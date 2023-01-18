require 'rails_helper'

RSpec.describe 'Produce', type: :request do
  describe 'GET /fetch' do
    subject(:fetch) { get produce_path }

    before do
      WebMock.enable!
    end

    context 'when there is a valid saved access token' do
      let!(:resource_api_call) do
        stub_request(:get, configatron.oauth.protected_resource.uri)
          .with(headers:)
          .to_return(
            body: {
              fruit: %w[apple pear tomato],
              veggies: %w[carrot broccoli]
            }.to_json,
            status: 200
          )
      end

      let(:headers) do
        {
          'Authorization' => "Bearer #{access_token.access_token}",
          'Content-Type' => 'application/x-www-form-urlencoded'
        }
      end

      let(:access_token) { create(:access_token) }

      before do
        allow(Rails.logger).to receive(:info)
      end

      it 'calls the produce API' do
        fetch
        expect(resource_api_call).to have_been_made
      end

      it 'logs success' do
        fetch
        expect(Rails.logger).to have_received(:info).with('Requesting produce from API')
      end

      it 'returns a 200 response' do
        fetch
        expect(response).to be_successful
      end

      it 'includes the scope in the response body' do
        fetch
        expect(JSON.parse(response.body))
          .to eq({
            'scope' => access_token.scope.join(' '),
            'data' => {
              'fruit' => %w[apple pear tomato],
              'veggies' => %w[carrot broccoli]
            }
          })
      end
    end

    context 'when there are no access tokens' do
      before do
        allow(Rails.logger).to receive(:error)
      end

      it "doesn't contact the produce API" do
        fetch
        expect(a_request(:post, configatron.oauth.protected_resource.uri)).not_to have_been_made
      end

      it 'logs the error' do
        fetch
        expect(Rails.logger)
          .to have_received(:error)
                .with('No access tokens in database')
      end

      it 'returns a 401 response' do
        fetch
        expect(response).to be_unauthorized
      end

      it 'returns an error message' do
        fetch
        expect(JSON.parse(response.body)).to eq({ 'error' => 'Missing access token' })
      end
    end

    context 'when the produce API returns a 401' do
      let!(:resource_api_call) do
        stub_request(:get, configatron.oauth.protected_resource.uri)
          .to_return(status: 401)
      end

      before do
        create(:access_token)
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:error)
      end

      it 'logs info' do
        fetch
        expect(Rails.logger).to have_received(:info).with('Requesting produce from API')
      end

      it 'contacts the produce API' do
        fetch
        expect(resource_api_call).to have_been_made
      end

      it 'logs the error' do
        fetch
        expect(Rails.logger)
          .to have_received(:error)
                .with('401 response from protected resource server')
      end

      it 'returns a 401 response' do
        fetch
        expect(response).to be_unauthorized
      end

      it 'returns an empty response body' do
        fetch
        expect(response.body).to be_blank
      end
    end

    context 'when there is an unexpected error from the API' do
      let(:headers) do
        {
          'Authorization' => "Bearer #{access_token.access_token}",
          'Content-Type' => 'application/x-www-form-urlencoded'
        }
      end

      let(:access_token) { create(:access_token) }

      context 'when a response body is returned' do
        let!(:resource_api_call) do
          stub_request(:get, configatron.oauth.protected_resource.uri)
            .with(headers:)
            .to_return(
              body: { error: 'Something went wrong' }.to_json,
              status: 500
            )
        end

        before do
          allow(Rails.logger).to receive(:error)
        end

        it 'logs the error' do
          fetch
          expect(Rails.logger).to have_received(:error).with('Error response 500 received from server: Something went wrong')
        end

        it 'returns the error to the client' do
          fetch
          expect(JSON.parse(response.body)).to eq({ 'error' => 'Something went wrong' })
        end

        it 'returns a 200 response' do
          fetch
          expect(response).to be_successful
        end
      end

      context 'when no response body is returned' do
        let!(:resource_api_call) do
          stub_request(:get, configatron.oauth.protected_resource.uri)
            .with(headers:)
            .to_return(status: 404)
        end

        before do
          allow(Rails.logger).to receive(:error)
        end

        it 'logs the error' do
          fetch
          expect(Rails.logger).to have_received(:error).with('Error response 404 received from server')
        end

        it 'returns a 200 response' do
          fetch
          expect(response).to be_successful
        end

        it 'returns an error message' do
          fetch
          expect(JSON.parse(response.body)).to eq({ 'error' => 'Error response 404 received from server' })
        end
      end
    end
  end
end
