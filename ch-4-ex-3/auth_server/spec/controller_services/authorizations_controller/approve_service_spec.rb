# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthorizationsController::ApproveService do
  describe '#perform' do
    subject(:perform) { described_class.new(controller, body_params:).perform }

    let!(:client) { create(:client) }
    let(:controller) { instance_double(AuthorizationsController) }

    context 'when there is a matching request' do
      let!(:req) do
        create(
          :request,
          client:,
          query: { 'state' => state, 'response_type' => response_type },
          reqid: 'foobar'
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
              scope_fruit: '1',
              scope_veggies: '0',
              scope_dairy: '1',
              approve: true
            }
          end

          before do
            allow(Rails.logger).to receive(:error)
            allow(controller).to receive(:redirect_to)
          end

          it 'logs the error' do
            perform
            expect(Rails.logger).to have_received(:error).with('Invalid scope(s) dairy')
          end

          it 'redirects with an error' do
            perform
            expect(controller)
              .to have_received(:redirect_to)
                    .with(
                      "#{req.redirect_uri}?error=invalid_scope",
                      status: :found,
                      allow_other_host: true
                    )
          end

          it 'destroys the request object' do
            expect { perform }.to change(Request, :count).from(1).to(0)
          end
        end

        context 'when the response_type is "code"' do
          let(:response_type) { 'code' }

          context 'when a user has been selected' do
            let!(:user) { create(:user) }
            let(:code) { instance_double(AuthorizationCode, code: 'foobar') }

            let(:body_params) do
              {
                reqid: 'foobar',
                user: user.sub,
                scope_fruit: '1',
                scope_veggies: '0',
                scope_meats: '1',
                approve: true
              }
            end

            before do
              allow(controller).to receive(:redirect_to)
              allow(SecureRandom).to receive(:hex).with(8).and_return('foobar')
            end

            context 'when the request object has a state value' do
              let(:state) { SecureRandom.hex(8) }

              it 'creates an authorization code' do
                expect { perform }.to change(AuthorizationCode, :count).from(0).to(1)
              end

              it 'redirects successfully' do
                perform
                expect(controller)
                  .to have_received(:redirect_to)
                        .with(
                          "#{req.redirect_uri}?code=foobar&state=#{state}",
                          status: :found,
                          allow_other_host: true
                        )
              end

              it 'destroys the request object' do
                expect { perform }.to change(Request, :count).from(1).to(0)
              end
            end

            context 'when the request object has no state value' do
              it 'creates an authorization code' do
                expect { perform }.to change(AuthorizationCode, :count).from(0).to(1)
              end

              it 'redirects successfully without including state' do
                perform
                expect(controller)
                  .to have_received(:redirect_to)
                        .with(
                          "#{req.redirect_uri}?code=foobar",
                          status: :found,
                          allow_other_host: true
                        )
              end

              it 'destroys the request object' do
                expect { perform }.to change(Request, :count).from(1).to(0)
              end
            end
          end

          context 'when no user has been selected' do
            let(:response_type) { 'code' }

            let(:body_params) do
              {
                reqid: 'foobar',
                user: 'baz',
                scope_fruit: '1',
                scope_veggies: '0',
                scope_meats: '1',
                approve: true
              }
            end

            before do
              allow(Rails.logger).to receive(:error)
              allow(controller).to receive(:render)
            end

            it 'logs the error' do
              perform
              expect(Rails.logger).to have_received(:error).with("Unknown user 'baz'")
            end

            it 'renders the error page' do
              perform
              expect(controller)
                .to have_received(:render)
                      .with('error', locals: { error: "Unknown user 'baz'" }, status: :internal_server_error)
            end

            it 'destroys the request object' do
              expect { perform }.to change(Request, :count).from(1).to(0)
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
                scope_fruit: '1',
                scope_veggies: '0',
                scope_meats: '1',
                approve: true
              }
            end

            before do
              allow(controller).to receive(:redirect_to)
            end

            context 'when the request object has a "state" value' do
              let(:state) { SecureRandom.hex(8) }

              it 'includes the state in the redirect params' do
                perform
                expect(controller)
                  .to have_received(:redirect_to)
                        .with(
                          "https://example.com/callback?access_token=#{AccessToken.last.token}&token_type=Bearer&scope=fruit+veggies&client_id=#{client.client_id}&user=#{user.sub}&refresh_token=#{RefreshToken.last.token}&state=#{state}",
                          status: :found,
                          allow_other_host: true
                        )
              end

              it 'destroys the request object' do
                expect { perform }.to change(Request, :count).from(1).to(0)
              end
            end

            context "when the request object doesn't have a 'state' value" do
              it "doesn't include a state param" do
                perform
                expect(controller)
                  .to have_received(:redirect_to)
                        .with(
                          "https://example.com/callback?access_token=#{AccessToken.last.token}&token_type=Bearer&scope=fruit+veggies&client_id=#{client.client_id}&user=#{user.sub}&refresh_token=#{RefreshToken.last.token}",
                          status: :found,
                          allow_other_host: true
                        )
              end

              it 'destroys the request object' do
                expect { perform }.to change(Request, :count).from(1).to(0)
              end
            end
          end

          context 'when no user has been selected' do
            let(:body_params) do
              {
                reqid: 'foobar',
                user: 'baz',
                scope_fruit: '1',
                scope_veggies: '0',
                scope_meats: '1',
                approve: true
              }
            end

            before do
              allow(controller).to receive(:render)
            end

            it 'renders the error page' do
              perform
              expect(controller)
                .to have_received(:render)
                      .with(
                        'error',
                        locals: { error: "Unknown user 'baz'" },
                        status: :internal_server_error
                      )
            end

            it 'destroys the request object' do
              expect { perform }.to change(Request, :count).from(1).to(0)
            end
          end
        end

        context 'when there is a different response type' do
          let(:response_type) { 'foo' }

          context 'when a user has been selected' do
            let!(:user) { create(:user) }

            let(:body_params) do
              {
                client_id: client.client_id,
                reqid: 'foobar',
                user: user.sub,
                scope_fruit: '1',
                scope_veggies: '0',
                approve: true
              }
            end

            before do
              allow(Rails.logger).to receive(:error)
              allow(controller).to receive(:redirect_to)
            end

            it 'logs the error' do
              perform
              expect(Rails.logger)
                .to have_received(:error)
                      .with("Unsupported response type 'foo'")
            end

            it 'redirects with an error' do
              perform
              expect(controller)
                .to have_received(:redirect_to)
                      .with(
                        "#{req.redirect_uri}?error=unsupported_response_type",
                        status: :found,
                        allow_other_host: true
                      )
            end

            it 'destroys the request object' do
              expect { perform }.to change(Request, :count).from(1).to(0)
            end
          end

          context 'when no user has been selected' do
            let(:response_type) { 'code' }

            let(:body_params) do
              {
                reqid: 'foobar',
                user: 'baz',
                scope_fruit: '1',
                scope_veggies: '0',
                scope_meats: '1',
                approve: true
              }
            end

            before do
              allow(Rails.logger).to receive(:error)
              allow(controller).to receive(:render)
            end

            it 'logs the error' do
              perform
              expect(Rails.logger).to have_received(:error).with("Unknown user 'baz'")
            end

            it 'renders the error page' do
              perform
              expect(controller)
                .to have_received(:render)
                      .with('error', locals: { error: "Unknown user 'baz'" }, status: :internal_server_error)
            end
          end
        end
      end

      context 'when authorization is denied' do
        let(:body_params) do
          {
            client_id: client.client_id,
            reqid: 'foobar',
            user: 'doesntmatter',
            scope_fruit: '1',
            scope_veggies: '0'
          }
        end

        before do
          allow(Rails.logger).to receive(:info)
          allow(controller).to receive(:redirect_to)
        end

        it 'logs that permission was denied' do
          perform
          expect(Rails.logger).to have_received(:info).with("User denied access for client '#{client.client_id}'")
        end

        it 'redirects with an error' do
          perform
          expect(controller)
            .to have_received(:redirect_to)
                  .with(
                    "#{req.redirect_uri}?error=access_denied",
                    status: :found,
                    allow_other_host: true
                  )
        end

        it 'destroys the request object' do
          expect { perform }.to change(Request, :count).from(1).to(0)
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

      before do
        allow(Rails.logger).to receive(:error)
        allow(controller).to receive(:render)
      end

      it 'logs the error' do
        perform
        expect(Rails.logger).to have_received(:error).with("No matching authorization request for reqid 'nonexistent'")
      end

      it 'renders the error page' do
        perform
        expect(controller).to have_received(:render).with('error', locals: { error: 'No matching authorization request' })
      end

      it "doesn't create an authorization code" do
        expect { perform }.not_to change(AuthorizationCode, :count)
      end
    end
  end
end