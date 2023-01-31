# frozen_string_literal: true

module TokenHelper
  class InvalidClientError < StandardError; end
  class InvalidUserError < StandardError; end
  class InvalidScopeError < StandardError; end

  def generate_token_response(client:, scope:, user: nil, generate_refresh_token: false)
    raise InvalidClientError, 'Invalid or missing client' unless client.is_a?(Client)
    raise InvalidUserError, 'Invalid user' if user.present? && !user.is_a?(User)
    raise InvalidScopeError, 'Invalid or missing scope' unless valid_scope?(scope)

    output_scope = scope.join(' ')
    access_token = SecureRandom.hex(32)
    AccessToken.create!(
      client:,
      user:,
      scope:,
      token: access_token,
      token_type: 'Bearer',
      expires_at: Time.now + 1.minute
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
      message =
        if user.present?
          "Found matching refresh token '#{refresh_token.token}' for client '#{client.client_id}' and user '#{user.sub}'"
        else
          "Found matching refresh token '#{refresh_token.token}' for client '#{client.client_id}'"
        end

      Rails.logger.info message
      refresh_token = refresh_token.token
    else
      refresh_token&.destroy!
      refresh_token = nil

      if generate_refresh_token == true
        refresh_token = SecureRandom.hex(16)
        RefreshToken.create!(
          client:,
          user:,
          token: refresh_token,
          scope:,
        )

        message =
          if user.present?
            "Issuing refresh token '#{refresh_token}' for client '#{client.client_id}' and user '#{user.sub}'"
          else
            "Issuing refresh token '#{refresh_token}' for client '#{client.client_id}'"
          end

        Rails.logger.info message
      end
    end

    { access_token:, refresh_token:, token_type: 'Bearer', scope: output_scope, client_id: client.client_id, user: user&.sub }.compact
  end

  def valid_scope?(scope)
    scope.is_a?(Array) && scope.all? {|val| val.is_a?(String) }
  end
end