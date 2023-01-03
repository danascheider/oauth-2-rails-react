# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AuthorizationsController#authorize', type: :request do
  subject(:authorize) { get uri }

  let(:uri) do
    base_uri = URI.parse(authorize_url)
    base_uri.query = URI.encode_www_form(query_params)
    base_uri.to_s
  end

  context 'when the client exists and the redirect URI is valid' do
    let!(:client) { create(:client) }

    context 'with only valid scopes' do
      let(:query_params) do
        {
          client_id: client.id,
          redirect_uri: client.redirect_uris.first,
          scope: client.scope.join(' ')
        }
      end

      it 'is successful' do
        authorize
        expect(response).to be_successful
      end
    end

    context 'with invalid scopes included' do
      let(:query_params) do
        {
          client_id: client.client_id,
          redirect_uri: client.redirect_uris.first,
          scope: 'fruit veggies dairy'
        }
      end

      it 'redirects' do
        authorize
        expect(response).to redirect_to "#{client.redirect_uris.first}?error=invalid_scope"
      end
    end
  end

  context "when the client doesn't exist" do
    let(:query_params) do
      {
        client_id: 'oauth-client-1',
        redirect_uri: 'https://example.com/callback',
        scope: 'fruit veggies'
      }
    end

    it 'is successful' do
      authorize
      expect(response).to be_successful
    end
  end

  context 'when the redirect URI is invalid' do
    let!(:client) { create(:client) }
    let(:query_params) do
      {
        client_id: client.id,
        redirect_uri: 'https://example.net/callback',
        scope: 'fruit veggies'
      }
    end

    it 'is successful' do
      authorize
      expect(response).to be_successful
    end
  end
end