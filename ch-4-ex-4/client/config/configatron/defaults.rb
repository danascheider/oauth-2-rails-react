# frozen_string_literal: true

configatron.oauth do |oauth|
  oauth.client do |client|
    client.client_id = 'oauth-client-1'
    client.client_secret = 'oauth-client-secret-1'
    client.default_redirect_uri = 'http://localhost:4000/callback'
    client.scope = 'movies food music'
  end

  oauth.auth_server do |auth_server|
    auth_server.authorization_endpoint = 'http://localhost:4003/authorize'
    auth_server.token_endpoint = 'http://localhost:4003/token'
  end

  oauth.protected_resource do |protected_resource|
    protected_resource.uri = 'http://localhost:4002/favorites'
  end
end
