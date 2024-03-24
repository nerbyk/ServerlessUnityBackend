require 'minitest/autorun'
require 'mocha/minitest'
require 'json'
require 'aws-sdk-dynamodb'
require 'aws-sdk-eventbridge'


describe 'Dispatcher' do
  let(:ddb_table_name) { 'test-connection-table' }
  let(:event_bus_name) { 'test-event-bus' }

  let(:events) do
    {
      connect: JSON.parse(File.read("#{__dir__}/fixtures/connect.json"))
    }
  end

  let(:response_ok) do
    {
      statusCode: 200,
      body: 'OK'.to_json,
      headers: { "Content-Type" => "application/json" }
    }
  end

  before do
    ENV['CONNECTION_TABLE_NAME'] = ddb_table_name
    ENV['EVENT_BUS_NAME']        = event_bus_name

    Aws.config[:dynamodb] = {
      stub_responses: {
        put_item: {},
        delete_item: {}
      }
    }

    Aws.config[:eventbridge] = {
      stub_responses: {
        put_events: {}
      }
    }

    require './main.rb'
  end

  after do
    ENV.delete('CONNECTION_TABLE_NAME')
    ENV.delete('EVENT_BUS_NAME')
  end

  describe '#connect' do
    let(:request_user_id) { events[:connect]['requestContext']['authorizer']['customerId'] }
    let(:request_connection_id) { events[:connect]['requestContext']['connectionId'] }

    let(:expected_item) do
      {
        table_name: ddb_table_name,
        item: {
          "connectionId" => request_connection_id,
          "userId" => request_user_id
        }
      }
    end

    let(:expected_event) do
      {
        entries: [
          {
            source: 'custom.gameplay_backend',
            detail_type: "GET_USER_DATA",
            event_bus_name: event_bus_name,
            detail: {
              "connectionId" => request_connection_id,
              "userId" => request_user_id
            }.to_json
          }
        ]
      }
    end

    subject do
      Dispatcher.handler(event: events[:connect], context: nil)
    end

    before do
      Aws::DynamoDB::Client.any_instance.expects(:put_item).once.with(expected_item)
      Aws::EventBridge::Client.any_instance.expects(:put_events).once.with(**expected_event)
    end

    it 'creates a connection and emits an event' do
      expect(subject).must_equal(response_ok)
    end
  end
end
