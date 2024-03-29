require 'spec_helper'
require 'support/aws_sdk_helpers/dynamodb'
require 'support/aws_sdk_helpers/cognito'
require 'support/aws_sdk_helpers/event_bus'

describe 'User Registration' do
  before(:context) do
    @signup_response = AwsSdkHelpers::Cognito.sign_up_user(email: 'test_user@example.com', password: '12345678')
  end

  after(:context) do
    AwsSdkHelpers::Cognito.delete_user('test_user@example.com')
  end

  # TODO: Setup SES to receive emails and confirm the code flow
  # context 'when new user signs up' do
  # end

  context 'when new user confirms their email' do
    let(:emitted_events) { gameplay_eb_events }

    before(:all) do
      expect(gameplay_eb_events).to be_empty
      expect(db_user).to be_nil
      expect(cognito_user.user_status).to eq('UNCONFIRMED')

      AwsSdkHelpers::Cognito.confirm_user(username: 'test_user@example.com') # subject, not allowed by context hooks
    end

    after(:all) do
      AwsSdkHelpers::DynamoDB.delete(:user, @signup_response.user_sub)
      AwsSdkHelpers::EventBus.gameplay_events_clean_up
    end

    def db_user = AwsSdkHelpers::DynamoDB.find(:user, by: @signup_response.user_sub).item
    def gameplay_eb_events = AwsSdkHelpers::EventBus.gameplay_events
    def cognito_user = AwsSdkHelpers::Cognito.get_user('test_user@example.com')

    it 'should emit USER_SIGN_UP_CONFIRMED event' do
      expect(emitted_events.size).to eq(1)

      expect(emitted_events.first.detail[:triggerSource]).to eq('PostConfirmation_ConfirmSignUp')
      expect(emitted_events.first.detail_type).to eq('USER_SIGN_UP_CONFIRMED')
      expect(emitted_events.first.source).to eq('custom.cognito')
    end

    it 'should create new user in dynamodb' do
      expect(db_user).not_to be_nil
    end

    it 'should mark user as confirmed' do
      expect(cognito_user.user_status).to eq('CONFIRMED')
    end
  end
end
