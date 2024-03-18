require 'spec_helper'
require 'support/aws_sdk_helpers/dynamodb'
require 'support/aws_sdk_helpers/cognito'
require 'support/aws_sdk_helpers/event_bus'

describe 'User SignIn' do
  before(:all) do
    @user = AwsSdkHelpers::Cognito.sign_up_user(
      email: 'test@example.com',
      password: '12345678',
      confirmed: true
    ).then { |it| AwsSdkHelpers::Cognito.get_user(it.user_sub) }
  end

  after(:all) do
    AwsSdkHelpers::Cognito.delete_user(@user.username)
  end

  context 'when user signs-in with valid credentials' do
    before(:context) do
      @sign_in = AwsSdkHelpers::Cognito.sign_in_user(username: @user.username, password: '12345678')
      @jwt = AwsSdkHelpers::Cognito.verify_jwt_token(@sign_in.id_token).first
    end

    it 'returns tokens' do
      expect(@sign_in).to respond_to(:access_token)
      expect(@sign_in).to respond_to(:id_token)
      expect(@sign_in).to respond_to(:refresh_token)
    end

    it 'returns valid JWT token' do
      expect(@jwt['cognito:username']).to eq(@user.username)
    end
  end

  context 'when user signs-in with invalid credentials' do
    it 'fails auth & sdk raises error' do
      expect {
        AwsSdkHelpers::Cognito.sign_in_user(username: @user.username, password: 'invalid')
      }.to raise_error
    end
  end
end
