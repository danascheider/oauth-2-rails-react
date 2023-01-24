# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'TokensController', type: :request do
  describe 'GET fetch' do
    subject(:token) { get token_path }

    context 'when there are no tokens in the database' do
      it 'returns status 204' do
        token
        expect(response).to be_no_content
      end

      it 'returns no response body' do
        token
        expect(response.body).to be_blank
      end
    end

    context 'when there are tokens in the database' do
      before do
        create_list(:access_token, 3)
      end

      it 'returns status 200' do
        token
        expect(response.status).to eq 200
      end

      it 'returns the last saved access token' do
        token
        expect(response.body).to eq AccessToken.last.to_json
      end
    end
  end
end
