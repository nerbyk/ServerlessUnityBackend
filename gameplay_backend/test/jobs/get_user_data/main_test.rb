require 'test_helper'
require 'mocha/minitest'
require 'aws-sdk-apigatewaymanagementapi'
require 'aws-sdk-dynamodb'

describe "NewUserLambda" do
  let(:event) { JSON.parse(File.read("#{__dir__}/fixtures/event.json")) }
  let(:user_data) do
    {
      "user_id" =>  event['detail']['userId'],
      "entities" =>  [
        { type: "tree", x: [1, 2], y: [1, 2], guid: "123"}, 
        { type: "stone", x: [3], y: [3] , guid: "456" }
      ]
    }
  end
  let(:user) { User.find(user_data["user_id"]) }

  subject do 
    handler(event:, context: nil) 
  end

  before do
    Aws.config[:apigatewaymanagementapi] = {
      stub_responses: {
        post_to_connection: {}
      }
    }

    require 'main'

    User.create(user_data)
  end

  around do |&block|
    ENV['USERS_TABLE_NAME'] = 'users-test'
    ENV['APIGW_ENDPOINT'] = 'http://test.execute-api.us-east-1.amazonaws.com/test'
  
    super(&block)

    ENV.delete('USERS_TABLE_NAME')
    ENV.delete('APIGW_ENDPOINT')
  end

  after { User.delete_all }

  it "should return user data from ddb" do
    Aws::ApiGatewayManagementApi::Client.any_instance.expects(:post_to_connection).with(
      data: user.attributes.to_json,
      connection_id: event['detail']['connectionId']
    )

    _(subject).must_equal({ statusCode: 200, body: "OK" })
  end
end
