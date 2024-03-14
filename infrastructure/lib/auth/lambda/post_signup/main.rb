require 'json'

unless ENV['AWS_LAMBDA_FUNCTION_NAME'] # Reserved AWS Lambda runtime environment variable
  require 'bundler/inline'

  gemfile do
    source 'https://rubygems.org'
    gem 'aws-sdk-eventbridge', '~> 1.57.0'
    gem 'nokogiri'
  end
end

require 'aws-sdk-eventbridge'
require 'logger'

LOGGER = Logger.new($stdout).freeze
EVENT_BRIDGE = Aws::EventBridge::Client.new.freeze
EVENT_BUS_NAME = ENV.fetch('EVENT_BUS_NAME', 'default').freeze

DEFAULT_EVENT_OPTIONS = {
  source: 'custom.cognito',
  detail_type: 'USER_SIGN_UP_CONFIRMED',
  event_bus_name: EVENT_BUS_NAME,
}.freeze

def handler(event:, context: nil)
  LOGGER.info "Event received: %s" % JSON.pretty_generate(event)

  EVENT_BRIDGE.put_events({
    entries: [
      {
        detail: JSON.generate(event),
        **DEFAULT_EVENT_OPTIONS
      }
    ]
  }).tap do |response|
    LOGGER.info "EventBridge response: #{response}"
  end

  event
end
