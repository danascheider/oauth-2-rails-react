# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ProduceController', type: :request do
  describe 'GET index' do
    subject(:index) { get produce_index_path, headers: }

    let(:scope) { %w[fruit veggies meats] }
    let(:expires_at) { Time.now + 1.minute }

    context 'when there is a matching access token' do
      let(:token) { SecureRandom.hex(32) }
      let(:headers) do
        {
          'Authorization' => "Bearer #{token}",
          'Content-Type' => 'application/x-www-form-urlencoded'
        }
      end

      before do
        create(:access_token, token:, expires_at:, scope:)
        allow(Rails.logger).to receive(:info)
      end

      it 'logs success' do
        index
        expect(Rails.logger).to have_received(:info).with("We found a matching access token: '#{token}'")
      end

      context 'when the access token is valid' do
        context 'when the access token includes all scopes' do
          let(:expected_body) do
            {
              fruit: %w[apple banana kiwi],
              veggies: %w[lettuce onion potato],
              meats: ['bacon', 'steak', 'chicken breast']
            }
          end

          before do
            allow(Rails.logger).to receive(:info)
          end

          it 'logs the response' do
            index
            expect(Rails.logger).to have_received(:info).with("Sending produce: #{expected_body}")
          end

          it 'returns the expected response' do
            index
            expect(JSON.parse(response.body, symbolize_names: true)).to eq expected_body
          end

          it 'returns a successful status' do
            index
            expect(response).to be_successful
          end
        end

        context "when the access token has limited scopes" do
          let(:scope) { %w[fruit] }

          let(:expected_body) do
            {
              fruit: %w[apple banana kiwi],
              veggies: [],
              meats: []
            }
          end

          before do
            allow(Rails.logger).to receive(:info)
          end

          it 'logs success' do
            index
            expect(Rails.logger).to have_received(:info).with("Sending produce: #{expected_body}")
          end

          it 'returns the correct response body' do
            index
            expect(JSON.parse(response.body, symbolize_names: true)).to eq expected_body
          end

          it 'returns a successful response' do
            index
            expect(response).to be_successful
          end
        end

        context 'when authenticating with query params' do
          subject(:index) { get "#{produce_index_path}?access_token=#{token}" }

          before do
            allow(Rails.logger).to receive(:info)
          end

          it 'logs success' do
            index
            expect(Rails.logger).to have_received(:info).with(/Sending produce\: /)
          end

          it 'returns a successful response' do
            index
            expect(response).to be_successful
          end
        end
      end

      context 'when the access token is expired' do
        let(:expires_at) { Time.now - 1.second }

        before do
          allow(Rails.logger).to receive(:error)
        end

        it 'logs the error' do
          index
          expect(Rails.logger).to have_received(:error).with "Access token '#{token}' is expired"
        end

        it 'returns status 401' do
          index
          expect(response).to be_unauthorized
        end
      end
    end

    context 'when there is no matching access token' do
      before do
        allow(Rails.logger).to receive(:error)
      end

      it 'logs the error' do
        index
        expect(Rails.logger).to have_received(:error).with('Missing access token')
      end

      it 'returns status 401' do
        index
        expect(response).to be_unauthorized
      end
    end
  end
end