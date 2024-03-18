require 'spec_helper'
require 'support/websocket_helper'
require 'support/aws_sdk_helpers/cognito'
require 'support/aws_sdk_helpers/dynamodb'

describe "WebSocket" do
  before(:all) do
    @user = AwsSdkHelpers::Cognito.sign_up_user(
      email: "test@example.com",
      password: "12345678",
      confirmed: true
    ).then { |it| AwsSdkHelpers::Cognito.get_user(it.user_sub) }
    .then { |it| AwsSdkHelpers::Cognito.sign_in_user(username: it.username, password: "12345678") }
    
    @jwt = AwsSdkHelpers::Cognito.verify_jwt_token(@user.id_token).first
  end
  

  it "should create connection in DynamoDB" do
    ws = WebSocketHelper.new

    connect = ws.connect(@user.id_token)
    expect(ws.handshake.state).to eq(:finished)
    expect(ws.queue).to be_present
  end
end