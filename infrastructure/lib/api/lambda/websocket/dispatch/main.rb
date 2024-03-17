require 'active_function'

require 'aws-sdk-dynamodb' 
require 'aws-sdk-eventbridge'

require 'logger'

DynamoDbClient = Aws::DynamoDB::Client.new
EventBridgeClient = Aws::EventBridge::Client.new
Log = Logger.new($stdout)

ActiveFunction.config do
  plugin :callbacks
end

class Dispatcher < ActiveFunction::Base
  before_action :set_connection_params, only: [:connect, :disconnect]
  before_action :set_action_params, only: [:default]

  def self.handler(event:, context:)
    ::Log.info "Event received: %s" % JSON.pretty_generate(event)
    route_key = event.dig('requestContext', 'routeKey').delete_prefix('$')
      
    process(route_key, {
      connection_id: event.dig('requestContext', 'ConnectionID'),
    })
  end

  def connect
    ::Log.info("Connecting #{@connection_id}")

    DynamoDbClient.put_item(
      table_name: ENV['CONNECTION_TABLE_NAME'],
      item: {
        connectionId: @connection_id,
        userId: @user_id
      } 
    ).tap { |it| ::Log.info("Connection created: #{it.inspect}") }

    @response.body = { statusCode: 200, body: 'OK' }
  rescue => e
    ::Log.error(e)
    @response.body = { statusCode: 500, body: 'Internal Server Error' }
  end

  def disconnect
    ::Log.info("Disconnecting #{@connection_id}")
    DynamoDbClient.delete_item(
      table_name: ENV['CONNECTION_TABLE_NAME'], 
      key: { connectionId: @connection_id }
    ).tap { |it| ::Log.info("Connection deleted: #{it.inspect}") }

    @response.body = { statusCode: 200, body: 'OK' }
  rescue => e 
    @response.body = { statusCode: 500, body: 'Internal Server Error' }
  end

  def default
    ::Log.info("Default event triggerd: #{@action}")
    ::Log.info("Event received: %s" % JSON.pretty_generate(@request))
  end

  private 
  
  def set_connection_params
    @connection_id = @request.dig('requestContext', 'ConnectionId')
    @user_id       = @request.dig('queryStringParameters', 'authorizer', 'customer_id')
  end

  def set_action_params
    @action = @request.dig('requestContext', 'RouteKey')
  end
end
