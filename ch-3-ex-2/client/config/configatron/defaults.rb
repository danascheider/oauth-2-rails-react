configatron.oauth do |oauth|
  oauth.client do |client|
    client.client_id = 'oauth-client-1'
    client.client_secret = 'oauth-client-secret-1'
    client.scope = 'foo'
    client.redirect_uris = {
      callback: 'http://localhost:4000/callback',
      resource: 'http://localhost:4000/resource'
    }
  end

  oauth.auth_server do |auth_server|
    auth_server.authorization_endpoint = 'http://localhost:4003/authorize'
    auth_server.token_endpoint = 'http://localhost:4003/token'
  end

  oauth.resource do |resource|
    resource.endpoint = 'http://localhost:4002/resources'
  end
end
