# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TokenHelper, type: :helper do
  describe '#generate_token_response' do
    subject(:generate) do
      helper.generate_token_response(client:, user:, scope:, generate_refresh_token:)
    end

    let(:generate_refresh_token) { false }

    context 'when the client is missing' do
      let(:client) { nil }
      let(:user) { create(:user) }
      let(:scope) { [] }

      it 'raises an InvalidClientError' do
        expect { generate }.to raise_error(described_class::InvalidClientError)
      end
    end

    context 'when the user is missing' do
      let(:client) { create(:client) }
      let(:user) { nil }
      let(:scope) { [] }

      it 'raises an InvalidUserError' do
        expect { generate }.to raise_error(described_class::InvalidUserError)
      end
    end

    context 'when the scope is missing' do
      let(:client) { create(:client) }
      let(:user) { create(:user) }
      let(:scope) { nil }

      it 'raises an InvalidScopeError' do
        expect { generate }.to raise_error(described_class::InvalidScopeError)
      end
    end

    context 'when all required values are present' do
      let(:client) { create(:client, scope: %w[fruit veggies meats]) }
      let(:user) { create(:user) }
      let(:scope) { %w[fruit veggies meats] }

      before do
        allow(Rails.logger).to receive(:info)
        allow(SecureRandom).to receive(:hex).with(16).and_call_original
        allow(SecureRandom).to receive(:hex).with(32).and_return('foobar')
      end

      it 'creates an access token' do
        expect { generate }.to change(AccessToken, :count).from(0).to(1)
      end

      it 'sets the expected attributes', :aggregate_failures do
        generate
        token = AccessToken.last
        expect(token.user).to eq user
        expect(token.client).to eq client
        expect(token.scope).to eq scope
      end

      it 'logs the access token' do
        generate
        expect(Rails.logger)
          .to have_received(:info)
                .with("Issuing access token 'foobar' for client '#{client.client_id}' and user '#{user.sub}' with scope 'fruit veggies meats'")
      end

      context 'when generate_refresh_token is set to true' do
        let(:generate_refresh_token) { true }

        context 'when there is an existing refresh token for that client and user' do
          let!(:refresh_token) { create(:refresh_token, client:, user:, token: 'raboof', scope: refresh_token_scope) }

          context 'when the scope matches the requested scope' do
            let(:refresh_token_scope) { scope }

            it 'uses the existing refresh token' do
              expect(generate).to eq({
                                       access_token: 'foobar',
                                       refresh_token: 'raboof',
                                       token_type: 'Bearer',
                                       scope: 'fruit veggies meats',
                                       client_id: client.client_id,
                                       user: user.sub
                                     })
            end

            it "doesn't create or destroy refresh tokens" do
              expect { generate }.not_to change(RefreshToken, :count)
            end
          end

          context "when the scope doesn't match the requested scope" do
            let(:refresh_token_scope) { %w[meats] }

            it 'destroys the existing refresh token' do
              generate
              expect(RefreshToken.find_by(token: 'raboof')).to be_nil
            end

            it 'includes a new refresh token in the output' do
              expect(generate).to eq({
                                       access_token: 'foobar',
                                       refresh_token: RefreshToken.last.token,
                                       token_type: 'Bearer',
                                       scope: 'fruit veggies meats',
                                       client_id: client.client_id,
                                       user: user.sub
                                     })
            end
          end
        end
      end

      context 'when generate_refresh_token is set to false' do
        context 'when there is an existing refresh token for that client and user' do
          let!(:refresh_token) do
            create(
              :refresh_token,
              client:,
              user:,
              scope: refresh_token_scope
            )
          end

          context 'when the scope matches the requested scope' do
            let(:refresh_token_scope) { scope }

            it 'includes the refresh token in the output' do
              expect(generate).to eq({
                access_token: AccessToken.last.token,
                token_type: 'Bearer',
                refresh_token: refresh_token.token,
                scope: scope.join(' '),
                client_id: client.client_id,
                user: user.sub
              })
            end
          end

          context 'when the scope does not match the requested scope' do
            let(:refresh_token_scope) { %w[meats] }

            it 'destroys the refresh token' do
              expect { generate }.to change(RefreshToken, :count).from(1).to(0)
            end

            it "doesn't include the refresh token in the output" do
              expect(generate).not_to have_key(:refresh_token)
            end
          end
        end

        context 'when there is no existing refresh token for that client and user' do
          it "doesn't include a refresh token" do
            expect(generate).to eq({
              access_token: 'foobar',
              token_type: 'Bearer',
              scope: 'fruit veggies meats',
              client_id: client.client_id,
              user: user.sub
            })
          end
        end
      end
    end
  end
end
