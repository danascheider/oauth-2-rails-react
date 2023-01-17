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

      context 'when the grant type is "client_credentials"' do
        let(:params) do
          URI.encode_www_form({
            grant_type: 'client_credentials',
            scope:
          })
        end


        context 'with valid scopes' do
          let(:scope) { 'fruit veggies meats' }

          before do
            allow(Rails.logger).to receive(:info)
          end

          it 'logs success' do
            issue_token
            expect(Rails.logger).to have_received(:info).with("Issuing access token '#{AccessToken.last.token}' for client '#{client.client_id}' with scope 'fruit veggies meats'")
          end

          it 'issues an access token' do
            expect { issue_token }.to change(AccessToken, :count).from(0).to(1)
          end

          it "doesn't issue a refresh token" do
            expect { issue_token }.not_to change(RefreshToken, :count)
          end

          it 'returns the access token' do
            issue_token
            expect(JSON.parse(response.body)).to eq({
                                                     'access_token' => AccessToken.last.token,
                                                     'token_type' => 'Bearer',
                                                     'scope' => 'fruit veggies meats'
                                                   })
          end

          it 'returns a 200 response' do
            issue_token
            expect(response).to be_successful
          end
        end

        context 'when there are disallowed scopes' do
          let(:scope) { 'fruit veggies meats dairy' }

          before do
            allow(Rails.logger).to receive(:error)
          end

          it 'logs the error' do
            issue_token
            expect(Rails.logger).to have_received(:error).with('Invalid scope(s): dairy')
          end

          it "doesn't create an access token" do
            expect { issue_token }.not_to change(AccessToken, :count)
          end

          it "doesn't create a refresh token" do
            expect { issue_token }.not_to change(RefreshToken, :count)
          end

          it 'returns status 400' do
            issue_token
            expect(response.status).to eq 400
          end

          it 'returns an error message' do
            issue_token
            expect(JSON.parse(response.body)).to eq({ 'error' => 'invalid_scope' })
          end
        end
      end

      context 'when the grant type is "refresh_token"' do
        let(:params) do
          URI.encode_www_form({
            grant_type: 'refresh_token',
            refresh_token: 'foobar'
          })
        end

        context 'when there is a matching refresh token' do
          let!(:refresh_token) { create(:refresh_token, token: 'foobar', client:) }

          before do
            allow(Rails.logger).to receive(:info)
          end

          it 'creates an access token' do
            expect { issue_token }.to change(AccessToken, :count).from(0).to(1)
          end

          it 'logs success' do
            issue_token
            expect(Rails.logger)
              .to have_received(:info)
                    .with("Issuing access token '#{AccessToken.last.token}' for refresh token 'foobar'")
          end

          it 'returns the tokens' do
            issue_token
            expect(JSON.parse(response.body)).to eq ({
              'access_token' => AccessToken.last.token,
              'refresh_token' => 'foobar',
              'scope' => 'fruit veggies',
              'token_type' => 'Bearer'
            })
          end
        end

        context 'when there is not a matching refresh token' do
          before do
            allow(Rails.logger).to receive(:error)
          end

          it 'logs the error' do
            issue_token
            expect(Rails.logger).to have_received(:error).with('No matching refresh token was found.')
          end

          it 'returns a 401 response' do
            issue_token
            expect(response).to be_unauthorized
          end
        end

        context 'when the refresh token belongs to another client' do
          let!(:refresh_token) { create(:refresh_token, token: 'foobar') }

          before do
            allow(Rails.logger).to receive(:error)
            allow(controller).to receive(:head)
          end

          it 'logs the error' do
            issue_token
            expect(Rails.logger)
              .to have_received(:error)
                    .with("Invalid client using a refresh token, expected '#{refresh_token.client_id}', got '#{client.client_id}'")
          end

          it 'returns a 400 error' do
            issue_token
            expect(response).to be_bad_request
          end
        end
      end

      context 'when the grant type is "password"' do
        let(:params) do
          URI.encode_www_form({
            grant_type: 'password',
            username: 'alice',
            password:,
            scope:
          })
        end

        context 'when there is no matching user' do
          let(:password) { 'wonderland' }
          let(:scope) { 'fruit veggies' }

          before do
            allow(Rails.logger).to receive(:error)
          end

          it 'logs the error' do
            issue_token
            expect(Rails.logger).to have_received(:error).with("Unknown user 'alice'")
          end

          it "doesn't issue a token" do
            expect { issue_token }.not_to change(AccessToken, :count)
          end

          it 'returns an unauthorized response' do
            issue_token
            expect(response).to be_unauthorized
          end

          it 'returns an error message' do
            issue_token
            expect(JSON.parse(response.body)).to eq({ 'error' => 'invalid_grant' })
          end
        end

        context 'when the password is wrong' do
          let!(:user) { create(:user, username: 'alice', password: 'foo') }
          let(:password) { 'wonderland' }
          let(:scope) { 'fruit veggies' }

          before do
            allow(Rails.logger).to receive(:error)
          end

          it "doesn't issue a token" do
            expect { issue_token }.not_to change(AccessToken, :count)
          end

          it 'logs the error' do
            issue_token
            expect(Rails.logger)
              .to have_received(:error)
                    .with("Mismatched resource owner password, expected 'foo', got 'wonderland'")
          end

          it 'returns a 401 response' do
            issue_token
            expect(response).to be_unauthorized
          end

          it 'returns an error message' do
            issue_token
            expect(JSON.parse(response.body)).to eq({ 'error' => 'invalid_grant' })
          end
        end

        context 'when the user has no password' do
          let!(:user) { create(:user, username: 'alice', password: nil) }
          let(:password) { nil }
          let(:scope) { 'fruit veggies' }

          before do
            allow(Rails.logger).to receive(:error)
          end

          it "doesn't issue a token" do
            expect { issue_token }.not_to change(AccessToken, :count)
          end

          it 'logs the error' do
            issue_token
            expect(Rails.logger)
              .to have_received(:error)
                    .with('Attempted password grant type but user has no password')
          end

          it 'returns status 401' do
            issue_token
            expect(response).to be_unauthorized
          end

          it 'returns an error message' do
            issue_token
            expect(JSON.parse(response.body)).to eq({ 'error' => 'invalid_grant' })
          end
        end

        context 'when the username and password are valid' do
          let!(:user) { create(:user, username: 'alice', password:) }
          let(:password) { 'wonderland' }

          context 'when disallowed scopes are present' do
            let(:scope) { 'fruit veggies meats dairy' }

            before do
              allow(Rails.logger).to receive(:error)
            end

            it "doesn't issue a token" do
              expect { issue_token }.not_to change(AccessToken, :count)
            end

            it 'logs the error' do
              issue_token
              expect(Rails.logger)
                .to have_received(:error)
                      .with("Invalid scope(s): dairy")
            end

            it 'returns a 400 response' do
              issue_token
              expect(response).to be_bad_request
            end

            it 'returns an error message' do
              issue_token
              expect(JSON.parse(response.body)).to eq({ 'error' => 'invalid_scope' })
            end
          end

          context 'when all scopes are valid' do
            let(:scope) { 'fruit veggies' }

            it 'issues an access token' do
              expect { issue_token }.to change(AccessToken, :count).from(0).to(1)
            end

            it "doesn't issue a refresh token" do
              expect { issue_token }.not_to change(RefreshToken, :count)
            end

            it 'returns a 200 response' do
              issue_token
              expect(response.status).to eq 200
            end

            it 'returns the token' do
              issue_token
              expect(JSON.parse(response.body)).to eq({
                                                       'access_token' => AccessToken.last.token,
                                                       'token_type' => 'Bearer',
                                                       'scope' => 'fruit veggies',
                                                       'client_id' => client.client_id,
                                                       'user' => user.sub
                                                     })
            end
          end
        end
      end

      context 'with an unknown grant type' do
        let(:params) do
          URI.encode_www_form({
            grant_type: 'something_else'
          })
        end

        before do
          allow(Rails.logger).to receive(:error)
        end

        it "doesn't issue a token" do
          expect { issue_token }.not_to change(AccessToken, :count)
        end

        it 'logs the error' do
          issue_token
          expect(Rails.logger).to have_received(:error).with("Unknown grant type 'something_else'")
        end

        it 'returns a 400 status' do
          issue_token
          expect(response).to be_bad_request
        end

        it 'returns an error message' do
          issue_token
          expect(JSON.parse(response.body)).to eq({ 'error' => 'unsupported_grant_type' })
        end
      end

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

      context 'when the grant type is "client_credentials"' do
        let(:params) do
          URI.encode_www_form({
            client_id: client.client_id,
            client_secret: client.client_secret,
            grant_type: 'client_credentials',
            scope:
          })
        end

        context 'with valid scopes' do
          let(:scope) { 'fruit veggies meats' }

          before do
            allow(Rails.logger).to receive(:info)
          end

          it 'logs success' do
            issue_token
            expect(Rails.logger).to have_received(:info).with("Issuing access token '#{AccessToken.last.token}' for client '#{client.client_id}' with scope 'fruit veggies meats'")
          end

          it 'issues an access token' do
            expect { issue_token }.to change(AccessToken, :count).from(0).to(1)
          end

          it "doesn't issue a refresh token" do
            expect { issue_token }.not_to change(RefreshToken, :count)
          end

          it 'returns the access token' do
            issue_token
            expect(JSON.parse(response.body)).to eq({
                                                     'access_token' => AccessToken.last.token,
                                                     'token_type' => 'Bearer',
                                                     'scope' => 'fruit veggies meats'
                                                   })
          end

          it 'returns a 200 response' do
            issue_token
            expect(response).to be_successful
          end
        end

        context 'when there are disallowed scopes' do
          let(:scope) { 'fruit veggies meats dairy' }

          before do
            allow(Rails.logger).to receive(:error)
          end

          it 'logs the error' do
            issue_token
            expect(Rails.logger).to have_received(:error).with('Invalid scope(s): dairy')
          end

          it "doesn't create an access token" do
            expect { issue_token }.not_to change(AccessToken, :count)
          end

          it "doesn't create a refresh token" do
            expect { issue_token }.not_to change(RefreshToken, :count)
          end

          it 'returns status 400' do
            issue_token
            expect(response.status).to eq 400
          end

          it 'returns an error message' do
            issue_token
            expect(JSON.parse(response.body)).to eq({ 'error' => 'invalid_scope' })
          end
        end
      end

      context 'when the grant type is "refresh_token"' do
        let(:params) do
          URI.encode_www_form({
            client_id: client.client_id,
            client_secret: client.client_secret,
            grant_type: 'refresh_token',
            refresh_token: 'foobar'
          })
        end

        context 'when there is a matching refresh token' do
          let!(:refresh_token) { create(:refresh_token, token: 'foobar', client:) }

          before do
            allow(Rails.logger).to receive(:info)
          end

          it 'creates an access token' do
            expect { issue_token }.to change(AccessToken, :count).from(0).to(1)
          end

          it 'logs success' do
            issue_token
            expect(Rails.logger)
              .to have_received(:info)
                    .with("Issuing access token '#{AccessToken.last.token}' for refresh token 'foobar'")
          end

          it 'returns the tokens' do
            issue_token
            expect(JSON.parse(response.body)).to eq ({
              'access_token' => AccessToken.last.token,
              'refresh_token' => 'foobar',
              'scope' => 'fruit veggies',
              'token_type' => 'Bearer'
            })
          end
        end

        context 'when there is not a matching refresh token' do
          before do
            allow(Rails.logger).to receive(:error)
          end

          it 'logs the error' do
            issue_token
            expect(Rails.logger).to have_received(:error).with('No matching refresh token was found.')
          end

          it 'returns a 401 response' do
            issue_token
            expect(response).to be_unauthorized
          end
        end

        context 'when the refresh token belongs to another client' do
          let!(:refresh_token) { create(:refresh_token, token: 'foobar') }

          before do
            allow(Rails.logger).to receive(:error)
            allow(controller).to receive(:head)
          end

          it 'logs the error' do
            issue_token
            expect(Rails.logger)
              .to have_received(:error)
                    .with("Invalid client using a refresh token, expected '#{refresh_token.client_id}', got '#{client.client_id}'")
          end

          it 'returns a 400 error' do
            issue_token
            expect(response).to be_bad_request
          end
        end
      end

      context 'when the grant type is "password"' do
        let(:params) do
          URI.encode_www_form({
            client_id: client.client_id,
            client_secret: client.client_secret,
            grant_type: 'password',
            username: 'alice',
            password:,
            scope:
          })
        end

        context 'when there is no matching user' do
          let(:password) { 'wonderland' }
          let(:scope) { 'fruit veggies' }

          before do
            allow(Rails.logger).to receive(:error)
          end

          it 'logs the error' do
            issue_token
            expect(Rails.logger).to have_received(:error).with("Unknown user 'alice'")
          end

          it "doesn't issue a token" do
            expect { issue_token }.not_to change(AccessToken, :count)
          end

          it 'returns an unauthorized response' do
            issue_token
            expect(response).to be_unauthorized
          end

          it 'returns an error message' do
            issue_token
            expect(JSON.parse(response.body)).to eq({ 'error' => 'invalid_grant' })
          end
        end

        context 'when the password is wrong' do
          let!(:user) { create(:user, username: 'alice', password: 'foo') }
          let(:password) { 'wonderland' }
          let(:scope) { 'fruit veggies' }

          before do
            allow(Rails.logger).to receive(:error)
          end

          it "doesn't issue a token" do
            expect { issue_token }.not_to change(AccessToken, :count)
          end

          it 'logs the error' do
            issue_token
            expect(Rails.logger)
              .to have_received(:error)
                    .with("Mismatched resource owner password, expected 'foo', got 'wonderland'")
          end

          it 'returns a 401 response' do
            issue_token
            expect(response).to be_unauthorized
          end

          it 'returns an error message' do
            issue_token
            expect(JSON.parse(response.body)).to eq({ 'error' => 'invalid_grant' })
          end
        end

        context 'when the user has no password' do
          let!(:user) { create(:user, username: 'alice', password: nil) }
          let(:password) { nil }
          let(:scope) { 'fruit veggies' }

          before do
            allow(Rails.logger).to receive(:error)
          end

          it "doesn't issue a token" do
            expect { issue_token }.not_to change(AccessToken, :count)
          end

          it 'logs the error' do
            issue_token
            expect(Rails.logger)
              .to have_received(:error)
                    .with('Attempted password grant type but user has no password')
          end

          it 'returns status 401' do
            issue_token
            expect(response).to be_unauthorized
          end

          it 'returns an error message' do
            issue_token
            expect(JSON.parse(response.body)).to eq({ 'error' => 'invalid_grant' })
          end
        end

        context 'when the username and password are valid' do
          let!(:user) { create(:user, username: 'alice', password:) }
          let(:password) { 'wonderland' }

          context 'when disallowed scopes are present' do
            let(:scope) { 'fruit veggies meats dairy' }

            before do
              allow(Rails.logger).to receive(:error)
            end

            it "doesn't issue a token" do
              expect { issue_token }.not_to change(AccessToken, :count)
            end

            it 'logs the error' do
              issue_token
              expect(Rails.logger)
                .to have_received(:error)
                      .with("Invalid scope(s): dairy")
            end

            it 'returns a 400 response' do
              issue_token
              expect(response).to be_bad_request
            end

            it 'returns an error message' do
              issue_token
              expect(JSON.parse(response.body)).to eq({ 'error' => 'invalid_scope' })
            end
          end

          context 'when all scopes are valid' do
            let(:scope) { 'fruit veggies' }

            it 'issues an access token' do
              expect { issue_token }.to change(AccessToken, :count).from(0).to(1)
            end

            it "doesn't issue a refresh token" do
              expect { issue_token }.not_to change(RefreshToken, :count)
            end

            it 'returns a 200 response' do
              issue_token
              expect(response.status).to eq 200
            end

            it 'returns the token' do
              issue_token
              expect(JSON.parse(response.body)).to eq({
                                                       'access_token' => AccessToken.last.token,
                                                       'token_type' => 'Bearer',
                                                       'scope' => 'fruit veggies',
                                                       'client_id' => client.client_id,
                                                       'user' => user.sub
                                                     })
            end
          end
        end
      end

      context 'with an unknown grant type' do
        let(:params) do
          URI.encode_www_form({
            client_id: client.client_id,
            client_secret: client.client_secret,
            grant_type: 'something_else'
          })
        end

        before do
          allow(Rails.logger).to receive(:error)
        end

        it "doesn't issue a token" do
          expect { issue_token }.not_to change(AccessToken, :count)
        end

        it 'logs the error' do
          issue_token
          expect(Rails.logger).to have_received(:error).with("Unknown grant type 'something_else'")
        end

        it 'returns a 400 status' do
          issue_token
          expect(response).to be_bad_request
        end

        it 'returns an error message' do
          issue_token
          expect(JSON.parse(response.body)).to eq({ 'error' => 'unsupported_grant_type' })
        end
      end

      context 'when the grant type is missing' do
        let(:params) do
          URI.encode_www_form({
            client_id: client.client_id,
            client_secret: client.client_secret,
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