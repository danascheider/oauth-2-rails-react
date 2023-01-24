require 'rails_helper'

RSpec.describe 'OauthController', type: :request do
  describe 'GET /authorize' do
    subject(:authorize) { get authorize_path }

    let(:redirect_uri) do
      uri = URI.parse(configatron.oauth.auth_server.authorization_endpoint)
      uri.query = query_string
      uri.to_s
    end

    let(:state) { '20ecad6cb5927120' }

    let(:query_string) do
      URI.encode_www_form({
        response_type: 'code',
        scope: configatron.oauth.client.scope,
        client_id: configatron.oauth.client.client_id,
        redirect_uri: configatron.oauth.client.default_redirect_uri,
        state:
      })
    end

    before do
      allow(SecureRandom).to receive(:hex).and_return(state)
      allow(Rails.logger).to receive(:info)
    end

    it 'logs the redirect' do
      authorize
      expect(Rails.logger)
        .to have_received(:info)
              .with("Redirecting to #{redirect_uri}")
    end

    it 'redirects to the authorization server' do
      authorize
      expect(response).to redirect_to(redirect_uri)
    end

    it 'creates an AuthorizationRequest' do
      expect { authorize }.to change(AuthorizationRequest, :count).from(0).to(1)
    end
  end
end
