# frozen_string_literal: true
require 'mail'
require 'mail/sendgrid_web_api_delivery'

RSpec.describe Mail::SendgridWebApiDelivery do
  before do
    ENV['MAIL_SENDGRID_API_KEY'] = 'API_KEY'
  end

  subject { described_class.new({}) }

  describe '#deliver!' do
    describe 'response' do
      let(:mail) do
        Mail.new do
          to 'alice@example.com'
          from 'bob@example.com'
          subject 'This is an email'
          body 'This is the body'
        end
      end

      context 'Connected to SendGrid' do
        before do
          allow_any_instance_of(Mail::SendgridWebApiDelivery::Gateway).to receive(:call).and_return(response)
        end

        context '200' do
          let(:response) { OpenStruct.new(status_code: '200', body: '{}') }
          it { expect { subject.deliver!(mail) }.to_not raise_error }
        end

        context '4xx' do
          let(:response) { OpenStruct.new(status_code: '400', body: '{}') }
          it { expect { subject.deliver!(mail) }.to raise_error(described_class::Error) }
        end

        context '5xx' do
          context 'json' do
            let(:response) { OpenStruct.new(status_code: '500', body: '{}', headers: { 'content-type' => ['application/json'] }) }
            it { expect { subject.deliver!(mail) }.to raise_error(described_class::Error) }
          end

          context 'html' do
            let(:response) { OpenStruct.new(status_code: '500', body: '<html><head><title>500 Internal Server Error</title></head><body><center><h1>500 Internal Server Error</h1></center></body></html>', headers: { 'content-type' => ['text/html'] }) }
            it { expect { subject.deliver!(mail) }.to raise_error(described_class::Error) }
          end
        end
      end

      context 'Errno::ECONNREFUSED' do
        before do
          allow(Mail::SendgridWebApiDelivery::Gateway).to receive(:new) do
            api = double('sendgrid_api')
            allow(api).to receive(:call).and_raise(Errno::ECONNREFUSED)
            api
          end
        end

        it 'should raise' do
          expect { subject.deliver!(mail) }.to raise_error(described_class::ConnectionError)
        end
      end

      context 'Net::OpenTimeout' do
        before do
          allow(Mail::SendgridWebApiDelivery::Gateway).to receive(:new) do
            api = double('sendgrid_api')
            allow(api).to receive(:call).and_raise(::Net::OpenTimeout)
            api
          end
        end

        it 'should raise' do
          expect { subject.deliver!(mail) }.to raise_error(described_class::ConnectionError)
        end
      end
    end

    describe 'request body' do
      let(:response) { OpenStruct.new(status_code: '200', body: '{}') }
      before do
        expect_any_instance_of(Mail::SendgridWebApiDelivery::Gateway).to receive(:call).with(request).and_return(response)
      end

      describe 'from' do
        let(:request) { hash_including(from: from) }

        context 'with from name' do
          let(:mail) do
            Mail.new do
              to 'alice@example.com'
              from 'Dave <dave@example.com>'
              body 'This is the body'
            end
          end

          let(:from) do
            { email: 'dave@example.com', name: 'Dave' }
          end

          it { subject.deliver!(mail) }
        end

        context 'without from name' do
          let(:mail) do
            Mail.new do
              to 'alice@example.com'
              from 'dave@example.com'
              body 'This is the body'
            end
          end

          let(:from) do
            { email: 'dave@example.com' }
          end

          it { subject.deliver!(mail) }
        end
      end

      describe 'personalizations' do
        let(:request) { hash_including(personalizations: [personalization]) }

        context 'to / cc / bcc' do
          let(:mail) do
            Mail.new do
              to 'alice@example.com'
              cc 'bob@example.com'
              bcc 'carol@example.com'
              from 'dave@example.com'
              body 'This is the body'
            end
          end

          let(:personalization) {
            {
              subject: nil,
              to: [{ email: 'alice@example.com' }],
              cc: [{ email: 'bob@example.com' }],
              bcc: [{ email: 'carol@example.com' }]
            }
          }
          it { subject.deliver!(mail) }
        end

        context 'duplicate entry' do
          context 'both' do
            let(:mail) do
              Mail.new do
                to 'alice@example.com'
                cc 'bob@example.com, alice@example.com'
                bcc 'carol@example.com, bob@example.com, alice@example.com'
                from 'dave@example.com'
                body 'This is the body'
              end
            end

            let(:personalization) {
              {
                subject: nil,
                to: [{ email: 'alice@example.com' }],
                cc: [{ email: 'bob@example.com' }],
                bcc: [{ email: 'carol@example.com' }]
              }
            }
            it { subject.deliver!(mail) }
          end

          context 'bcc only' do
            let(:mail) do
              Mail.new do
                to 'alice@example.com'
                bcc 'carol@example.com, alice@example.com'
                from 'dave@example.com'
                body 'This is the body'
              end
            end

            let(:personalization) {
              {
                subject: nil,
                to: [{ email: 'alice@example.com' }],
                bcc: [{ email: 'carol@example.com' }]
              }
            }
            it { subject.deliver!(mail) }
          end

          context 'more than 1 same addresses in cc' do
            let(:mail) do
              Mail.new do
                to 'alice@example.com'
                cc 'brabo@example.com, brabo@example.com'
                from 'zoe@example.com'
                body 'This is the body'
              end
            end

            let(:personalization) {
              {
                subject: nil,
                to: [{ email: 'alice@example.com' }],
                cc: [{ email: 'brabo@example.com' }]
              }
            }
            it { subject.deliver!(mail) }
          end

          context 'to and cc have same addresses, but cases are different' do
            let(:mail) do
              Mail.new do
                to 'alice@example.com'
                cc 'Alice@example.com'
                from 'zoe@example.com'
                body 'This is the body'
              end
            end

            let(:personalization) {
              {
                subject: nil,
                to: [{ email: 'alice@example.com' }],
              }
            }
            it { subject.deliver!(mail) }
          end
        end
      end

      describe 'content' do
        context 'not multipart' do
          let(:mail) do
            Mail.new do
              to 'alice@example.com'
              from 'bob@example.com'
              body 'This is the body'
            end
          end

          let(:request) { hash_including(content: [{ type: 'text/plain', value: 'This is the body' }]) }
          it { subject.deliver!(mail) }
        end
      end

      context 'multipart' do
        let(:mail) do
          Mail.new do
            to 'alice@example.com'
            from 'bob@example.com'
            add_file 'spec/logo.png'
          end
        end
        let(:request) {
          hash_including(
            attachments: [{
              type: 'image/png',
              content: Base64.strict_encode64(File.read('spec/logo.png')),
              filename: 'logo.png'
            }]
          )
        }
        it { subject.deliver!(mail) }
      end
    end
  end
end
