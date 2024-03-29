require 'spec_helper'
require 'support/rest_api_helper'
require 'support/shared_contexts/cognito_user'

RSpec.describe 'User Data API' do
  include_context :cognito_user

  describe 'GET /user_data' do
    subject { RestApiHelper.get('user_data', jwt_token) }
    
    let(:jwt_token) { @user.id_token }
    let(:response_body) { JSON.parse(subject.body) }

    it 'returns user data as JSON' do
      expect(subject.code).to eq("200")
      expect(response_body).to be_kind_of(Hash).and(include('user_id', 'entites'))

      expect(response_body['entites']).to be_kind_of(Hash)
      expect(response_body['entites'].values[0]).to be_kind_of(Hash).and(include('type', 'position'))
      expect(response_body['entites'].values[0]['type']).to be_kind_of(String)
      expect(response_body['entites'].values[0]['position']).to be_kind_of(Hash).and(include('x', 'y'))
    end

    context 'when invalid JWT passed' do
      let(:jwt_token) { 'invalid_token' }

      it 'returns 403' do
        expect(subject.code).to eq("403")
      end
    end
  end
end
