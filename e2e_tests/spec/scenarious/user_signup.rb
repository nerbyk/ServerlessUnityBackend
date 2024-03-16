require 'spec_helper'

describe 'User Registration' do
  let(:cdk_stack_name) { ENV['CDK_STACK_NAME'] }

  let(:ssm_client) { Aws::SSM::Client.new }
  let(:cognito_client) { Aws::CognitoIdentityProvider::Client.new }
  let(:dynamodb_client) { Aws::DynamoDB::Client.new }

  let(:cognito_user_pool_id) { ssm_client.get_parameter(name: "/#{cdk_stack_name}/cognito/user-pool-id").parameter.value }
  let(:cognito_user_pool_client_id) { ssm_client.get_parameter(name: "/#{cdk_stack_name}/cognito/user-pool-client-id").parameter.value }

  let(:users_table_name) { cdk_stack_name + '-Users' }
  let(:user_email) { 'test_user@example.com' }
  let(:user_password) { '12345678' }

  def cognito_signup_user
    cognito_client.sign_up({
      client_id: cognito_user_pool_client_id,
      username: user_email,
      password: user_password,
      user_attributes: [
        { name: 'email', value: user_email }
      ]
    })
  rescue Aws::CognitoIdentityProvider::Errors::UsernameExistsException
    cognito_delete_user
    retry
  end

  def cognito_delete_user = cognito_client.admin_delete_user(user_pool_id: cognito_user_pool_id, username: user_email)
  def confirm_user_signup = cognito_client.admin_confirm_sign_up(user_pool_id: cognito_user_pool_id, username: user_email)
  
  def dynamodb_delete_user(user_id)
    dynamodb_client.delete_item({
      table_name: users_table_name,
      key: { 'user_id': user_id }
    })
  end

  def dynamodb_get_user(user_id)
    dynamodb_client.get_item({
      table_name: users_table_name,
      key: { 'user_id': user_id }
    })
  end
  
  after do 
    cognito_delete_user
  end
    
  context "when new user confirms their email" do
    let!(:user) { cognito_signup_user }
    let(:ddb_user) {  }

    after do
      dynamodb_delete_user(user.user_sub)
    end

    it "should create new user in dynamodb" do
      expect(dynamodb_get_user(user.user_sub).item).to be_nil

      confirm_user_signup

      sleep(5)

      expect(dynamodb_get_user(user.user_sub).item).to_not be_nil
    end
  end
end