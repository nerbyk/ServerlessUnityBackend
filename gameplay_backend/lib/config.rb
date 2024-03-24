# frozen_string_literal: true

require 'dynamoid'

Dynamoid.configure do |config|
  config.namespace = nil
  # config.endpoint = 'http://localhost:8000' if ['development', 'test', nil].include?(ENV['env'])
  config.logger = ENV['DEBUG'] ? Logger.new($stdout) : nil
  config.read_capacity = 10
  config.write_capacity = 10
  config.create_table_on_save = false
end

require 'models/user' if ENV['USERS_TABLE_NAME']
require 'models/receipt' if ENV['ENTITY_RECEIPTS_TABLE_NAME']
require 'models/item' if ENV['ITEMS_TABLE_NAME']

if (STATICS_S3_BUCKET_NAME = ENV['STATICS_S3_BUCKET_NAME'])
  require 'aws-sdk-s3'

  S3_CLIENT = Aws::S3::Client.new
end

if (EVENT_BUS_NAME = ENV['EVENT_BUS_NAME'])
  require 'aws-sdk-eventbridge'

  EVENT_BRIDGE_CLIENT = Aws::EventBridge::Client.new
end

if (APIGW_ENDPOINT = ENV['APIGW_ENDPOINT'])
  require 'aws-sdk-apigatewaymanagementapi'

  APIGW_CLIENT = Aws::ApiGatewayManagementApi::Client.new(endpoint: APIGW_ENDPOINT)
end

LOGGER = Logger.new($stdout).freeze
