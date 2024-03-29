require 'active_function'

require 'aws-sdk-dynamodb' 
require 'aws-sdk-eventbridge'

require 'logger'

CONNECTION_TABLE_NAME = ENV.fetch('CONNECTION_TABLE_NAME')
EVENT_BUS_NAME        = ENV.fetch('EVENT_BUS_NAME')

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

  CONNECTION_OPTIONS = {
    ddb: { table_name: ::CONNECTION_TABLE_NAME },
    eb: {
      broadcast_user_data_event: {
        source: 'gameplay_backend',
        detail_type: "GET_USER_DATA",
        event_bus_name: ::EVENT_BUS_NAME
      }
    }
  } 

  def self.handler(event:, context:)
    ::Log.info "Event received: %s" % JSON.pretty_generate(event)

    route_key       = event.dig('requestContext', 'routeKey').delete_prefix('$')
    event_payload   = (event_body = event.dig('body')) && JSON.parse(event_body, symbolize_names: true) 

    process(route_key, {
      connection_id: event.dig('requestContext', 'connectionId'),
      user_id: event.dig('requestContext', 'authorizer', 'customerId'),
      action: route_key,
      payload: event_payload
    })
  end

  def connect
    create_user_connection

    render status: 200, json: "OK", head: {}
  rescue => e
    ::Log.error(e)
    render status: 500, json: { error: e.message }
  end

  def disconnect
    delete_user_connection

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
  end

  def set_action_params
    @action =  @request[:action]
    @payload = @request[:payload]
  end

  def create_user_connection
    DynamoDbClient.put_item(new_connection_ddb_item)
      .tap { |it| ::Log.info("Connection created: #{it.inspect}") }
  end

  def delete_user_connection
    DynamoDbClient.delete_item(delete_connection_ddb_item)
      .tap { |it| ::Log.info("Connection deleted: #{it.inspect}") }
  end

  def new_connection_ddb_item
    CONNECTION_OPTIONS[:ddb].merge(item: user_connection_params)
  end

  def delete_connection_ddb_item
    CONNECTION_OPTIONS[:ddb].merge(key: user_connection_params.slice("connectionId"))
  end

  def user_connection_params
    {
      "connectionId" => @connection_id,
      "userId" => @user_id
    }
  end
end
