require 'minitest/autorun'
require 'json'

class DispatcherTest < Minitest::Test
  RESPONSE_OK = { 
    statusCode: 200, 
    body: 'OK'.to_json, 
    headers: { "Content-Type"=>"application/json" }
  }

  def setup
    ENV['CONNECTION_TABLE_NAME'] = 'test-connection-table'

    @events = {
      connect: JSON.parse(File.read("#{__dir__}/fixtures/connect.json"))
    }

    require 'aws-sdk-dynamodb'

    Aws.config[:dynamodb] = {
      stub_responses: {
        put_item: {},
        delete_item: {}
      }
    }
  end

  def test_connect
    event = @events[:connect]

    require './main.rb'

    assert_equal(RESPONSE_OK, Dispatcher.handler(event:, context: nil))
  end
end
