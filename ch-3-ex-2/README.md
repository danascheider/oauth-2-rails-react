# OAuth 2.0 in Action Exercise 3-2

## Table of Contents

* [Important Points and Surprising Behaviour](#important-points-and-surprising-behaviour)
  * [Persistence](#persistence)
  * [Client Endpoints and Front-End Behaviour](#client-endpoints-and-front-end-behaviour)
  * [Notes on Parameters in Rails](#notes-on-parameters-in-rails)
* [Extensions](#extensions)
  * [Suggested Extension](#suggested-extension)
    * [Implementation](#implementation)
  * [Additional UX Improvement](#additional-ux-improvement)
    * [Implementation](#implementation-1)

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

The suggested extension for this exercise is similar to the one for the previous example. In the event a `refresh_token` grant fails, the user should be automatically prompted to (re-)authorise the application.

Note that there is no mechanism in this system by which this would happen, so to illustrate this behaviour, you'll have to manually create the conditions under which such an error would occur. You can do this by removing the refresh token and access token from the auth server database.

`cd` into the auth server and, open the Rails console with `bundle exec rails c`. In the Rails console, destroy the access tokens and refresh tokens:

```ruby
AccessToken.destroy_all
RefreshToken.destroy_all
```

Now, when the client attempts to refresh its access token, the request will fail and the user should be prompted to reauthorise.

#### Implementation

I've implemented this extension by adding an `authorize()` function to the [resource page](/client_frontend/src/pages/resource_page/resource_page.js) that gets called when the initial request to fetch the protected resource returns status 401. This calls the client back end's `/authorize` endpoint, redirecting to the auth server's approval page.

### Additional UX Improvement

As with the previous exercise, it's reasonable to assume that a user who has navigated to the protected resource page on the front end - either by clicking the "Fetch Protected Resource" button on the homepage or by navigating to the resource page directly - doesn't want to be returned to the homepage after they reauthorise the application. For that reason, I've also added the ability for the user to be redirected to the resource page as well as the callback page. They'll only be redirected to the callback page if they click the "Get OAuth Token" button on the homepage or callback page.

#### Implementation

I implemented this the same way as in exercise 3-1. First, I updated the seeds for the auth server and the config for the client back end to allow an additional redirect URI, `"http://localhost:4000/resource"`. In the [client config](/client/config/configatron/defaults.rb), I made the redirect URIs a hash instead of an array, enabling one to be specified by name instead of by index in an array, which would be brittle since somebody could change the order of the array. Then, on the client back end's `/authorize` endpoint, I added a possible query param called `redirect_page`. If this param is not present or doesn't correspond to any keys in the redirect URI hash, it will default to `"http://localhost:4000/callback"`. If the param is present and corresponds to a key in the redirect URI hash, it will set that URI as the redirect URI for the request.

On the front end, then, I arranged for this query param to be set when the client back end's `/authorize` endpoint is requested from the resource page.

When the auth server redirects to the redirect URI, it includes the query params used for the `authorization_code` grant type, including the `code` and `state` used to request an access token. Since the resource page is now a valid redirect URI, it has to know what to do when it receives these query params. Specifically, like the callback page, it needs to pass them through to the back end, which uses them to request an access token from the auth server using the authorization code from the query params. Only after this request has completed successfully can the protected resource be fetched.

I configured the `useEffect` hook on the resource page to forward the query params, if present, to the client back end's `/callback` endpoint. If this request is successful, it then fetches the protected resource. If the request is not successful, the user is prompted to authorise again. (This could result in an endless cycle for our poor user if there is an issue with reauthorisation/refresh tokens resulting repeated 401 responses being returned.)

If the `code` query param is not included in the query string, the resource page will assume this is a normal request for the protected resource and immediately makes that request when the component mounts.