# OAuth 2.0 in Action Exercise 4-2

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
  * [Client Routes for Protected Resource](#client-routes-for-protected-resource)
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

### Nonce

The `AuthorizationsController#generate_token_response` method in the authorization server takes a `nonce` as an optional argument. In the `#token` endpoint, this value is passed in as the nonce associated with the `AuthorizationCode` when it was created. The book's example doesn't actually use the nonce in generating the tokens, though, nor is there a way to actually set a nonce for the authorization code model. Like users, this seems to be functionality that the authors didn't fully implement, or was intended as an extension for readers.

### Client Credentials Grant Type

In the authorization server's `#token` endpoint handler, the client is first identified using either the authorization header or post body params. (The book indicates that it could also be identified by query params, however, the code example doesn't check the query params for the client ID/secret values, so I haven't done that in this example either.) If the client does not exist, or if the secret doesn't match, an error is returned. However, later, if the body params indicate the grant type is `'client_credentials'`, the `client` variable is set again using the `client_id` from the query params. There is no error handling in the cases where (1) no client exists with the given ID, (2) no client ID is present in the query params or (3) the client secret is missing from the query params or doesn't match the client ID. Because the book and other documentation I've found don't indicate client authentication works differently for client credentials than other grant types, I believe this is an error. In the previous example, I left it as-is, but in this one I'm using the same method of client identification for client credentials as for other grant types.

### Password Grant Type

Users are uniquely identified by `sub` value in this application. Unlike in exercise 4-1, there is a `username` column on the `users` table in this application, however, not all users have one, so I've used `sub` as the unique identifier in all cases rather than `username`. It is also worth noting here that not all users have a password. In fact, of the three seeded users, only one has a password.

In the book, the `password` grant type does not check the request scope against the client's scope. I believe this to be in error and have changed it in this implementation so that, if the request scope is more permissive than the client scope, a 400 error is returned indicating a bad scope.

### Refresh Tokens from the Client's Perspective

In the book's example, the authorization server issues refresh tokens and handles the `'refresh_token'` grant type, but the client doesn't actually use the refresh tokens. Because this functionality is implemented in the auth server, I've decided to implement it in the client backend code as well. Like the previous exercise (ex. 4-1), this client will automatically request a new access token if a request to the protected resource fails.

### Client Routes for Protected Resource

In the book's example, the client has a `/words` route that renders the `words` page. It then has three `GET` routes:

* `GET /get_words` - retrieves words from the protected resource API
* `GET /add_word` - adds a word (makes a `POST` request to the protected resource)
* `GET /delete_word` - deletes the last word from the database (makes a `DELETE` request to the protected resource)

`/words` is the most RESTful name for all of these routes but it makes sense not to use it in the book's example since that route is used to render the page. However, since the client backend is a pure API in our case, the front end can have its own `/words` route to render the page that then makes requests to a `/words` route on the backend with actions differentiated by HTTP method. For that reason, the client backend in this example has the following routes:

* `GET /words` - retrieves the words from the protected resource API
* `POST /words` - adds a word
* `DELETE /words` - deletes the last word from the database

Note that these routes directly correspond to the protected resource's own routes.

## Architecture

Because the `AuthorizationsController` in the auth server has become bloated in the preceding examples, for this and future examples, I've implemented controller services, with each service being responsible for a single controller action. These services are stored in the `/app/controller_services` directory, in the subdirectory for the relevant controller.

## Extensions

### Suggested Extension

There is no suggested extension for this exercise.