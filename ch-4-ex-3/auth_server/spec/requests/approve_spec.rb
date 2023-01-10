# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AuthorizationsController#approve', type: :request do
  subject(:approve) { post approve_url, params: body_params }

  let!(:client) { create(:client) }

  context 'when there is a matching request' do
    let!(:req) do
      create(
        :request,
        client:,
        reqid: 'foobar',
        query: { 'state' => state, 'response_type' => response_type }
      )
    end

    let(:state) { nil }
    let(:response_type) { nil }

    context 'when authorization is approved' do
      context 'when disallowed scopes are present' do
        let(:body_params) do
          {
            reqid: 'foobar',
            user: 'doesntmatter',
            scope_veggies: '1',
            scope_fruit: '0',
            scope_meat: '1',
            approve: true
          }
        end

        it 'redirects with an error' do
          approve
          expect(response).to redirect_to "#{req.redirect_uri}?error=invalid_scope"
        end
      end

      context 'when the response_type is "code"' do
        let(:response_type) { 'code' }

        context 'when a user has been selected' do
          let!(:user) { create(:user) }

          let(:body_params) do
            {
              reqid: 'foobar',
              user: user.sub,
              scope_veggies: '1',
              scope_fruit: '0',
              approve: true
            }
          end

          before do
            allow(SecureRandom).to receive(:hex).with(8).and_return('foobar')
          end

          context 'when a state value is present' do
            let(:state) { 'raboof' }

            it 'redirects successfully with the state value' do
              approve
              expect(response)
                .to redirect_to("#{req.redirect_uri}?code=foobar&state=raboof")
            end
          end

          context 'when no state value is present' do
            it 'redirects successfully with no state param' do
              approve
              expect(response)
                .to redirect_to("#{req.redirect_uri}?code=foobar")
            end
          end
        end

        context 'when no user has been selected' do
          let(:body_params) do
            {
              reqid: 'foobar',
              user: 'doesntexist',
              scope_veggies: '1',
              scope_fruit: '0',
              approve: true
            }
          end

          it 'returns a 500 error' do
            approve
            expect(response.status).to eq 500
          end
        end
      end

      context 'when the response_type is "token"' do
        let(:response_type) { 'token' }

        context 'when a user has been selected' do
          let!(:user) { create(:user) }

          let(:body_params) do
            {
              reqid: 'foobar',
              user: user.sub,
              scope_veggies: '1',
              scope_fruit: '0',
              approve: true
            }
          end

          context 'when the request object has a "state" value' do
            let(:state) { 'raboof' }

            it 'redirects with the state value' do
              approve
              expect(response)
                .to redirect_to("https://example.com/callback?access_token=#{AccessToken.last.token}&token_type=Bearer&scope=fruit+veggies&client_id=#{client.client_id}&user=#{user.sub}&refresh_token=#{RefreshToken.last.token}&state=raboof")
            end
          end

          context "when the request object doesn't have a 'state' value"
        end

        context 'when no user has been selected' do
          let(:body_params) do
            {
              reqid: 'foobar',
              user: 'baz',
              scope_veggies: '1',
              scope_fruit: '0',
              approve: true
            }
          end

          it 'returns a 500 error' do
            approve
            expect(response.status).to eq 500
          end
        end
      end

      context 'when there is a different response type' do
        let!(:user) { create(:user) }
        let(:response_type) { 'foo' }

        let(:body_params) do
          {
            reqid: 'foobar',
            user: user.sub,
            scope_fruit: '1',
            scope_veggies: '1',
            approve: true
          }
        end

        it 'redirects with an error' do
          approve
          expect(response).to redirect_to "#{req.redirect_uri}?error=unsupported_response_type"
        end
      end
    end

    context 'when authorization is denied' do
      let(:body_params) do
        {
          reqid: 'foobar',
          user: 'doesntmatter',
          scope_fruit: '1',
          scope_veggies: '1'
        }
      end

      it 'redirects' do
        approve
        expect(response).to redirect_to("#{req.redirect_uri}?error=access_denied")
      end
    end
  end

  context 'when there is no matching request' do
    let(:body_params) do
      {
        reqid: 'nonexistent',
        approve: true,
        user: 'doesntmatter',
        scope_fruit: '0',
        scope_veggies: '1'
      }
    end

    it 'is successful' do
      approve
      expect(response).to be_successful
    end
  end
end