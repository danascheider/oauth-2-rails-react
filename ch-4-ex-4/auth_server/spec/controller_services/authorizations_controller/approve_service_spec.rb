# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthorizationsController::ApproveService do
  subject(:perform) { described_class.new(controller, body_params:).perform }

  let(:controller) { instance_double(AuthorizationsController) }

  let(:body_params) do
    {
      reqid:,
      user:,
      approve: true
    }
  end

  context 'when there is no matching Request object' do
    let(:reqid) { 'doesntmatter' }
    let(:user) { 'doesntmatter' }
    let(:approve) { true }

    before do
      allow(Rails.logger).to receive(:error)
      allow(controller).to receive(:render)
    end

    it 'logs the error' do
      perform
      expect(Rails.logger)
        .to have_received(:error)
              .with("No matching authorization request for reqid 'doesntmatter'")
    end

    it 'renders the template' do
      perform
      expect(controller)
        .to have_received(:render)
              .with('error', locals: { error: 'No matching authorization request' }, status: :bad_request)
    end
  end

  context 'when the user approves the authorization request' do
    let!(:request) { create(:request, redirect_uri: 'https://example.com/callback?foo=bar', scope:) }

    let(:body_params) do
      {
        reqid: request.reqid,
        user: 'doesntmatter',
        response_type: response_type,
        scope_movies: '1',
        scope_foods: '0',
        scope_music: '1',
        approve: true
      }
    end

    context 'when the response_type is "code"' do
      let(:scope) { %w[movies music] }
      let(:response_type) { 'code' }

      context 'when there is a matching user' do
        let(:user) { create(:user) }

        let(:body_params) do
          {
            reqid: request.reqid,
            user: user.sub,
            response_type: response_type,
            scope_movies: '1',
            scope_foods: '0',
            scope_music: '1',
            approve: true
          }
        end

        before do
          allow(Rails.logger).to receive(:info)
          allow(controller).to receive(:redirect_to)
        end

        it 'logs the user' do
          perform
          expect(Rails.logger).to have_received(:info).with "User '#{user.sub}'"
        end

        it 'creates an authorization code' do
          expect { perform }.to change(AuthorizationCode, :count).from(0).to(1)
        end

        it 'assigns the correct values', :aggregate_failures do
          perform
          expect(AuthorizationCode.last.user).to eq user
          expect(AuthorizationCode.last.client).to eq request.client
          expect(AuthorizationCode.last.scope).to eq %w[movies music]
          expect(AuthorizationCode.last.expires_at).to be_present
        end

        it 'logs the authorization code' do
          perform
          expect(Rails.logger)
            .to have_received(:info)
                  .with("Issuing authorization code '#{AuthorizationCode.last.code}' for client '#{request.client_id}' and user '#{user.sub}'")
        end

        it 'destroys the Request object' do
          expect { perform }.to change(Request, :count).from(1).to(0)
        end

        it 'redirects' do
          perform
          expect(controller)
            .to have_received(:redirect_to)
                  .with(
                    "#{request.redirect_uri}&code=#{AuthorizationCode.last.code}&state=#{request.state}",
                    status: :found,
                    allow_other_host: true
                  )
        end
      end

      context 'when there is no matching user' do
        before do
          allow(Rails.logger).to receive(:error)
          allow(controller).to receive(:render)
        end

        it 'logs the error' do
          perform
          expect(Rails.logger)
            .to have_received(:error)
                  .with("Unknown user 'doesntmatter'")
        end

        it "doesn't create an AuthorizationCode" do
          expect { perform }.not_to change(AuthorizationCode, :count)
        end

        it 'destroys the Request object' do
          expect { perform }.to change(Request, :count).from(1).to(0)
        end

        it 'renders the error page' do
          perform
          expect(controller)
            .to have_received(:render)
                  .with(
                    'error',
                    locals: { error: "Unknown user 'doesntmatter'" },
                    status: :internal_server_error
                  )
        end
      end
    end

    context 'when the response_type is "token"' do
      let(:scope) { %w[foods movies music] }

      let(:body_params) do
        {
          reqid: request.reqid,
          response_type: 'token',
          state: request.state,
          user: user_sub,
          scope_foods: '1',
          scope_movies: '1',
          scope_music: '1',
          approve: true
        }
      end

      context 'when there is a matching user' do
        let(:user) { create(:user) }
        let(:user_sub) { user.sub }

        context 'when the user has an existing refresh token' do
          let!(:refresh_token) { create(:refresh_token, client: request.client, user:, scope:) }

          let(:expected_redirect_uri) do
            query = {
              access_token: AccessToken.last.token,
              refresh_token: refresh_token.token,
              token_type: 'Bearer',
              scope: scope.join(' '),
              client_id: request.client_id,
              user: user_sub
            }
            uri = URI.parse(request.redirect_uri)
            query = CGI.parse(uri.query || '').merge(query)
            uri.query = URI.encode_www_form(query)
            uri.to_s
          end

          before do
            allow(controller).to receive(:redirect_to)
          end

          it 'creates an access token' do
            expect { perform }.to change(AccessToken, :count).from(0).to(1)
          end

          it 'assigns the correct attributes', :aggregate_failures do
            perform
            expect(AccessToken.last.user).to eq user
            expect(AccessToken.last.client).to eq request.client
            expect(AccessToken.last.scope).to eq scope
          end

          it "doesn't create an authorization code" do
            expect { perform }.not_to change(AuthorizationCode, :count)
          end

          it "doesn't create a new refresh token" do
            expect { perform }.not_to change(RefreshToken, :count)
          end

          it 'redirects with the tokens' do
            perform
            expect(controller)
              .to have_received(:redirect_to)
                    .with(expected_redirect_uri, status: :found, allow_other_host: true)
          end
        end
      end

      context 'when there is no matching user' do
        let(:user_sub) { 'doesntmatter' }

        before do
          allow(Rails.logger).to receive(:error)
          allow(controller).to receive(:render)
        end

        it 'logs the error' do
          perform
          expect(Rails.logger).to have_received(:error).with("Unknown user 'doesntmatter'")
        end

        it "doesn't create an authorization code" do
          expect { perform }.not_to change(AuthorizationCode, :count)
        end

        it 'destroys the request object' do
          expect { perform }.to change(Request, :count).from(1).to(0)
        end

        it 'renders the template with an error status' do
          perform
          expect(controller)
            .to have_received(:render)
                  .with(
                    'error',
                    locals: { error: "Unknown user '#{user_sub}'" },
                    status: :internal_server_error
                  )
        end
      end
    end

    context 'when the response type is something else' do
      let(:scope) { %w[foods movies music] }

      let(:body_params) do
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

      context 'when there is no matching user' do
        let(:user_sub) { 'doesntmatter' }

        before do
          allow(Rails.logger).to receive(:error)
          allow(controller).to receive(:render)
        end

        it 'logs the error' do
          perform
          expect(Rails.logger).to have_received(:error).with("Unknown user 'doesntmatter'")
        end

        it "doesn't create an authorization code" do
          expect { perform }.not_to change(AuthorizationCode, :count)
        end

        it 'destroys the Request object' do
          expect { perform }.to change(Request, :count).from(1).to(0)
        end

        it 'renders the template with an error response' do
          perform
          expect(controller)
            .to have_received(:render)
                  .with(
                    'error',
                    locals: { error: "Unknown user 'doesntmatter'" },
                    status: :internal_server_error
                  )
        end
      end

      context 'when there is a matching user' do
        let(:user_sub) { create(:user).sub }

        before do
          allow(Rails.logger).to receive(:info)
          allow(Rails.logger).to receive(:error)
          allow(controller).to receive(:redirect_to)
        end

        it 'logs the user' do
          perform
          expect(Rails.logger).to have_received(:info).with("User '#{user_sub}'")
        end

        it 'logs the error' do
          perform
          expect(Rails.logger).to have_received(:error).with("Unsupported response type 'foo'")
        end

        it "doesn't create an authorization code" do
          expect { perform }.not_to change(AuthorizationCode, :count)
        end

        it 'destroys the Request object' do
          expect { perform }.to change(Request, :count).from(1).to(0)
        end

        it 'redirects with an error' do
          perform
          expect(controller)
            .to have_received(:redirect_to)
                  .with(
                    "#{request.redirect_uri}&error=unsupported_response_type",
                    status: :found,
                    allow_other_host: true
                  )
        end
      end
    end

    context 'when disallowed scopes are present' do
      let(:scope) { %w[movies animals colors] }

      let(:body_params) do
        {
          reqid: request.reqid,
          user: 'doesntmatter',
          response_type: 'code',
          scope_movies: '1',
          scope_foods: '0',
          scope_colors: '1',
          scope_animals: '1',
          approve: true
        }
      end

      before do
        allow(Rails.logger).to receive(:error)
        allow(controller).to receive(:redirect_to)
      end

      it 'logs the error' do
        perform
        expect(Rails.logger)
          .to have_received(:error)
                .with('Invalid scope(s) colors,animals')
      end

      it 'redirects with the correct query string' do
        perform
        expect(controller)
          .to have_received(:redirect_to)
                .with(
                  'https://example.com/callback?foo=bar&error=invalid_scope',
                  status: :found,
                  allow_other_host: true
                )
      end

      it "doesn't create an AuthorizationCode" do
        expect { perform }.not_to change(AuthorizationCode, :count)
      end

      it 'destroys the request object' do
        expect { perform }.to change(Request, :count).from(1).to(0)
      end
    end
  end

  context 'when the user denies the authorization request' do
    let!(:request) { create(:request, redirect_uri: 'https://example.com/callback?foo=bar') }

    let(:user) { 'doesntmatter' }

    let(:body_params) do
      {
        reqid: request.reqid,
        user:,
        scope_foods: '1',
        scope_movies: '1',
        scope_music: '0',
        deny: true
      }
    end

    before do
      allow(Rails.logger).to receive(:error)
      allow(controller).to receive(:redirect_to)
    end

    it 'logs the error' do
      perform
      expect(Rails.logger)
        .to have_received(:error)
              .with("User denied access for client '#{request.client_id}'")
    end

    it 'redirects correctly' do
      perform
      expect(controller)
        .to have_received(:redirect_to)
              .with('https://example.com/callback?foo=bar&error=access_denied', status: :found, allow_other_host: true)
    end

    it 'destroys the request object' do
      expect { perform }.to change(Request, :count).from(1).to(0)
    end
  end
end