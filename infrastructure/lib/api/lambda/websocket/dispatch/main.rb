require 'active_function'

require 'aws-sdk-dynamodb' 
require 'aws-sdk-eventbridge'

require 'logger'

CONNECTION_TABLE_NAME = ENV.fetch('CONNECTION_TABLE_NAME') || "test-BusinessFarm-WebhookApiConnectionIdTable904D6C87-WDM6NDBR05VZ"

DynamoDbClient = Aws::DynamoDB::Client.new
EventBridgeClient = Aws::EventBridge::Client.new
Log = Logger.new($stdout)

ActiveFunction.config do
  plugin :callbacks
  plugin :rendering
end

class Dispatcher < ActiveFunction::Base
  before_action :log_request
  after_action :log_response

  before_action :set_connection_params, only: %w(connect disconnect)
  before_action :set_action_params, only: %w(default)

  def self.handler(event:, context:)
    ::Log.info "Event received: %s" % JSON.pretty_generate(event)
    route_key = event.dig('requestContext', 'routeKey').delete_prefix('$')
      
    process(route_key, {
      connection_id: event.dig('requestContext', 'connectionId'),
      user_id: event.dig('requestContext', 'authorizer', 'customerId'),
      action: route_key,
    })
  end

  def connect
    DynamoDbClient.put_item(
      table_name: CONNECTION_TABLE_NAME,
      item: {
        "connectionId" => @connection_id,
        "userId" => @user_id
      } 
    ).tap { |it| ::Log.info("Connection created: #{it.inspect}") }

    render status: 200, json: "OK"
  rescue => e
    ::Log.error(e)
    render status: 500, body: { error: e.message }
  end

  def disconnect
    DynamoDbClient.delete_item(
      table_name: CONNECTION_TABLE_NAME, 
      key: { "connectionId" => @connection_id }
    ).tap { |it| ::Log.info("Connection deleted: #{it.inspect}") }

    render status: 200
  rescue => e 
    render status: 500, body: { error: e.message }
  end

  def default
    ::Log.info("Default event triggerd: #{@action}")
    ::Log.info("Event received: %s" % JSON.pretty_generate(@request))
  end

  private 

  def log_request = ::Log.info("Request: %s" % JSON.pretty_generate(@request))
  def log_response = ::Log.info("Response: %s" % JSON.pretty_generate(@response.to_h))
  
  def set_connection_params
    @connection_id = @request[:connection_id]
    @user_id       = @request[:user_id]
    ::Log.info("Connection params: #{@connection_id}, #{@user_id}")
  end

  def set_action_params
    @action = @request["action"]
  end
end
