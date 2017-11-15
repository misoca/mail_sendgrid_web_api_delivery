# frozen_string_literal: true
require 'mail/check_delivery_params'
require 'sendgrid-ruby'
require 'base64'

module Mail
  class SendgridWebApiDelivery
    attr_accessor :settings

    def initialize(values)
      self.settings = values
    end

    def deliver!(mail)
      Mail::CheckDeliveryParams.check(mail)

      res = Gateway.new.call(to_request_body(mail))
      if [4, 5].include?(res.status_code.to_i.div(100))
        content_type = res.headers&.dig('content-type') || []
        msg = if content_type.include?('application/json')
                JSON.parse(res.body).dig('errors', 0, 'message') || 'Error'
              else
                res.body
              end
        raise Error, msg
      end
      res
    rescue EOFError, Errno::ECONNREFUSED, Net::OpenTimeout, Net::ReadTimeout => e
      err = ConnectionError.new(e.message)
      err.set_backtrace(e.backtrace)
      raise err
    end

    private

    def to_request_body(mail)
      ToRequestBody.new(mail).call
    end

    class Gateway
      def call(request_body)
        sg = SendGrid::API.new(api_key: ENV['MAIL_SENDGRID_API_KEY'])
        sg.client.mail._('send').post(request_body: request_body)
      end
    end

    class ToRequestBody
      def initialize(mail)
        @mail = mail
      end

      def call
        res = {
          personalizations: personalizations,
          from: { email: mail.smtp_envelope_from },
          content: content
        }
        res[:from][:name] = mail[:from].display_names.first if mail[:from].display_names.first
        res[:reply_to] = { email: mail.reply_to.to_a.first } if mail.reply_to.to_a.first
        if mail.attachments.to_a.any?
          res[:attachments] = mail.attachments.map do |a|
            { type: a.mime_type, content: Base64.strict_encode64(a.body.decoded), filename: a.filename }
          end
        end
        res
      end

      private

      attr_accessor :mail

      def unique_to_addrs
        @unique_to_addrs ||= unique_addrs(mail.to)
      end

      def unique_cc_addrs
        @unique_cc_addrs ||= unique_addrs(mail.cc.to_a)
      end

      def unique_bcc_addrs
        @unique_bcc_addrs ||= unique_addrs(mail.bcc.to_a)
      end

      def unique_addrs(addrs)
        addrs.uniq { |a| a.downcase }
      end

      def personalizations
        # Accoring Sendgrid Web API,
        #   Each email address in the personalization block should be
        #   unique between to, cc, and bcc
        personalization = {
          to: unique_to_addrs.map { |a| { email: a } },
          subject: mail.subject
        }
        cc = remove_duplicates(unique_cc_addrs, unique_to_addrs)
        personalization[:cc] = cc.map { |a| { email: a } } if cc.any?

        bcc = remove_duplicates(unique_bcc_addrs, unique_to_addrs + cc)
        personalization[:bcc] = bcc.map { |a| { email: a } } if bcc.any?

        [personalization]
      end

      def remove_duplicates(addrs, excludes)
        excludes = excludes.map(&:downcase)
        addrs.each_with_object([]) do |addr, res|
          res << addr unless excludes.include?(addr.downcase)
        end
      end

      def content
        if mail.multipart?
          mail.parts.each_with_object([]) do |part, arr|
            next if part.attachment?
            arr << { type: part.mime_type, value: part.body.decoded }
          end
        else
          [{ type: 'text/plain', value: mail.body.decoded }]
        end
      end
    end

    class Error < ::StandardError
    end

    class ConnectionError < Error
    end
  end
end
