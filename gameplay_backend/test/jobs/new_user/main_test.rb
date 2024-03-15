require 'test_helper'
require 'mocha/minitest'
require 'main'

describe "NewUserLambda" do
  let(:event) { JSON.parse(File.open("#{__dir__}/fixtures/new_user_event.json")) }
  let(:new_user_id) { event.dig('detail', 'userName') }
  let(:ddb_client) { Aws::DynamoDB::Client.new(stub_responses: true) }

  subject {
    handler(event:, context: nil)
  } 

  it "should create new user" do

  end
end