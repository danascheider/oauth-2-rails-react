# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Authorizations', type: :request do
  describe 'GET /authorize' do
    subject(:authorize) { get authorize_path, params: }

    let(:state) { SecureRandom.hex(8) }

    let(:params) do
      URI.encode_www_form({
        client_id:,
        scope:,
        redirect_uri:,
        state:,
        response_type: 'code',
      })
    end

    context 'when a client can be identified' do
      let(:client) { create(:client) }
      let(:client_id) { client.client_id }
      let(:scope) { client.scope.join(' ') }
      let(:redirect_uri) { client.redirect_uris.first }

      context 'when the redirect URI is invalid' do
        let(:redirect_uri) { 'https://example.net/callback' }

        before do
          allow(Rails.logger).to receive(:error)
        end

        it 'logs the error' do
          authorize
          expect(Rails.logger)
            .to have_received(:error)
                  .with("Mismatched redirect URI, expected https://example.com/callback, got https://example.net/callback")
        end

        it 'returns a success status' do
          authorize
          expect(response).to be_successful
        end

        it "doesn't create a Request object" do
          expect { authorize }.not_to change(Request, :count)
        end
      end

      context 'when all requested scopes are permitted' do
        context 'when all client scopes are requested' do
          it 'creates a request object' do
            expect { authorize }.to change(Request, :count).from(0).to(1)
          end

          it 'uses the right scope for the request object' do
            authorize
            expect(Request.last.scope).to eq client.scope
          end

          it 'is successful' do
            authorize
            expect(response).to be_successful
          end
        end

        context 'when a subset of client scopes are requested' do
          let(:scope) { 'movies foods' }

          it 'sets a limited scope on the Request object' do
            authorize
            expect(Request.last.scope).to eq(%w[movies foods])
          end
        end
      end

      context 'when disallowed scopes are requested' do
        let(:scope) { 'colors places movies' }
        let(:expected_redirect_uri) { "#{redirect_uri}?error=invalid_scope"}

        before do
          allow(Rails.logger).to receive(:error)
        end

        it 'logs the error' do
          authorize
          expect(Rails.logger)
            .to have_received(:error)
                  .with('Invalid scope(s): colors,places')
        end

        it 'redirects' do
          authorize
          expect(response).to redirect_to(expected_redirect_uri)
        end

        it "doesn't create a Request object" do
          expect { authorize }.not_to change(Request, :count)
        end
      end

      context 'when no state value is given'
    end

    context 'when no client can be found' do
      let(:client_id) { 'foobar' }
      let(:redirect_uri) { 'https://example.com/callback' }
      let(:scope) { %w[movies foods music] }

      before do
        allow(Rails.logger).to receive(:error)
      end

      it 'logs the error' do
        authorize
        expect(Rails.logger).to have_received(:error).with("Unknown client 'foobar'")
      end

      it 'returns a success status' do
        authorize
        expect(response).to be_successful
      end

      it "doesn't create a Request object" do
        expect { authorize }.not_to change(Request, :count)
      end
    end
  end

  describe 'POST /approve' do
    subject(:approve) { post approve_path, params: }

    context 'when there is a matching Request object' do
      let!(:request) { create(:request, response_type:, state:, scope:) }

      let(:state) { SecureRandom.hex(8) }
      let(:response_type) { 'code' }
      let(:user) { 'someuser' }
      let(:scope) { %w[movies foods music] }

      context 'when the user has approved authorization' do
        context 'when disallowed scopes are present' do
          let(:params) do
            URI.encode_www_form({
              reqid: request.reqid,
              user: 'doesntmatter',
              response_type: 'token',
              scope_movies: '1',
              scope_foods: '0',
              scope_animals: '1',
              approve: true
            })
          end

          before do
            allow(Rails.logger).to receive(:error)
          end

          it 'logs the error' do
            approve
            expect(Rails.logger)
              .to have_received(:error)
                    .with('Invalid scope(s) animals')
          end

          it 'redirects' do
            approve
            expect(response).to redirect_to "#{request.redirect_uri}?error=invalid_scope"
          end

          it 'destroys the Request object' do
            expect { approve }.to change(Request, :count).from(1).to(0)
          end
        end

        context 'when the response type is "code"' do
          let(:params) do
            URI.encode_www_form({
              reqid: request.reqid,
              user: user_sub,
              response_type: 'code',
              scope_foods: '1',
              scope_movies: '1',
              scope_music: '0',
              approve: true
            })
          end

          context 'when there is no matching user' do
            let(:user_sub) { 'doesntmatter' }

            before do
              allow(Rails.logger).to receive(:error)
            end

            it 'logs the error' do
              approve
              expect(Rails.logger)
                .to have_received(:error)
                      .with("Unknown user 'doesntmatter'")
            end

            it "doesn't issue a code" do
              expect { approve }.not_to change(AuthorizationCode, :count)
            end

            it 'destroys the Request object' do
              expect { approve }.to change(Request, :count).from(1).to(0)
            end

            it 'returns a 500 error' do
              approve
              expect(response.status).to eq 500
            end
          end

          context 'when there is a matching user' do
            let(:user) { create(:user) }
            let(:user_sub) { user.sub }
            let(:expected_redirect_uri) do
              "#{request.redirect_uri}?code=#{AuthorizationCode.last.code}&state=#{request.state}"
            end

            before do
              allow(Rails.logger).to receive(:info)
            end

            it 'logs the user' do
              approve
              expect(Rails.logger).to have_received(:info).with "User '#{user_sub}'"
            end

            it 'creates an authorization code' do
              expect { approve }.to change(AuthorizationCode, :count).from(0).to(1)
            end

            it 'assigns the correct values', :aggregate_failures do
              approve
              expect(AuthorizationCode.last.user).to eq user
              expect(AuthorizationCode.last.client).to eq request.client
              expect(AuthorizationCode.last.scope).to eq request.scope
              expect(AuthorizationCode.last.expires_at).to be_present
            end

            it 'logs the authorization code' do
              approve
              expect(Rails.logger)
                .to have_received(:info)
                      .with("Issuing authorization code '#{AuthorizationCode.last.code}' for client '#{request.client_id}' and user '#{user_sub}'")
            end

            it 'destroys the Request object' do
              expect { approve }.to change(Request, :count).from(1).to(0)
            end

            it 'redirects' do
              approve
              expect(response).to redirect_to expected_redirect_uri
            end
          end
        end

        context 'when the response type is "token"' do
          let(:response_type) { 'token' }
        end

        context 'when the response type is something else' do
          let(:params) do
            {
              reqid: request.reqid,
              response_type: 'foo',
              state: request.state,
              user: user_sub,
              scope_foods: '1',
              scope_movies: '1',
              scope_music: '1',
              approve: true
            }
          end

          before do
            allow(Rails.logger).to receive(:error)
          end

          context 'when there is no matching user' do
            let(:user_sub) { 'doesntmatter' }

            it 'logs the error' do
              approve
              expect(Rails.logger).to have_received(:error).with("Unknown user 'doesntmatter'")
            end

            it "doesn't create an authorization code" do
              expect { approve }.not_to change(AuthorizationCode, :count)
            end

            it 'destroys the request object' do
              expect { approve }.to change(Request, :count).from(1).to(0)
            end

            it 'returns status 500' do
              approve
              expect(response.status).to eq 500
            end
          end

          context 'when there is a matching user' do
            let(:user_sub) { create(:user).sub }

            it 'logs the error' do
              approve
              expect(Rails.logger).to have_received(:error).with("Unsupported response type 'foo'")
            end

            it "doesn't create an authorization code" do
              expect { approve }.not_to change(AuthorizationCode, :count)
            end

            it 'destroys the request object' do
              expect { approve }.to change(Request, :count).from(1).to(0)
            end

            it 'redirects with an error' do
              approve
              expect(response).to redirect_to "#{request.redirect_uri}?error=unsupported_response_type"
            end
          end
        end
      end

      context 'when the user has denied authorization' do
        let(:params) do
          URI.encode_www_form({
            reqid: request.reqid,
            user: 'doesntmatter',
            deny: true
          })
        end

        before do
          allow(Rails.logger).to receive(:error)
        end

        it 'logs the error' do
          approve
          expect(Rails.logger)
            .to have_received(:error)
                  .with("User denied access for client '#{request.client_id}'")
        end

        it 'redirects with an error' do
          approve
          expect(response)
            .to redirect_to("#{request.redirect_uri}?error=access_denied")
        end

        it 'destroys the request object' do
          expect { approve }.to change(Request, :count).from(1).to(0)
        end
      end
    end

    context 'when no matching Request object can be found' do
      let(:params) do
        URI.encode_www_form({
          reqid: 'doesntmatter',
          user: 'doesntmatter',
          approve: true
        })
      end

      before do
        allow(Rails.logger).to receive(:error)
      end

      it 'logs the error' do
        approve
        expect(Rails.logger)
          .to have_received(:error)
                .with("No matching authorization request for reqid 'doesntmatter'")
      end

      it 'returns status 400' do
        approve
        expect(response).to be_bad_request
      end
    end
  end
end
