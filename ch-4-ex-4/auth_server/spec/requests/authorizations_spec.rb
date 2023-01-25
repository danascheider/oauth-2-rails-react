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

      context 'when the redirect URI is invalid'

      context 'when all requested scopes are permitted'

      context 'when disallowed scopes are requested'

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
