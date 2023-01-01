# frozen_string_literal: true

AccessToken.create!(
  access_token: 'a1d221ca205682a69ceaf0b0fad6ccefdced6e81d3fa4f169381c0c3b5a10a16',
  refresh_token: 'b15b3b4bf2f10020133e805602d21178',
  token_type: 'Bearer',
  scope: %w[read write delete]
)