# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthorizationsController::TokenService do
  describe '#perform' do
    subject(:perform) { described_class.new(controller, client:, body_params:).perform }

    let(:controller) { instance_double(AuthorizationsController) }
    let(:client) { create(:client) }

    context 'when the grant type is "authorization_code"' do
      let(:body_params) do
        {
          grant_type: 'authorization_code',
          code:
        }
      end

      context 'when the params include a valid authorization code' do
        let!(:authorization_code) { create(:authorization_code, client:) }
        let(:code) { authorization_code.code }

        before do
          allow(Rails.logger).to receive(:info)
          allow(controller).to receive(:render)
        end

        it 'logs success' do
          perform
          expect(Rails.logger)
            .to have_received(:info)
                  .with("Issued tokens for code '#{authorization_code.code}'")
        end

        it 'creates an access token' do
          expect { perform }.to change(AccessToken, :count).from(0).to(1)
        end

        it 'creates a refresh token' do
          expect { perform }.to change(RefreshToken, :count).from(0).to(1)
        end

        it 'renders a response with the tokens' do
          perform
          expect(controller)
            .to have_received(:render)
                  .with(
                    json: {
                      access_token: AccessToken.last.token,
                      refresh_token: RefreshToken.last.token,
                      token_type: 'Bearer',
                      scope: authorization_code.scope.join(' '),
                      client_id: client.client_id,
                      user: authorization_code.user.sub
                    },
                    status: :ok
                  )
        end

        it 'designates the tokens for the correct user', :aggregate_failures do
          perform
          expect(AccessToken.last.user).to eq authorization_code.user
          expect(RefreshToken.last.user).to eq authorization_code.user
        end
      end

      context "when the code doesn't match the authenticated client" do
        let!(:authorization_code) { create(:authorization_code) }
        let(:code) { authorization_code.code }

        before do
          allow(Rails.logger).to receive(:error)
          allow(controller).to receive(:render)
        end

        it 'destroys the code' do
          expect { perform }.to change(AuthorizationCode, :count).from(1).to(0)
        end

        it 'logs the error' do
          perform
          expect(Rails.logger)
            .to have_received(:error)
                  .with("Client mismatch, expected '#{authorization_code.client_id}', got '#{client.client_id}'")
        end

        it 'renders a 400 response' do
          perform
          expect(controller)
            .to have_received(:render)
                  .with(json: { error: 'invalid_grant' }, status: :bad_request)
        end
      end

      context "when the code doesn't exist" do
        let(:code) { 'foo' }

        before do
          allow(Rails.logger).to receive(:error)
          allow(controller).to receive(:render)
        end

        it 'logs the error' do
          perform
          expect(Rails.logger).to have_received(:error).with("Unknown code 'foo'")
        end

        it 'renders a 400 response' do
          perform
          expect(controller)
            .to have_received(:render)
                  .with(json: { error: 'invalid_grant' }, status: :bad_request)
        end
      end

      context "when the params don't include an authorization code" do
        let(:code) { nil }

        before do
          allow(Rails.logger).to receive(:error)
          allow(controller).to receive(:render)
        end

        it 'logs the error' do
          perform
          expect(Rails.logger).to have_received(:error).with("Unknown code ''")
        end

        it 'renders a 400 response' do
          perform
          expect(controller)
            .to have_received(:render)
                  .with(json: { error: 'invalid_grant' }, status: :bad_request)
        end
      end
    end

    context 'with an unrecognised grant type' do
      let(:body_params) { { grant_type: 'foo' } }

      before do
        allow(Rails.logger).to receive(:error)
        allow(controller).to receive(:render)
      end

      it 'logs the error' do
        perform
        expect(Rails.logger).to have_received(:error).with("Unknown grant type 'foo'")
      end

      it 'renders a 400 response' do
        perform
        expect(controller)
          .to have_received(:render)
                .with(json: { error: 'unsupported_grant_type' }, status: :bad_request)
      end
    end

    context 'when the grant type is missing' do
      let(:body_params) { { code: 'foobar' } }

      before do
        allow(Rails.logger).to receive(:error)
        allow(controller).to receive(:render)
      end

      it 'logs the error' do
        perform
        expect(Rails.logger).to have_received(:error).with("Unknown grant type ''")
      end

      it 'renders a 400 response' do
        perform
        expect(controller)
          .to have_received(:render)
                .with(json: { error: 'unsupported_grant_type' }, status: :bad_request)
      end
    end
  end
end