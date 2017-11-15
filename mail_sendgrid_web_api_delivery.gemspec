# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mail_sendgrid_web_api_delivery/version'

Gem::Specification.new do |spec|
  spec.name          = 'mail_sendgrid_web_api_delivery'
  spec.version       = Mail::SendgridWebApiDelivery::VERSION
  spec.authors       = ['MIZUNO Hiroki', 'Eito Katagiri']
  spec.email         = ['mzppp@gmail.com', 'eitoball@gmail.com']

  spec.summary       = 'A delivery method for mail gem which sends via SendGrid API version 3'
  spec.description   = 'A delivery method for mail gem which sends via SendGrid API version 3'
  spec.homepage      = 'https://github.com/misoca/mail_sendgrid_web_api_delivery'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = %w(
    Gemfile
    LICENSE.txt
    README.md
    Rakefile
    bin/console
    bin/setup
    lib/mail/sendgrid_web_api_delivery.rb
    lib/mail_sendgrid_web_api_delivery.rb
    lib/mail_sendgrid_web_api_delivery/version.rb
    mail_sendgrid_web_api_delivery.gemspec
  )
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'actionmailer'
  spec.add_dependency 'activesupport'
  spec.add_dependency 'mail', '~> 2.6.6'
  spec.add_dependency 'sendgrid-ruby'

  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rake', '~> 10.0'
end
