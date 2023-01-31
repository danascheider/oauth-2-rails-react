# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TokenHelper, type: :helper do
  describe '#generate_token_response' do
    subject(:generate) do
      helper.generate_token_response(client:, user:, scope:, generate_refresh_token:)
    end

    let(:generate_refresh_token) { false }
    let(:client) { create(:client) }
    let(:user) { create(:user) }
    let(:scope) { client.scope }

    context 'when the client is missing' do
      let(:client) { nil }
      let(:scope) { [] }

      it 'raises an InvalidClientError' do
        expect { generate }.to raise_error(described_class::InvalidClientError)
      end
    end

    context 'when the user is invalid' do
      let(:user) { 'not a user object' }

      it 'raises an InvalidUserError' do
        expect { generate }.to raise_error(described_class::InvalidUserError)
      end
    end

    context 'when the scope is missing' do
      let(:scope) { nil }

      it 'raises an InvalidScopeError' do
        expect { generate }.to raise_error(described_class::InvalidScopeError)
      end
    end

    context 'when the scope is not an array' do
      let(:scope) { 'movies foods music' }

      it 'raises an InvalidScopeError' do
        expect { generate }.to raise_error(described_class::InvalidScopeError)
      end
    end

    context 'when the scope array contains non-string values' do
      let(:scope) { ['movies', 'foods', 14] }

      it 'raises an InvalidScopeError' do
        expect { generate }.to raise_error(described_class::InvalidScopeError)
      end
    end

    context 'when all required values are present' do
      before do
        allow(Rails.logger).to receive(:info)
      end

      context 'when generate_refresh_token is set to false' do
        it 'generates an access token' do
          expect { generate }.to change(AccessToken, :count).from(0).to(1)
        end

        it 'sets the expected attributes', :aggregate_failures do
          generate
          expect(AccessToken.last.client).to eq client
          expect(AccessToken.last.user).to eq user
          expect(AccessToken.last.scope).to eq scope
        end

        it 'logs the access token' do
          generate
          expect(Rails.logger)
            .to have_received(:info)
                  .with("Issuing access token '#{AccessToken.last.token}' for client '#{client.client_id}' and user '#{user.sub}' with scope '#{scope.join(' ')}'")
        end

        it 'returns the response' do
          expect(generate)
            .to eq({
                    access_token: AccessToken.last.token,
                    token_type: 'Bearer',
                    scope: scope.join(' '),
                    client_id: client.client_id,
                    user: user.sub
                  })
        end

        context 'when there is a refresh token for that user and client' do
          let!(:refresh_token) { create(:refresh_token, client:, user:, scope: refresh_scope) }

          context 'when the refresh token has the requested scope' do
            let(:refresh_scope) { scope }

            context 'when a user is present' do
              it 'logs the user' do
                generate
                expect(Rails.logger)
                  .to have_received(:info)
                        .with("Found matching refresh token '#{refresh_token.token}' for client '#{client.client_id}' and user '#{user.sub}'")
              end

              it 'includes the refresh token in the output' do
                expect(generate)
                .to eq({
                        access_token: AccessToken.last.token,
                        refresh_token: refresh_token.token,
                        token_type: 'Bearer',
                        scope: scope.join(' '),
                        client_id: client.client_id,
                        user: user.sub
                      })
              end
            end

            context 'when no user is present' do
              let(:user) { nil }

              it 'logs without the user' do
                generate
                expect(Rails.logger)
                  .to have_received(:info)
                        .with("Found matching refresh token '#{refresh_token.token}' for client '#{client.client_id}'")
              end

              it 'returns the response without the user' do
                expect(generate)
                  .to eq({
                          access_token: AccessToken.last.token,
                          refresh_token: refresh_token.token,
                          token_type: 'Bearer',
                          scope: scope.join(' '),
                          client_id: client.client_id
                        })
              end
            end
          end

          context 'when the refresh token has a different scope' do
            let(:refresh_scope) { %w[foods] }

            it 'destroys the existing refresh token without issuing a new one' do
              expect { generate }.to change(RefreshToken, :count).from(1).to(0)
            end

            it "doesn't include a refresh token in the output" do
              expect(generate).not_to have_key(:refresh_token)
            end
          end
        end

        context 'when there is no refresh token for that user and client' do
          it "doesn't create a refresh token" do
            expect { generate }.not_to change(RefreshToken, :count)
          end

          it "doesn't include a refresh_token key in the output" do
            expect(generate).not_to have_key(:refresh_token)
          end
        end
      end

      context 'when generate_refresh_token is set to true' do
        let(:generate_refresh_token) { true }

        context 'when there is an existing refresh token for that client and user' do
          let!(:refresh_token) { create(:refresh_token, client:, user:, scope: refresh_scope) }

          context 'when the scope matches the scope passed in' do
            let(:refresh_scope) { scope }

            it 'uses the existing refresh token' do
              generate
              expect(RefreshToken.last).to eq refresh_token
            end

            it 'logs the refresh token' do
              generate
              expect(Rails.logger)
                .to have_received(:info)
                      .with("Found matching refresh token '#{refresh_token.token}' for client '#{client.client_id}' and user '#{user.sub}'")
            end

            it 'includes the refresh token in the output' do
              expect(generate).to include(refresh_token: refresh_token.token)
            end
          end

          context 'when the scope does not match the scope passed in' do
            let(:refresh_scope) { %w[foods] }

            it 'destroys the refresh token' do
              generate
              expect { refresh_token.reload }.to raise_error(ActiveRecord::RecordNotFound)
            end

            it 'creates a new refresh token' do
              generate
              expect(RefreshToken.find_by(client:, user:)).to be_present
            end

            it 'logs the new refresh token' do
              generate
              expect(Rails.logger)
                .to have_received(:info)
                      .with("Issuing refresh token '#{RefreshToken.last.token}' for client '#{client.client_id}' and user '#{user.sub}'")
            end

            it 'includes the new refresh token in the output' do
              expect(generate).to include(refresh_token: RefreshToken.last.token)
            end
          end
        end

        context 'when there is no existing refresh token for that client and user' do
          it 'creates a refresh token' do
            expect { generate }.to change(RefreshToken, :count).from(0).to(1)
          end

          it 'logs the refresh token' do
            generate
            expect(Rails.logger)
              .to have_received(:info)
                    .with("Issuing refresh token '#{RefreshToken.last.token}' for client '#{client.client_id}' and user '#{user.sub}'")
          end

          it 'returns the refresh token in the output' do
            expect(generate).to include(refresh_token: RefreshToken.last.token)
          end
        end
      end
    end

    context 'when there is no user' do
      let!(:refresh_token) { create(:refresh_token, user: nil, client:, scope:) }
      let(:user) { nil }

      before do
        allow(Rails.logger).to receive(:info)
      end

      it 'generates an access token' do
        expect { generate }.to change(AccessToken, :count).from(0).to(1)
      end

      it 'logs the access token' do
        generate
        expect(Rails.logger)
          .to have_received(:info)
                .with("Issuing access token '#{AccessToken.last.token}' for client '#{client.client_id}' with scope '#{scope.join(' ')}'")
      end

      it 'logs the refresh token' do
        generate
        expect(Rails.logger)
          .to have_received(:info)
                .with("Found matching refresh token '#{refresh_token.token}' for client '#{client.client_id}'")
      end

      it 'generates the expected output' do
        expect(generate).to eq({
                                access_token: AccessToken.last.token,
                                refresh_token: refresh_token.token,
                                token_type: 'Bearer',
                                scope: scope.join(' '),
                                client_id: client.client_id
                              })
      end
    end

    context "when the scope is more limited than the client's scope" do
      let(:scope) { [client.scope.first] }
      let(:generate_refresh_token) { true }

      it 'issues the access token with the limited scope' do
        generate
        expect(AccessToken.last.scope).to eq scope
      end

      it 'issues the refresh token with the limited scope' do
        generate
        expect(RefreshToken.last.scope).to eq scope
      end

      it 'includes the limited scope in the output' do
        expect(generate).to include(scope: scope.first)
      end
    end
  end
end