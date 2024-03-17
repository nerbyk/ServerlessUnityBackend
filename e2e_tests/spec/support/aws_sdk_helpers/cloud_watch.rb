require 'aws-sdk-cloudwatchlogs'
require 'json'

module AwsSdkHelpers
  class CloudWatch
    Client = Aws::CloudWatchLogs::Client.new
    Event = Data.define(:detail_type, :source, :detail) do
      def self.[](raw_event)
        parsed_event = JSON.parse(raw_event, symbolize_names: true)
          .tap { |it| it[:detail_type] = it.delete(:'detail-type') }

        new(**parsed_event.slice(*members))
      end
    end

    def self.logs(log_group_name)
      Client.describe_log_streams(log_group_name:).log_streams.flat_map do |log_stream|
        Client.get_log_events(log_group_name:, log_stream_name: log_stream.log_stream_name).events.map do |event|
          Event[event.message]
        end
      end
    end

    def self.clean_up(log_group_name)
      Client.describe_log_streams(log_group_name:).log_streams.each do |log_stream|
        Client.delete_log_stream(log_group_name:, log_stream_name: log_stream.log_stream_name)
      end
    end
  end
end
