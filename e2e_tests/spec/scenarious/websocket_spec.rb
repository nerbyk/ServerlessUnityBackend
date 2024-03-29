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
    AwsSdkHelpers::DynamoDB.find_by_index("connection", "user_id", @decoded_jwt["sub"]).items.first
  end

  let(:connection) { get_connected_user }

  it "should connect to WebSocket" do
    expect(@ws_conn.handshake.state).to eq(:finished)
    expect(@ws_conn).to be_open
  end

  it "should create connection in DynamoDB" do
    expect(connection).not_to be_nil
    expect(connection['userId']).to eq(@decoded_jwt["sub"])
  end

  it "should delete connection from DynamoDB when disconnected" do
    expect(connection).not_to be_nil

    @ws_conn.close
    
    sleep(1)

    expect(get_connected_user).to be_nil
  end
end
