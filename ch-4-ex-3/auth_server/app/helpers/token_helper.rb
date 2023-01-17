# frozen_string_literal: true

module TokenHelper
  class InvalidClientError < StandardError; end
  class InvalidUserError < StandardError; end
  class InvalidScopeError < StandardError; end

  def generate_token_response(client:, scope:, user: nil, generate_refresh_token: false)
    raise InvalidClientError, 'Invalid or missing client' unless client.is_a?(Client)
    raise InvalidUserError, 'Invalid or missing user' unless user.is_a?(User) || user.nil?
    raise InvalidScopeError, 'Invalid scope' if scope.nil?

    output_scope = scope.join(' ')
    access_token = SecureRandom.hex(32)
    AccessToken.create!(
      client:,
      user:,
      scope:,
      token: access_token,
      token_type: 'Bearer',
      expires_at: Time.zone.now + 1.minute
    )

    message =
      if user.present?
        "Issuing access token '#{access_token}' for client '#{client.client_id}' and user '#{user.sub}' with scope '#{output_scope}'"
      else
        "Issuing access token '#{access_token}' for client '#{client.client_id}' with scope '#{output_scope}'"
      end

    Rails.logger.info message

    refresh_token = RefreshToken.find_by(client:, user:)

    if refresh_token&.scope == scope
     refresh_token = refresh_token.token
    else
      refresh_token&.destroy!
      refresh_token = nil

      if generate_refresh_token
        refresh_token = SecureRandom.hex(16)
        RefreshToken.create!(
          client:,
          user:,
          scope:,
          token: refresh_token
        )
      end
    end

    { access_token:, refresh_token:, token_type: 'Bearer', scope: output_scope, client_id: client.client_id, user: user&.sub }.compact
  end
end