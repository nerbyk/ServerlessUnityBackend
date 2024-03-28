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
      { type: "stone", x: [3], y: [3] }
    ] 
  end

  subject do 
    require 'main'

    handler(event:, context: nil) 
  end

  before do
    Aws.config[:s3] = {
      stub_responses: {
        get_object: {
          body: default_entity_mapping.to_json
        }
      }
    }
  end

  around do |&block|
    ENV['STATICS_S3_BUCKET_NAME'] = 'statics-test'
  
    super(&block)

    ENV.delete('STATICS_S3_BUCKET_NAME')
  end

  it "should create new user from s3 json asset" do
    _(subject).must_equal({ statusCode: 200, body: "OK" })

    assert created_user
    assert created_user.user_id == new_user_id
    assert created_user.entities.count == default_entity_mapping.count

    assert created_user.entities.values[0][:type] == default_entity_mapping[0][:type]
    assert created_user.entities.values[0][:position] == default_entity_mapping[0].slice(:x, :y)

    assert created_user.entities.values[1][:type] == default_entity_mapping[1][:type]
    assert created_user.entities.values[1][:position] == default_entity_mapping[1].slice(:x, :y)
  end
end
