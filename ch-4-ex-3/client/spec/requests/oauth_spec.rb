require 'rails_helper'

RSpec.describe 'OauthController', type: :request do
  describe 'GET /authorize' do
    subject(:authorize) { get authorize_path }

    let(:state) { 'foobar' }
    let(:expected_redirect_uri) do
      query = {
        state:,
        response_type: 'code',
        client_id: configatron.oauth.client.client_id,
        scope: configatron.oauth.client.scope,
        redirect_uri: configatron.oauth.client.default_redirect_uri,
      }

      base_uri = URI.parse(configatron.oauth.auth_server.authorization_endpoint)
      base_uri.query = URI.encode_www_form(query)
      base_uri.to_s
    end

    before do
      allow(SecureRandom).to receive(:hex).with(8).and_return(state)
      allow(Rails.logger).to receive(:info)
    end

    it 'creates an AuthorizationRequest' do
      expect { authorize }.to change(AuthorizationRequest, :count).from(0).to(1)
    end

    it 'sets the correct state value' do
      authorize
      expect(AuthorizationRequest.last.state).to eq 'foobar'
    end

    it 'logs the redirect' do
      authorize
      expect(Rails.logger).to have_received(:info).with("Redirecting to #{expected_redirect_uri}")
    end

    it 'redirects to the auth server with appropriate query params' do
      authorize
      expect(response).to redirect_to(expected_redirect_uri)
    end
  end
end
