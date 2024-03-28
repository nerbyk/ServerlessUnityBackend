require 'test_helper'
require 'mocha/minitest'
require 'aws-sdk-apigatewaymanagementapi'
require 'aws-sdk-dynamodb'

describe "NewUserLambda" do
  let(:event) { JSON.parse(File.read("#{__dir__}/fixtures/event.json")) }
  let(:user) { User.find(user_data["user_id"]) }

  let(:user_data) do
    {
      "user_id" =>  event['detail']['userId'],
      "entities" =>  {
          "123" =>         { type: "tree", position: { x: [1, 2], y: [1, 2] } }, 
          "456" =>         { type: "tree", position: { x: [2, 3], y: [2, 3] } },
       },
      "items" => []
    }
  end

  let(:expected_response) do
    {
      statusCode: 200, 
      body: {
        user_id: user_data["user_id"], 
        items: user_data["items"], 
        entites: {
          :"456" =>  user_data["entities"]["456"],
          :"123"=>   user_data["entities"]["123"]
        }
      }
    }
  end

  subject do 
    handler(event:, context: nil) 
  end

  before do
    require 'main'

    User.create(user_data)
  end

  it "should return user data from ddb" do
    assert subject == expected_response
  end
end
