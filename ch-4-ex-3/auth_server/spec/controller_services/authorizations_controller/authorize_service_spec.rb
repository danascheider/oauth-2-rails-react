# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthorizationsController::AuthorizeService do
  describe '#perform' do
    subject(:perform) { described_class.new(controller, query_params:).perform }

    let(:controller) { instance_double(AuthorizationsController) }

    context 'when the client exists and the redirect URI is valid'

    context "when the client doesn't exist" do
      let(:query_params) do
        {
          client_id: 'oauth-client-1',
          redirect_uri: 'https://example.com/callback',
          scope: 'fruit veggies'
        }
      end

      before do
        allow(Rails.logger).to receive(:error)
        allow(controller).to receive(:render)
      end

      it 'logs an error' do
        perform
        expect(Rails.logger).to have_received(:error).with("Unknown client 'oauth-client-1'")
      end

      it 'renders the error page' do
        perform
        expect(controller).to have_received(:render).with('error', locals: { error: 'Unknown client' })
      end
    end

    context 'when there is an invalid redirect URI' do
      let!(:client) { create(:client, redirect_uris: ['https://example.com/callback']) }
      let(:query_params) do
        {
          client_id: client.client_id,
          redirect_uri: 'https://example.net/callback',
          scope: 'fruit veggies'
        }
      end

      before do
        allow(Rails.logger).to receive(:error)
        allow(controller).to receive(:render)
      end

      it 'logs an error' do
        perform
        expect(Rails.logger)
          .to have_received(:error)
                .with("Mismatched redirect URI, expected https://example.com/callback, got 'https://example.net/callback'")
      end

      it 'renders the error page' do
        perform
        expect(controller)
          .to have_received(:render)
                .with('error', locals: { error: 'Invalid redirect URI' })
      end
    end
    # Context: When the client exists and the redirect URI is valid
    #   Context: With only valid scopes
    #     - Creates a request object
    #     - Renders the authorization form
    #   Context: When there are disallowed scopes
    #     - Redirects with an 'invalid_scope' error
    #     - Doesn't create a Request object
    # Context: When client doesn't exist
    #   - Logs error
    #   - Returns 'unknown_client' error
    # Context: When there is an invalid redirect URI
    #   - Logs error
    #   - Renders 'invalid redirect URI' error
  end
end