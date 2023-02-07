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

  describe 'GET /callback' do
    subject(:callback) { get callback_path, params: }

    context 'when the params include an error' do
      let(:params) { { error: 'unsupported_response_type' } }

      it 'returns the error to the client' do
        callback
        expect(JSON.parse(response.body)).to eq({ 'error' => 'unsupported_response_type' })
      end

      it 'returns status 403' do
        callback
        expect(response).to be_forbidden
      end
    end

    context "when the state value doesn't match an existing request" do
      let(:params) do
        {
          state: 'foobar',
          code: SecureRandom.hex(8)
        }
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
        expect(JSON.parse(response.body))
          .to eq({ 'error' => 'State value did not match' })
      end

      it 'returns status 403' do
        callback
        expect(response).to be_forbidden
      end
    end

    context 'when there is an existing authorization request' do
      let!(:request) { create(:authorization_request) }
      let(:faraday_response) { instance_double(Faraday::Response, body:, status:, success?: success) }
      let(:status) { 200 }
      let(:success) { true }

      let(:body) do
        {
          access_token: 'foo',
          refresh_token: 'raboof',
          token_type: 'Bearer',
          scope: 'movies foods',
          user: 'user-42'
        }.to_json
      end

      let(:params) do
        {
          state: request.state,
          code: 'foobar'
        }
      end

      let(:expected_request_body) do
        URI.encode_www_form({
                              grant_type: 'authorization_code',
                              code: 'foobar',
                              redirect_uri: configatron.oauth.client.default_redirect_uri
                            })
      end

      let(:expected_reqeust_headers) do
        {
          'Content-Type' => 'application/x-www-form-urlencoded',
          'Authorization' => /^Basic \w+$/
        }
      end

      before do
        allow(Rails.logger).to receive(:info)
        allow(Faraday).to receive(:post).and_return(faraday_response)
      end

      it 'logs the state' do
        callback
        expect(Rails.logger)
          .to have_received(:info)
                .with("State value '#{request.state}' matches")
      end

      it 'logs the request to the auth server' do
        callback
        expect(Rails.logger)
          .to have_received(:info)
                .with("Requesting access token for code 'foobar'")
      end

      context 'when the auth server endpoint returns a successful response' do
        let(:expected_response_body) do
          {
            access_token: 'foo',
            refresh_token: 'raboof',
            scope: 'movies foods'
          }
        end

        it 'logs the access token' do
          callback
          expect(Rails.logger).to have_received(:info).with("Got access token: 'foo'")
        end

        it 'logs the refresh token' do
          callback
          expect(Rails.logger).to have_received(:info).with("Got refresh token: 'raboof'")
        end

        it 'logs the scope' do
          callback
          expect(Rails.logger).to have_received(:info).with("Got scope: 'movies foods'")
        end

        it 'creates an AccessToken record' do
          expect { callback }.to change(AccessToken, :count).from(0).to(1)
        end

        it 'assigns the correct attributes', :aggregate_failures do
          callback
          expect(AccessToken.last.access_token).to eq 'foo'
          expect(AccessToken.last.refresh_token).to eq 'raboof'
          expect(AccessToken.last.user).to eq 'user-42'
          expect(AccessToken.last.scope).to eq %w[movies foods]
          expect(AccessToken.last.token_type).to eq 'Bearer'
        end

        it 'returns the data to the front end' do
          callback
          expect(JSON.parse(response.body, symbolize_names: true)).to eq expected_response_body
        end

        it 'returns status 200' do
          callback
          expect(response).to be_successful
        end
      end

      context 'when the auth server returns an error response' do
        let(:body) { { error: 'oops' }.to_json }
        let(:status) { 421 }
        let(:success) { false }

        before do
          allow(Rails.logger).to receive(:error)
        end

        it 'logs an error' do
          callback
          expect(Rails.logger).to have_received(:error).with('oops')
        end

        it 'returns an error to the client' do
          callback
          expect(JSON.parse(response.body, symbolize_names: true))
            .to eq({ error: 'Unable to fetch access token, error (421)' })
        end

        it 'returns the HTTP status from the auth server' do
          callback
          expect(response.status).to eq 421
        end
      end
    end
  end
end
