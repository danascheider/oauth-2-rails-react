# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AuthorizationsController#token' do
  subject(:issue_token) { post token_path, headers:, params: }

  let(:headers) { {} }

  context 'when the client authenticates with the authorization header' do
    let!(:client) { create(:client) }

    let(:headers) do
      { 'Authorization' => "Basic #{credentials}" }
    end

    context 'when the client ID and client secret match' do
      let(:credentials) { Base64.encode64("#{client.client_id}:#{client.client_secret}") }

      context 'when the grant type is "authorization_code"' do
        let(:params) do
          URI.encode_www_form({
            grant_type: 'authorization_code',
            code:
          })
        end

        context 'when the params do not include an authorization code' do
          let(:code) { nil }

          before do
            allow(Rails.logger).to receive(:error)
          end

          it 'logs the error' do
            issue_token
            expect(Rails.logger).to have_received(:error).with("Unknown code ''")
          end

          it 'returns status 400' do
            issue_token
            expect(response.status).to eq 400
          end

          it 'returns an error message' do
            issue_token
            expect(JSON.parse(response.body)).to eq({ 'error' => 'invalid_grant' })
          end
        end

        context 'when the code is not present in the database' do
          let(:code) { 'foo' }

          before do
            allow(Rails.logger).to receive(:error)
          end

          it 'logs the error' do
            issue_token
            expect(Rails.logger).to have_received(:error).with("Unknown code 'foo'")
          end

          it 'returns a 400 response' do
            issue_token
            expect(response).to be_bad_request
          end

          it 'returns an error message' do
            issue_token
            expect(JSON.parse(response.body)).to eq({ 'error' => 'invalid_grant' })
          end
        end

        context 'with a valid authorization code' do
          context 'when the client ID matches' do
            let!(:authorization_code) { create(:authorization_code, client:) }
            let(:code) { authorization_code.code }

            before do
              allow(Rails.logger).to receive(:info)
            end

            it 'logs success' do
              issue_token
              expect(Rails.logger).to have_received(:info).with("Issued tokens for code '#{code}'")
            end

            it 'creates an access token' do
              expect { issue_token }.to change(AccessToken, :count).from(0).to(1)
            end

            it 'creates a refresh token' do
              expect { issue_token }.to change(RefreshToken, :count).from(0).to(1)
            end

            it 'returns status 200' do
              issue_token
              expect(response).to be_successful
            end

            it 'returns the new tokens' do
              issue_token
              expect(JSON.parse(response.body)).to eq({
                                                       'client_id' => client.client_id,
                                                       'user' => authorization_code.user.sub,
                                                       'access_token' => AccessToken.last.token,
                                                       'refresh_token' => RefreshToken.last.token,
                                                       'token_type' => 'Bearer',
                                                       'scope' => authorization_code.scope.join(' ')
                                                     })
            end

            it 'designates the tokens for the requested user', :aggregate_failures do
              issue_token
              expect(AccessToken.last.user).to eq authorization_code.user
              expect(RefreshToken.last.user).to eq authorization_code.user
            end
          end

          context "when the client ID doesn't match" do
            let!(:authorization_code) { create(:authorization_code) }
            let(:code) { authorization_code.code }

            before do
              allow(Rails.logger).to receive(:error)
            end

            it 'destroys the authorization code' do
              expect { issue_token }.to change(AuthorizationCode, :count).from(1).to(0)
            end

            it 'logs the error' do
              issue_token
              expect(Rails.logger)
                .to have_received(:error)
                      .with("Client mismatch, expected '#{authorization_code.client_id}', got '#{client.client_id}'")
            end

            it 'returns a 400 status' do
              issue_token
              expect(response).to be_bad_request
            end

            it 'returns an error message' do
              issue_token
              expect(JSON.parse(response.body)).to eq({ 'error' => 'invalid_grant' })
            end
          end
        end
      end

      context 'when the grant type is "client_credentials"'

      context 'when the grant type is "refresh_token"'

      context 'when the grant type is "password"'

      context 'with an unknown grant type'

      context 'when the grant type is missing' do
        let(:params) do
          URI.encode_www_form({
            code: 'foobar'
          })
        end

        before do
          allow(Rails.logger).to receive(:error)
        end

        it 'logs the error' do
          issue_token
          expect(Rails.logger).to have_received(:error).with("Unknown grant type ''")
        end

        it 'returns status 400' do
          issue_token
          expect(response).to be_bad_request
        end

        it 'returns an error message' do
          issue_token
          expect(JSON.parse(response.body)).to eq({ 'error' => 'unsupported_grant_type' })
        end
      end
    end

    context "when the client ID and client secret don't match" do
      let(:credentials) { "Basic #{Base64.encode64(client.client_id + ':secret')}" }

      let(:params) do
        URI.encode_www_form({
          grant_type: 'authorization_code',
          code: 'foobar'
        })
      end

      before do
        allow(Rails.logger).to receive(:error)
      end

      it 'logs the error' do
        issue_token
        expect(Rails.logger)
          .to have_received(:error)
                .with("Mismatched client secret, expected '#{client.client_secret}', got 'secret'")
      end

      it 'returns status 401' do
        issue_token
        expect(response).to be_unauthorized
      end

      it 'returns an error message' do
        issue_token
        expect(JSON.parse(response.body)).to eq({ 'error' => 'invalid_client' })
      end
    end
  end

  context 'when the client authenticates with body params' do
    context 'when the client ID and client secret match' do
      let!(:client) { create(:client) }

      context 'when the grant type is "authorization_code"' do
        let(:params) do
          URI.encode_www_form({
            client_id: client.client_id,
            client_secret: client.client_secret,
            grant_type: 'authorization_code',
            code:
          })
        end

        context 'when the params do not include an authorization code' do
          let(:code) { nil }

          before do
            allow(Rails.logger).to receive(:error)
          end

          it 'logs the error' do
            issue_token
            expect(Rails.logger).to have_received(:error).with("Unknown code ''")
          end

          it 'returns status 400' do
            issue_token
            expect(response.status).to eq 400
          end

          it 'returns an error message' do
            issue_token
            expect(JSON.parse(response.body)).to eq({ 'error' => 'invalid_grant' })
          end
        end

        context 'when the code is not present in the database' do
          let(:code) { 'foo' }

          before do
            allow(Rails.logger).to receive(:error)
          end

          it 'logs the error' do
            issue_token
            expect(Rails.logger).to have_received(:error).with("Unknown code 'foo'")
          end

          it 'returns a 400 response' do
            issue_token
            expect(response).to be_bad_request
          end

          it 'returns an error message' do
            issue_token
            expect(JSON.parse(response.body)).to eq({ 'error' => 'invalid_grant' })
          end
        end

        context 'with a valid authorization code' do
          context 'when the client ID matches' do
            let!(:authorization_code) { create(:authorization_code, client:) }
            let(:code) { authorization_code.code }

            before do
              allow(Rails.logger).to receive(:info)
            end

            it 'logs success' do
              issue_token
              expect(Rails.logger).to have_received(:info).with("Issued tokens for code '#{code}'")
            end

            it 'creates an access token' do
              expect { issue_token }.to change(AccessToken, :count).from(0).to(1)
            end

            it 'creates a refresh token' do
              expect { issue_token }.to change(RefreshToken, :count).from(0).to(1)
            end

            it 'returns status 200' do
              issue_token
              expect(response).to be_successful
            end

            it 'returns the new tokens' do
              issue_token
              expect(JSON.parse(response.body)).to eq({
                                                       'client_id' => client.client_id,
                                                       'user' => authorization_code.user.sub,
                                                       'access_token' => AccessToken.last.token,
                                                       'refresh_token' => RefreshToken.last.token,
                                                       'token_type' => 'Bearer',
                                                       'scope' => authorization_code.scope.join(' ')
                                                     })
            end

            it 'designates the tokens for the requested user', :aggregate_failures do
              issue_token
              expect(AccessToken.last.user).to eq authorization_code.user
              expect(RefreshToken.last.user).to eq authorization_code.user
            end
          end

          context "when the client ID doesn't match" do
            let!(:authorization_code) { create(:authorization_code) }
            let(:code) { authorization_code.code }

            before do
              allow(Rails.logger).to receive(:error)
            end

            it 'destroys the authorization code' do
              expect { issue_token }.to change(AuthorizationCode, :count).from(1).to(0)
            end

            it 'logs the error' do
              issue_token
              expect(Rails.logger)
                .to have_received(:error)
                      .with("Client mismatch, expected '#{authorization_code.client_id}', got '#{client.client_id}'")
            end

            it 'returns a 400 status' do
              issue_token
              expect(response).to be_bad_request
            end

            it 'returns an error message' do
              issue_token
              expect(JSON.parse(response.body)).to eq({ 'error' => 'invalid_grant' })
            end
          end
        end
      end

      context 'when the grant type is "client_credentials"'

      context 'when the grant type is "refresh_token"'

      context 'when the grant type is "password"'

      context 'with an unknown grant type'
    end

    context "when the client ID and client secret don't match" do
      let!(:client) { create(:client) }

      let(:params) do
        URI.encode_www_form({
          client_id: client.client_id,
          client_secret: 'secret',
          grant_type: 'authorization_code',
          code: 'foobar'
        })
      end

      before do
        allow(Rails.logger).to receive(:error)
      end

      it 'logs the error' do
        issue_token
        expect(Rails.logger)
          .to have_received(:error)
                .with("Mismatched client secret, expected '#{client.client_secret}', got 'secret'")
      end

      it 'returns status 401' do
        issue_token
        expect(response).to be_unauthorized
      end

      it 'returns an error message' do
        issue_token
        expect(JSON.parse(response.body)).to eq({ 'error' => 'invalid_client' })
      end
    end
  end

  context 'when the client authenticates with multiple methods' do
    let!(:client) { create(:client) }
    let(:credentials) { Base64.encode64("#{client.client_id}:#{client.client_secret}") }

    let(:headers) do
      { 'Authorization' => "Basic #{credentials}" }
    end

    let(:params) do
      URI.encode_www_form({
        client_id: client.client_id,
        client_secret: client.client_secret,
        grant_type: 'authorization_code',
        code: 'foobar'
      })
    end

    before do
      allow(Rails.logger).to receive(:error)
    end

    it 'logs the error' do
      issue_token
      expect(Rails.logger).to have_received(:error).with('Client attempted to authenticate with multiple methods')
    end

    it 'returns status 401' do
      issue_token
      expect(response).to be_unauthorized
    end

    it 'returns an error message' do
      issue_token
      expect(JSON.parse(response.body)).to eq({ 'error' => 'invalid_client' })
    end
  end

  context "when the client doesn't authenticate" do
    let(:params) do
      URI.encode_www_form({
        grant_type: 'authorization_code', # doesn't actually matter here
        code: 'foobar'
      })
    end

    before do
      allow(Rails.logger).to receive(:error)
    end

    it 'logs the error' do
      issue_token
      expect(Rails.logger).to have_received(:error).with("Unknown client ''")
    end

    it 'returns status 401' do
      issue_token
      expect(response).to be_unauthorized
    end

    it 'returns an error response' do
      issue_token
      expect(JSON.parse(response.body)).to eq({ 'error' => 'invalid_client' })
    end
  end

  context "when the client can't be identified" do
    let(:credentials) { Base64.encode64('client:secret') }

    let(:headers) do
      {
        'Authorization' => "Basic #{credentials}"
      }
    end

    let(:params) do
      URI.encode_www_form({
        grant_type: 'authorization_code', # doesn't matter for this
        code: 'foobar'
      })
    end

    before do
      allow(Rails.logger).to receive(:error)
    end

    it 'logs the error' do
      issue_token
      expect(Rails.logger).to have_received(:error).with("Unknown client 'client'")
    end

    it 'returns status 401' do
      issue_token
      expect(response).to be_unauthorized
    end

    it 'returns an error response' do
      issue_token
      expect(JSON.parse(response.body)).to eq({ 'error' => 'invalid_client' })
    end
  end
end