# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthorizationsController::AuthorizeService do
  subject(:perform) { described_class.new(controller, query_params:).perform }

  let(:controller) { instance_double(AuthorizationsController) }
  let(:state) { SecureRandom.hex(8) }

  let(:query_params) do
    {
      client_id:,
      redirect_uri:,
      scope:,
      state:,
      response_type: 'code'
    }
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