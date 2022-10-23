# OAuth 2.0 in Action Exercise 4-1

## Table of Contents

* [Important Points and Surprising Behaviour](#important-points-and-surprising-behaviour)
  * [Persistence](#persistence)
  * [Client Endpoints and Front-End Behaviour](#client-endpoints-and-front-end-behaviour)
  * [Notes on Parameters in Rails](#notes-on-parameters-in-rails)
* [Extensions](#extensions)
  * [Suggested Extension](#suggested-extension)
    * [Implementation](#implementation)

## Important Points and Surprising Behaviour

There are a couple ways in which this application differs from the one in _OAuth 2.0 in Action_. First of all, data is stored in a Postgres database instead of in variables or an in-memory data store. This means that persistence is slightly different. For example, there is a `/token` endpoint on the client backend that enables the client to fetch the most recent access token to display on the homepage when it loads.

### Persistence

First of all, data is stored in a Postgres database instead of in variables or an in-memory data store. This means that persistence and a couple other aspects of the system's function are different. When the application makes requests using a token, it uses the most recent token stored in the database. The client backend database is seeded with an expired access token, which has a refresh token that will work with the auth server.

### Client Endpoints and Front-End Behaviour

Because the book uses a monolith for its OAuth client application, the value of the existing access token is automatically rendered on initial page load. However, this repo uses a distributed stack, so the front end doesn't automatically know what models are in the database. Because of this, I've added the `GET /token` endpoint to the client API to enable the front end to fetch the last saved token to display initially. The client does this in a `useEffect` hook, displaying either the access token or any error returned from the endpoint. `'NONE'` is only displayed if the response from the endpoint indicates that there is no saved access token.

If you have run the setup script or seeded the client's database manually, there will be an (expired) access token already present when you initially run the app.

### Notes on Parameters in Rails

The OAuth protocol is often very specific about how parameters and other data need to be passed, making use of headers, query strings, and post data. In Rails, query strings and post data are combined into a single `params` object. In general, controllers access these values agnostically. Although doing it that way would probably not cause problems in this system, to more clearly illustrate the OAuth protocol, I've separated params into query parameters (accessed with `request.query_parameters` within the controller) and body parameters (accessed with `request.request_parameters` within the controller). In cases where it truly does not matter, the default `params` hash is still used.

There is one important implication to the fact that query strings and post data are combined into a single `params` object: if the post data and query string contain the same key, one will overwrite the other since a hash can only contain a single value for each key. This prevents us from, say, raising an error when `client_id` is sent to the auth server's `/token` endpoint in both the query string and the post data the way an error is raised when the `client_id` is sent in both the `Authorization` header and the params. This is only a small issue in this application but it is worth being aware of if you decide to modify or extend the code.

## Extensions

### Suggested Extension

#### Implementation
