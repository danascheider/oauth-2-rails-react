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
      context 'when the response_type is "code"' do
        context 'when all scopes are valid'

        context 'when disallowed scopes are present'
      end

      context 'when the response_type is "token"' do
        context 'when all scopes are valid' do
          context 'when a user has been selected' do
            context 'when the request object has a "state" value'

            context "when the request object doesn't have a 'state' value"
          end

          context 'when no user has been selected'
        end

        context 'when disallowed scopes are present'
      end

      context 'when there is a different response type' do
        let(:response_type) { 'foo' }

        let(:body_params) do
          {
            reqid: 'foobar',
            client_id: client.client_id,
            user: 'doesntmatter',
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
          client_id: client.client_id,
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