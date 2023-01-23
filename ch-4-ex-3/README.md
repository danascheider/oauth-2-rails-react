# OAuth 2.0 in Action Exercise 4-3

## Table of Contents

* [Important Points and Surprising Behaviour](#important-points-and-surprising-behaviour)
  * [Persistence](#persistence)
  * [Client Endpoints and Front-End Behaviour](#client-endpoints-and-front-end-behaviour)
  * [Notes on Parameters in Rails](#notes-on-parameters-in-rails)
  * [Users](#users)
  * [Request Model](#request-model)
  * [Nonce](#nonce)
  * [Client Credentials Grant Type](#client-credentials-grant-type)
  * [Password Grant Type](#password-grant-type)
  * [Issuing Tokens](#issuing-tokens)
  * [Refresh Tokens](#refresh-tokens)
  * [Refresh Tokens from the Client's Perspective](#refresh-tokens-from-the-clients-perspective)
  * [Shared Database](#shared-database)
    * [database.yml](#databaseyml)
    * [Schemas](#schemas)
    * [SharedModel](#sharedmodel)
    * [New Models](#new-models)
  * [Authenticating with the Protected Resource](#authenticating-with-the-protected-resource)
  * [Errors from Protected Resource](#errors-from-protected-resource)
* [Architecture](#architecture)
* [Extensions](#extensions)
  * [Suggested Extension](#suggested-extension)

## Important Points and Surprising Behaviour

There are a couple ways in which this application differs from the one in _OAuth 2.0 in Action_.

### Persistence

First of all, data is stored in Postgres databases instead of in variables or an in-memory data store. This means that persistence and a couple other aspects of the system's function are different. For example, there is a `/token` endpoint on the client backend that enables the client to fetch the most recent access token to display on the homepage when it loads. When the application makes requests using a token, it uses the most recent token stored in the database.

### Client Endpoints and Front-End Behaviour

Because the book uses a monolith for its OAuth client application, the value of the existing access token is automatically rendered on initial page load. However, this repo uses a distributed stack, so the front end doesn't automatically know what models are in the database. Because of this, I've added the `GET /token` endpoint to the client API to enable the front end to fetch the last saved token to display initially. The client does this in a `useEffect` hook, displaying either the access token or any error returned from the endpoint. `'NONE'` is only displayed if the response from the endpoint indicates that there is no saved access token.

If you have run the setup script or seeded the client's database manually, there will be an (expired) access token already present when you initially run the app.

### Notes on Parameters in Rails

The OAuth protocol is often very specific about how parameters and other data need to be passed, making use of headers, query strings, and post data. In Rails, query strings and post data are combined into a single `params` object. In general, controllers access these values agnostically. Although doing it that way would probably not cause problems in this system, to more clearly illustrate the OAuth protocol, I've separated params into query parameters (accessed with `request.query_parameters` within the controller) and body parameters (accessed with `request.request_parameters` within the controller). In cases where it truly does not matter, the default `params` hash is still used.

There is one important implication to the fact that query strings and post data are combined into a single `params` object: if the post data and query string contain the same key, one will overwrite the other since a hash can only contain a single value for each key. This prevents us from, say, raising an error when `client_id` is sent to the auth server's `/token` endpoint in both the query string and the post data the way an error is raised when the `client_id` is sent in both the `Authorization` header and the params. This is only a small issue in this application but it is worth being aware of if you decide to modify or extend the code.

### Users

In the book's examples, the authorization server has a concept of users that doesn't exist in the other components (client or protected resource). It seems the authors implemented this feature only partially. Since I'm not sure what the endgame was in including users, I also have only implemented it partially. However, because the authorization server requires user to be specified in certain parameters, I've made the client backend also aware of the user `sub` value so that it can request tokens for that user.

In particular, I've modified the query string sent to the client's callback URI to include the user's `sub` value. When the authorization code is exchanged for a token, the client then includes a `user` param with this value that the auth server can use to identify the resource owner.

Another case involving users is the `/approve` endpoint of the auth server. In this handler, when the `response_type` is set to `'token'`, a 500 response is returned if the user is missing. However, in the book's examples, if the `response_type` is `'code'`, there is no validation to make sure the user exists. I've changed this so the presence of a user is validated for both response types and an error returned if no user is present.

In the protected resource, all users have the same permissions, so in the client's `/produce` handler, I've used the last saved access token in the database regardless of who the user is. The protected resource is also agnostic to users, accepting any existing and un-expired token. (It also doesn't do other validations, such as verifying the client or that the access token's scopes are all among the client's scopes. Since this auth server only handles authorization for this protected resource, it's safe to assume all registered clients are able to access the resource.) Obviously if different users had access to different data, we would need to ensure the correct user's data is requested.

### Request Model

For this example I have diverged a bit from my earlier approach with the `Request` model. Previously, the `state` and `response_type` values were stored in a JSON object in the `query` field. However, I didn't see a good reason for this, so for this example (and probably future ones), I've decided to make these fields on the model.

### Nonce

The `AuthorizationsController#generate_token_response` method in the authorization server takes a `nonce` as an optional argument. In the `#token` endpoint, this value is passed in as the nonce associated with the `AuthorizationCode` when it was created. The book's example doesn't actually use the nonce in generating the tokens, though, nor is there a way to actually set a nonce for the authorization code model. Like users, this seems to be functionality that the authors didn't fully implement, or was intended as an extension for readers.

### Client Credentials Grant Type

In the authorization server's `#token` endpoint handler, the client is first identified using either the authorization header or post body params. (The book indicates that it could also be identified by query params, however, the code example doesn't check the query params for the client ID/secret values, so I haven't done that in this example either.) If the client does not exist, or if the secret doesn't match, an error is returned. However, later, if the body params indicate the grant type is `'client_credentials'`, the `client` variable is set again using the `client_id` from the query params. There is no error handling in the cases where (1) no client exists with the given ID, (2) no client ID is present in the query params or (3) the client secret is missing from the query params or doesn't match the client ID. Because the book and other documentation I've found don't indicate client authentication works differently for client credentials than other grant types, I believe this is an error. In the previous example, I left it as-is, but in this one I'm using the same method of client identification for client credentials as for other grant types.

It's worth noting that there is a bug in the book's example in this code path that would blow up if a client actually attempted to use this grant type:

```js
// The variable `query` is not defined. Previously, the variable `query` has been assigned to
// a Request object, so it's possible that was intended, or it may be meant to be `req.query`.
var client = getClient(query.clientId);
```

### Password Grant Type

I've handled this grant type slightly differently in this exercise than in previous ones. Although not all users have usernames, I've opted to use the username as the identifier for users here, effectively requiring a user to have a username in order to use this grant type. In order to avoid a security hole where a missing or empty `:password` body param is matched to a missing or empty `password` value on the user, I've also added logic to ensure a user has a password and that it is not blank or empty before proceeding with the grant.

The book's example also doesn't check scopes in the password grant type. I assume this is in error as I don't see a reason why scopes shouldn't be validated for this grant type. In deciding on an error response, I went with a `400 Bad Request` response and an `'invalid_scope'` error message, the same as when validating scopes for the client credentials grant type.

### Issuing Tokens

In the book's example, access and refresh tokens are generated in the `generateTokens` function. In this implementation, this function is analogous to the `TokenHelper::generate_token_response` method. Like the function provided by the authors, this function takes a `generate_refresh_token` argument indicating whether the refresh token should be generated. However, the book doesn't account for the case where a refresh token already exists for the given client and user.

To handle this case, I've decided on the following behaviour for this example:

* When the `generate_refresh_token` argument is omitted or set to `false`:
  * No refresh token is generated, regardless of the presence of an existing one
  * If there is an existing refresh token for that client and user, and its scope matches the requested one, it is included in the hash returned from the method
  * If there is an existing refresh token for that client and user, and its scope differs from the requested one, it is destroyed and not replaced
* When the `generate_refresh_token` argument is set to `true`:
  * If a refresh token exists for the given client and user, and its scope is equal to the scope requested, no new refresh token is generated and the existing one is included in the hash
  * If a refresh token exists for the given client and user, and its scope differs from the scope requested, that token is destroyed and a new one generated
  * If no refresh token exists for that client and user, a new one is generated and included in the hash returned

### Refresh Tokens

In contrast to previous examples, in this example, I've restricted refresh tokens to one per client-user combination. If I were going to do the previous examples over, I would do the same with them as well, even though the book's example doesn't do any similar validations. The reason it seemed better to me to use the validation is that, without it, a malicious user could potentially use an old refresh token with a more permissive scope to access data or perform actions they shouldn't. With the validations, old tokens must be destroyed before a new one can be created.

### Refresh Tokens from the Client's Perspective

In the book's example, the authorization server issues refresh tokens and handles the `'refresh_token'` grant type, but the client doesn't actually use the refresh tokens. Because this functionality is implemented in the auth server, I've decided to implement it in the client backend code as well. Like the previous exercise (ex. 4-1), this client will automatically request a new access token if a request to the protected resource fails.

### Shared Database

The auth server shares its database with the protected resource, which only reads from that database. However, in order to facilitate testing, it was necessary to use a different approach in the test environment to enable access tokens to be seeded before request specs. This wasn't an issue in past examples because previous examples weren't tested and therefore test environment configuration was a moot point. For this reason, for this and future examples that use a shared database, the following changes have been made from previous exercises.

#### database.yml

Instead of using the auth server's dev database in the test environment, the protected resource in this exercise has its own database in the test environment set up to mimic that of the auth server.

#### Schemas

In order to prevent errors, I had to generate a schema file for the shared test database. The main database schema file is `/db/schema.rb` - this database is empty because we aren't using DB persistence for the produce items since they are just strings. The test database schema is `/db/shared_schema.rb`. This file is copied from the auth server's `schema.rb` file. In a production application, this file would have to be updated every time the auth server's schema changed, but for the sake of the example it works.

#### SharedModel

The abstract model `SharedModel` has had some changes as well, ensuring that the database is read-only in development and production environments but includes write access in the test environment. I dislike modifying application code to behave differently in a test environment, since it means tests will not be able to truly test the way the application actually works. However, I couldn't find an alternative other than to use raw SQL with hard-coded values to populate the access tokens in the "shared" database. I began implementing that approach but it proved onerous and error-prone. Since this is only an example, I went with making the code behave differently in tests.

#### New Models

In order to populate the access tokens, I needed to also create `Client` and `User` models, with the same assocations to `AccessToken` as are present in the auth server database, for the purpose of satisfying foreign key constraints. This enabled me to use FactoryBot to populate the database instead of a custom module.

Note that the auth server will not create an access token with more permissive or different scopes than are available to the client. However, since this application doesn't create or destroy access tokens, it contains no such assurances. For that reason, in tests, the client's scopes may be different or more limited than those of the access token belonging to that client.

### Authenticating with the Protected Resource

In the book's example, the route `GET /produce` on the protected resource allows authenticating using, in order of preference:

* The authorization header
* Body params
* Query params

However, `GET` requests, at least in Rails, only support query params. I didn't become aware of this issue until now, so the code is slightly wrong in previous exercises, in that it checks for the access token in the body params before the query params. I'm not sure that this hurts anything (since it falls back to the query params anyway), but in this example I've removed the ability to use body params to authenticate. I'm not sure if not allowing body params breaks the OAuth protocol. (Note that [this tutorial](https://codeforgeek.com/handle-get-post-request-express-4/) suggests this is the same in Express.js, so it may be failing silently in the authors' example too.)

Note that, if we defined the `get_access_token` method on the `ApplicationController` instead of the `ProduceController`, we could assume it might be used for other routes in the future. In that case, it would make sense to check for body params too. Here I'm treating this as a premature optimisation.

### Errors from Protected Resource

In the `ProduceController#fetch` method on the client API, when the protected resource returns a 401 response, the application attempts to refresh the access token using a saved refresh token, returning a 401 response only if this fails. When the protected resource returns any other error response, the client API's response to the front end will have a 200 status, with the body containing an error message. I chose the 200 status for two reasons:

* The client front end doesn't rely on response status to determine how results should be populated - it gleans this from the shape of the response body
* No error is actually occurring in the client API, which is responding normally to responses from the protected resource.

## Architecture

As with example 4-2, I have used controller services in the auth server to encapsulate logic better within the `AuthorizationsController`.

## Extensions

### Suggested Extension

There is no suggested extension for this exercise.
