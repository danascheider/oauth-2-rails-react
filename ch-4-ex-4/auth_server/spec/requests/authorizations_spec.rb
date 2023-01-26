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
          let(:scope) { %w[movies foods] }
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
end
