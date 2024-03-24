require 'spec_helper'
require 'support/websocket_helper'
require 'support/shared_contexts/cognito_user'

require 'support/aws_sdk_helpers/cognito'
require 'support/aws_sdk_helpers/dynamodb'



describe "WebSocket" do
  include_context :cognito_user
  
  before(:all) do

    @decoded_jwt = AwsSdkHelpers::Cognito.verify_jwt_token(@user.id_token).first
    @ws  = WebSocketHelper.new
    @ws_conn = @ws.connect(@user.id_token)
    sleep(0.1) while @ws_conn.handshake.state == :new
  end

  after(:all) do
    @ws_conn.close
  end

  def get_connected_user
    AwsSdkHelpers::DynamoDB.find_by(:connection, { "userId" => @decoded_jwt["sub"] }).item
  end

  it "should create connection in DynamoDB" do
    binding.irb
    expect(@ws_conn.handshake.state).to eq(:finished)

  end
end
