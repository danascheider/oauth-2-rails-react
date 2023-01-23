require 'rails_helper'

RSpec.describe 'TokensController', type: :request do
  describe 'GET /tokens' do
    subject(:token) { get tokens_path }

    context 'when there are access tokens saved' do
      before do
        create_list(:access_token, 3)
      end

      it 'returns the last saved access token' do
        token
        expect(response.body).to eq AccessToken.last.to_json
      end

      it 'returns status 200' do
        token
        expect(response.status).to eq 200
      end
    end

    context 'when there are no access tokens saved' do
      it 'returns an empty response' do
        token
        expect(response.body).to be_blank
      end

      it 'returns status 204' do
        token
        expect(response.status).to eq 204
      end
    end
  end
end
