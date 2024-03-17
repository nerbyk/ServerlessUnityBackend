require_relative 'cloud_watch'
require 'aws-sdk-eventbridge'

module AwsSdkHelpers
  class EventBus
    Client = Aws::EventBridge::Client.new
    GAMEPLAY_EVENTS_CW_LOG_GROUP_NAME = ENV['CDK_STACK_NAME'] + 'GameplayEventsLogGroup'

    def self.gameplay_events
      CloudWatch.logs(GAMEPLAY_EVENTS_CW_LOG_GROUP_NAME)
    end

    def self.gameplay_events_clean_up
      CloudWatch.clean_up(GAMEPLAY_EVENTS_CW_LOG_GROUP_NAME)
    end
  end
end
