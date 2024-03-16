require 'test_helper'
require 'mocha/minitest'
require 'aws-sdk-s3'
require 'aws-sdk-dynamodb'

describe "NewUserLambda" do
  let(:event) { JSON.parse(File.read("#{__dir__}/fixtures/sign_up_confirmed_cw_event.json")) }
  let(:new_user_id) { event.dig('detail', 'userName') }
  let(:entity_uuid) { "test-uuid" }
  let(:created_user) { User.find(new_user_id) }

  let(:default_entity_mapping) do 
    [
      { type: "tree", x: [1, 2], y: [1, 2] }, 
      {type: "stone", x: [3], y: [3]}
    ].to_json 
  end

  subject do 
    require 'main'

    handler(event:, context: nil) 
  end

  before do
    Aws.config[:s3] = {
      stub_responses: {
        get_object: {
          body: default_entity_mapping
        }
      }
    }
  end

  around do |&block|
    ENV['USERS_TABLE_NAME'] = 'users-test'
    ENV['STATICS_S3_BUCKET_NAME'] = 'statics-test'
  
    super(&block)

    ENV.delete('USERS_TABLE_NAME')
    ENV.delete('STATICS_S3_BUCKET_NAME')
  end

  after { User.delete_all }

  it "should create new user from s3 json asset" do
    _(subject).must_equal({ statusCode: 200, body: "OK" })

    assert created_user

    assert created_user.entities[1][1]["type"] == "tree"
    assert created_user.entities[1][1]["guid"] == created_user.entities[2][2]["guid"]

    assert created_user.entities[3][3]["type"] == "stone"
    assert created_user.entities[3][3]["guid"] != created_user.entities[1][1]["guid"]
  end
end