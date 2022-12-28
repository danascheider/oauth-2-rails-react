# frozen_string_literal: true

configatron.oauth do
  oauth.auth_server do
    auth_server.authorization_endpoint = 'http://localhost:4003/authorize'
    auth_server.token_endpoint = 'http://localhost:4003/token'
    auth_server.revocation_endpoint = 'http://localhost:4003/revoke'
    auth_server.registration_endpoint = 'http://localhost:4003/register'
    auth_server.user_info_endpoint = 'http://localhost:9001/userinfo'
  end

  oauth.client do
    client.client_id = 'oauth-client-1'
    client.client_secret = 'oauth-client-secret-1'
    client.redirect_uris = ['http://localhost:4000/callback']
    client.scope = ''
  end

  oauth.resource do
    resource.base_uri = 'http://localhost:4002/words'
  end
end
