# frozen_string_literal: true

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

  describe 'GET /callback' do
    subject(:callback) { get "#{callback_path}?#{params}" }

    before do
      WebMock.enable!
    end

    context 'when the params indicate there is an error' do
      let(:params) { URI.encode_www_form({ error: 'invalid_scope' }) }

      it 'returns an error' do
        callback
        expect(JSON.parse(response.body)).to eq({ 'error' => 'invalid_scope' })
      end

      it 'returns status 403' do
        callback
        expect(response).to be_forbidden
      end
    end

    context 'when there is no matching authorization request' do
      let(:params) do
        URI.encode_www_form({
          state: 'foobar'
        })
      end

      before do
        allow(Rails.logger).to receive(:error)
      end

      it 'logs the error' do
        callback
        expect(Rails.logger)
          .to have_received(:error)
                .with("State value 'foobar' did not match an existing authorization request")
      end

      it 'renders an error' do
        callback
        expect(JSON.parse(response.body)).to eq({ 'error' => 'State value did not match' })
      end

      it 'returns status 403' do
        callback
        expect(response).to be_forbidden
      end
    end

    context 'when the auth server returns an error' do
      let(:params) do
        URI.encode_www_form({
          state: 'foobar',
          grant_type: 'authorization_code',
          code: 'abcdef',
          user: 'usersub',
          redirect_uri: configatron.oauth.client.default_redirect_uri
        })
      end

      before do
        create(:authorization_request, state: 'foobar')

        stub_request(:post, 'http://localhost:4003/token')
          .to_return(
            body: { error: 'invalid_client' }.to_json,
            status: 401
          )

        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:error)
      end

      it 'logs the state' do
        callback
        expect(Rails.logger).to have_received(:info).with("State value 'foobar' matches")
      end

      it 'logs the code' do
        callback
        expect(Rails.logger).to have_received(:info).with("Requesting access token for code 'abcdef'")
      end

      it 'logs the error' do
        callback
        expect(Rails.logger)
          .to have_received(:error)
                .with('invalid_client')
      end

      it "doesn't create an access token" do
        expect { callback }.not_to change(AccessToken, :count)
      end

      it 'passes the error through' do
        callback
        expect(JSON.parse(response.body)).to eq({ 'error' => 'Unable to fetch access token, error (401)' })
      end

      it 'returns the same status as the auth server' do
        callback
        expect(response).to be_unauthorized
      end
    end

    context 'when the auth server issues the token successfully' do
      let(:params) do
        URI.encode_www_form({
          state: 'foobar',
          grant_type: 'authorization_code',
          code: 'abcdef',
          user: 'usersub',
          redirect_uri: configatron.oauth.client.default_redirect_uri
        })
      end

      before do
        create(:authorization_request, state: 'foobar')

        stub_request(:post, configatron.oauth.auth_server.token_endpoint)
          .to_return(
            body: {
              access_token: 'foobar',
              refresh_token: 'raboof',
              scope: 'fruit veggies',
              token_type: 'Bearer',
              client_id: configatron.oauth.client.client_id,
              user: 'usersub'
            }.to_json,
            status: 200
          )

        allow(Rails.logger).to receive(:info)
      end

      it 'logs the access token' do
        callback
        expect(Rails.logger)
          .to have_received(:info)
                .with('Got access token: foobar')
      end

      it 'logs the refresh token' do
        callback
        expect(Rails.logger)
          .to have_received(:info)
                .with('Got refresh token: raboof')
      end

      it 'logs the scope' do
        callback
        expect(Rails.logger)
          .to have_received(:info)
                .with('Got scope: fruit veggies')
      end

      it 'creates an access token in the database' do
        expect { callback }.to change(AccessToken, :count).from(0).to(1)
      end

      it 'returns the access token, refresh token, and scope' do
        callback
        expect(JSON.parse(response.body))
          .to eq({ 'access_token' => 'foobar', 'refresh_token' => 'raboof', 'scope' => 'fruit veggies' })
      end

      it 'returns a successful response' do
        callback
        expect(response.status).to eq 200
      end
    end
  end
end
