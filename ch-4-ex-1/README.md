# OAuth 2.0 in Action Exercise 4-1

## Table of Contents

* [Important Points and Surprising Behaviour](#important-points-and-surprising-behaviour)
  * [Persistence](#persistence)
  * [Client Endpoints and Front-End Behaviour](#client-endpoints-and-front-end-behaviour)
  * [Notes on Parameters in Rails](#notes-on-parameters-in-rails)
  * [Users](#users)
  * [Nonce](#nonce)
  * [Client Credentials Grant Type](#client-credentials-grant-type)
  * [Password Grant Type](#password-grant-type)
  * [Refresh Tokens from the Client's Perspective](#refresh-tokens-from-the-clients-perspective)
* [Extensions](#extensions)
  * [Suggested Extension](#suggested-extension)
    * [Implementation](#implementation)
* [Notes](#notes)

## Important Points and Surprising Behaviour

There are a couple ways in which this application differs from the one in _OAuth 2.0 in Action_.

### Persistence

First of all, data is stored in Postgres databases instead of in variables or an in-memory data store. This means that persistence and a couple other aspects of the system's function are different. For example, there is a `/token` endpoint on the client backend that enables the client to fetch the most recent access token to display on the homepage when it loads. When the application makes requests using a token, it uses the most recent token stored in the database. The client backend database is seeded with an expired access token, which has a refresh token that will work with the auth server.

### Client Endpoints and Front-End Behaviour

Because the book uses a monolith for its OAuth client application, the value of the existing access token is automatically rendered on initial page load. However, this repo uses a distributed stack, so the front end doesn't automatically know what models are in the database. Because of this, I've added the `GET /token` endpoint to the client API to enable the front end to fetch the last saved token to display initially. The client does this in a `useEffect` hook, displaying either the access token or any error returned from the endpoint. `'NONE'` is only displayed if the response from the endpoint indicates that there is no saved access token.

If you have run the setup script or seeded the client's database manually, there will be an (expired) access token already present when you initially run the app.

### Notes on Parameters in Rails

The OAuth protocol is often very specific about how parameters and other data need to be passed, making use of headers, query strings, and post data. In Rails, query strings and post data are combined into a single `params` object. In general, controllers access these values agnostically. Although doing it that way would probably not cause problems in this system, to more clearly illustrate the OAuth protocol, I've separated params into query parameters (accessed with `request.query_parameters` within the controller) and body parameters (accessed with `request.request_parameters` within the controller). In cases where it truly does not matter, the default `params` hash is still used.

There is one important implication to the fact that query strings and post data are combined into a single `params` object: if the post data and query string contain the same key, one will overwrite the other since a hash can only contain a single value for each key. This prevents us from, say, raising an error when `client_id` is sent to the auth server's `/token` endpoint in both the query string and the post data the way an error is raised when the `client_id` is sent in both the `Authorization` header and the params. This is only a small issue in this application but it is worth being aware of if you decide to modify or extend the code.

### Users

In the book's examples, the authorization server has a concept of users that doesn't exist in the other components (client or protected resource). It seems the authors implemented this feature only partially. Since I'm not sure what the endgame was in including users, I also have only implemented it partially. However, because the authorization server requires user to be specified in certain parameters, I've made the client backend also aware of the user `sub` value so that it can request tokens for that user.

In particular, I've modified the query string sent to the client's callback URI to include the user's `sub` value. When the authorization code is exchanged for a token, the client then includes a `user` param with this value that the auth server can use to identify the resource owner.

### Nonce

The `AuthorizationsController#generate_token_response` method in the authorization server takes a `nonce` as an optional argument. In the `#token` endpoint, this value is passed in as the nonce associated with the `AuthorizationCode` when it was created. The book's example doesn't actually use the nonce in generating the tokens, though, nor is there a way to actually set a nonce for the authorization code model. Like users, this seems to be functionality that the authors didn't fully implement, or was intended as an extension for readers.

### Client Credentials Grant Type

In the authorization server's `#token` endpoint handler, the client is first identified using either the authorization header or post body params. (The book indicates that it could also be identified by query params, however, the code example doesn't check the query params for the client ID/secret values, so I haven't done that in this example either.) If the client does not exist, or if the secret doesn't match, an error is returned. However, later, if the body params indicate the grant type is `'client_credentials'`, the `client` variable is set again using the `client_id` from the query params. There is no error handling in the cases where (1) no client exists with the given ID, (2) no client ID is present in the query params or (3) the client secret is missing from the query params or doesn't match the client ID. I suspect this is an error, but have left it as-is in this example.

### Password Grant Type

Users are uniquely identified by `sub` value in this application, and not by `username`. `username` is not a column in the `users` table, with the closest column being `preferred_username`. The fact that this field is called "preferred" suggests to me that it may not be unique, however, the `sub` would be a unique identifier so I've used it instead (in this and other places where users are identified). It is also worth noting here that not all users have a password. In fact, of the four seeded users, only one has a password.

In the book, the `password` grant type does not check the request scope against the client's scope. I believe this to be in error and have changed it in this implementation so that, if the request scope is more permissive than the client scope, a 400 error is returned indicating a bad scope.

### Refresh Tokens from the Client's Perspective

In the book's example, the authorization server issues refresh tokens and handles the `'refresh_token'` grant type, but the client doesn't actually use the refresh tokens. Because this functionality is implemented in the auth server, I've decided to implement it in the client backend code as well. Like the previous exercise (ex. 3-2), this client will automatically request a new access token if a request to the protected resource fails.

### Client Scope

I've modified the client's scope to include one value, `'foo'`. Otherwise, including any scope value with a request would result in disallowed scopes and an error response from the auth server or protected resource.

## Extensions

### Suggested Extension

There is no suggested extension for this exercise.

## Notes

The auth server's `AuthorizationsController` is extremely unwieldy in this application and I would generally use service classes to encapsulate logic better. I probably will do that in future exercises because different ways of constructing responses and identifying clients, users, etc. are making it hard to create and name all the private methods required if we don't want the entire controller to be a massive wall of code. For the present example, I stuck to the code in the book for the sake of "simplicity", but I'm not sure simplicity was the result.