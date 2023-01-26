# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthorizationsController::AuthorizeService do
  subject(:perform) { described_class.new(controller, query_params:).perform }

  let(:controller) { instance_double(AuthorizationsController) }
  let(:query_params) do
    {
      client_id:,
      redirect_uri:,
      scope:,
      state: SecureRandom.hex(8),
      response_type: 'code'
    }
  end

  context 'when a client can be identified' do
    let!(:client) { create(:client) }
    let(:client_id) { client.client_id }
    let(:scope) { client.scope.join(' ') }
    let(:redirect_uri) { client.redirect_uris.first }

    context 'when the redirect URI is invalid' do
      let(:redirect_uri) { 'https://example.net/oauth/callback' }

      before do
        allow(Rails.logger).to receive(:error)
        allow(controller).to receive(:render)
      end

      it 'logs the error' do
        perform
        expect(Rails.logger)
          .to have_received(:error)
                .with("Mismatched redirect URI, expected https://example.com/callback, got https://example.net/oauth/callback")
      end

      it 'renders the error template' do
        perform
        expect(controller)
          .to have_received(:render)
                .with('error', locals: { error: 'Invalid redirect URI' })
      end

      it "doesn't create a Request object" do
        expect { perform }.not_to change(Request, :count)
      end
    end

    context 'when all requested scopes are permitted' do
      context 'when all client scopes are requested' do
        before do
          allow(controller).to receive(:render)
        end

        it 'creates a request object' do
          expect { perform }.to change(Request, :count).from(0).to(1)
        end

        it 'sets the scope on the request object' do
          perform
          expect(Request.last.scope).to eq client.scope
        end

        it 'renders the template' do
          perform
          expect(controller)
            .to have_received(:render)
                  .with('authorize', locals: { client:, req: Request.last })
        end
      end

      context 'when a subset of client scopes are requested' do
        let(:scope) { 'foods' }

        before do
          allow(controller).to receive(:render)
        end

        it 'sets the scope on the Request object to the limited scope' do
          perform
          expect(Request.last.scope).to eq %w[foods]
        end
      end
    end

    context 'when requested scopes are not allowed' do
      let(:scope) { 'colors movies' }
      let(:expected_redirect_uri) { "#{redirect_uri}?error=invalid_scope" }

      before do
        allow(Rails.logger).to receive(:error)
        allow(controller).to receive(:redirect_to)
      end

      it 'logs the error' do
        perform
        expect(Rails.logger)
          .to have_received(:error)
                .with('Invalid scope(s): colors')
      end

      it 'redirects' do
        perform
        expect(controller)
          .to have_received(:redirect_to)
                .with(expected_redirect_uri, status: :found, allow_other_host: true)
      end

      it "doesn't create a Request object" do
        expect { perform }.not_to change(Request, :count)
      end
    end
  end

  context "when the client can't be identified" do
    let(:client_id) { 'foobar' }
    let(:redirect_uri) { 'https://example.com/callback' }
    let(:scope) { %w[movies foods music] }

    before do
      allow(Rails.logger).to receive(:error)
      allow(controller).to receive(:render)
    end

    it 'logs the error' do
      perform
      expect(Rails.logger).to have_received(:error).with("Unknown client 'foobar'")
    end

    it 'renders the template with an error message' do
      perform
      expect(controller)
        .to have_received(:render)
              .with('error', locals: { error: 'Unknown client' })
    end

    it "doesn't create a Request object" do
      expect { perform }.not_to change(Request, :count)
    end
  end
end