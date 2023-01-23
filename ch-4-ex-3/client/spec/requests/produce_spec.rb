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
              veggies: %w[carrot broccoli],
              meats: []
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
        expect(Rails.logger)
          .to have_received(:info)
                .with("Requesting produce from API with access token '#{access_token.access_token}'")
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
            'produce' => {
              'fruit' => %w[apple pear tomato],
              'meats' => [],
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
      let!(:access_token) { create(:access_token, refresh_token: 'foobar') }

      let!(:resource_api_call) do
        stub_request(:get, configatron.oauth.protected_resource.uri)
          .to_return(status: 401)
      end

      before do
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:error)
      end

      context 'when the token is successfully refreshed' do
        let!(:successful_resource_api_call) do
          stub_request(:get, configatron.oauth.protected_resource.uri)
            .to_return(
              {
                status: 401
              },
              {
                body: {
                  fruit: %w[apple banana kiwi],
                  veggies: %w[lettuce onion potato],
                  meats: []
                }.to_json,
                status: 200
              }
            )
        end

        before do
          stub_request(:post, configatron.oauth.auth_server.token_endpoint)
            .with(body: { grant_type: 'refresh_token', refresh_token: 'foobar' })
            .to_return(
              body: {
                access_token: 'raboof',
                refresh_token: 'foobar',
                token_type: 'Bearer',
                user: 'ABC-123',
                scope: 'fruit veggies',
              }.to_json,
              status: 200
            )
        end

        it 'logs info twice' do
          fetch
          expect(Rails.logger)
            .to have_received(:info)
                  .twice
                  .with(/Requesting produce from API with access token /)
        end

        it 'contacts the produce API twice' do
          fetch
          expect(resource_api_call).to have_been_made.twice
        end

        it 'logs the refresh attempt' do
          fetch
          expect(Rails.logger)
            .to have_received(:info)
                  .with('401 response from protected resource server, attempting to refresh token')
        end

        it 'refreshes the access token' do
          fetch
          expect(AccessToken.last.access_token).to eq 'raboof'
        end

        it 'deletes the old access token' do
          fetch
          expect { access_token.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it 'returns a 200 response' do
          fetch
          expect(response).to be_successful
        end

        it 'returns the produce corresponding to the scope' do
          fetch
          body = JSON.parse(response.body, symbolize_names: true)
          expect(body)
            .to eq({
              produce: {
                fruit: %w[apple banana kiwi],
                veggies: %w[lettuce onion potato],
                meats: []
              },
              scope: 'fruit veggies'
            })
        end
      end

      context "when the token can't be refreshed" do
        before do
          stub_request(:post, configatron.oauth.auth_server.token_endpoint)
            .with(body: { grant_type: 'refresh_token', refresh_token: 'foobar' })
            .to_return(status: 401)
        end

        it 'logs info' do
          fetch
          expect(Rails.logger)
            .to have_received(:info)
                  .once
                  .with(/Requesting produce from API with access token /)
        end

        it 'contacts the produce API' do
          fetch
          expect(resource_api_call).to have_been_made
        end

        it 'logs the refresh attempt' do
          fetch
          expect(Rails.logger)
            .to have_received(:info)
                  .with('401 response from protected resource server, attempting to refresh token')
        end

        it 'returns a 401 response' do
          fetch
          expect(response).to be_unauthorized
        end

        it 'logs the error' do
          fetch
          expect(Rails.logger)
            .to have_received(:error)
                  .with("Unable to refresh access token with refresh token 'foobar'")
        end

        it 'returns the error in the response body' do
          fetch
          expect(JSON.parse(response.body)).to eq({ 'error' => 'Unauthorized. Failed to refresh access token.' })
        end

        it 'destroys the access token' do
          expect { fetch }.to change(AccessToken, :count).from(1).to(0)
        end
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
