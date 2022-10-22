# OAuth 2.0 in Action Exercise 3-1

## System Requirements

You will need the following to run this OAuth system:

* PostgreSQL (will need to be installed on your system before you run `bundle install` for any of the Rails apps contained in this directory)
* Ruby 3.1.2
* Node.js 18.10.0
* Yarn 1.22.19

I'm not sure what exactly what the version requirements are for PostgreSQL - I'm running 14.2.1. It is recommended to manage versions of Ruby, Node.js, and Yarn with [asdf](https://asdf-vm.com).

## Dev Environment Setup

Once you have the appropriate system requirements and are using the correct versions of system software (PostgreSQL, Ruby, Node.js, and Yarn), you can run the setup scripts. These instructions assume you have the correct versions of Ruby, Node.js, and Yarn already installed using asdf.

You can install dependencies and set up databases (create, migrate, and seed) for all four apps by running the following from the directory containing this README:

```bash
./script/setup
```

If you would like to install dependencies for all apps but not set up the databases or vice versa, you can run:

```bash
# Install dependencies
./script/install_deps

# Set up databases
./script/setup_dbs
```

## Running Locally

In order for the system to function properly, each of the four applications in this monorepo must be running. Additionally, they must be running on the appropriate ports since this is required by the [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) configurations for the applications.

You'll want to open a separate terminal window for each application to run in. Although the apps have to run together in order for the system to operate, it doesn't matter in which order you start the servers. The servers run on ports 4000-4003, inclusive. This is different from the _OAuth 2.0 in Action_ examples, which run on ports 9000-9002, inclusive. I've done this so that the authors' examples may be run concurrently with these. That way, you can compare results at each step.

Be sure you have run the dev environment setup steps prior to starting the servers or you will get errors.

Each of the sections below assumes you are starting from the root directory of the `ch-3-ex-1` monorepo.

### Auth Server

The auth server should run on port 4003:

```
cd auth_server
bundle exec rails s -p 4003
```

You can visit the auth server's informational page in the browser at `http://localhost:4003` once you've completed these steps.

### Protected Resource

The protected resource should run on port 4002:

```
cd protected_resource
bundle exec rails s -p 4002
```

The protected resource does not have any pages that can be viewed in the browser, it is strictly an API.

### Client Backend

The client backend should run on port 4001:

```
cd client
bundle exec rails s -p 4001
```

### Client Frontend

The client frontend runs on port 4000. This will happen automatically when you start the server using the script defined in the `package.json` file:

```
cd client_frontend
yarn start
```

## Utility Scripts

This monorepo contains handy scripts to enable you to do various tasks for all the apps at once. This way you don't have to `cd` into multiple directories executing commands every time you want to, say, truncate and re-seed all the databases to put the systems back in their starting state.

### Reset Databases and Logs

For troubleshooting, it is often beneficial to truncate databases and logs so you start from a clean slate on the next request.

```bash
# Truncate and re-seed all 3 back-end databases
./script/reset_dbs

# Clear logs for all 3 Rails apps
./script/clear_logs

# Do both of these things in one command
./script/reset
```

### Set Up Dev Environments

```bash
# Install dependencies for all apps with Bundler and Yarn
./script/install_deps

# Set up databases for all Rails apps (create, migrate, seed)
./script/setup_dbs

# Do both of these things in one command
./script/setup
```

## Important Points and Surprising Behaviour

There are a couple ways in which this system differs from the one in _OAuth 2.0 in Action_.

### Persistence

First of all, data is stored in a Postgres database instead of in variables or an in-memory data store. This means that persistence and a couple other aspects of the system's function are different. When the application makes requests using a token, it uses the most recent token stored in the database.

### Client Endpoints and Front-End Behaviour

Because access tokens are persisted in the database, an access token could already be present on startup. This differs from the book, which leverages variables and in-memory data stores to keep track of access tokens. Consequently, the book's client application (which is a monolith, in contrast to the client in this system) is able to confidently assume that the correct access token value to display initially is `'NONE'`. Since this isn't the case for these applications, I've added the `/token` endpoint to the client API to enable the front end to fetch the last saved token to display initially. The client does this in a `useEffect` hook, displaying either the access token or any error returned from the endpoint. `'NONE'` is only displayed if the response from the endpoint indicates that there is no saved access token.

### Scopes

An astute observer will notice that, while the client has access to the `foo` and `bar` scopes per the authorisation server, the access token only covers the `foo` case. Scopes don't really matter for this exercise anyway, in that the protected resource doesn't check them, and I did this to experiment with requesting scopes more limited than those allowed by the auth server.

### Notes on Parameters in Rails

The OAuth protocol is often very specific about how parameters and other data need to be passed, making use of headers, query strings, and post data. In Rails, query strings and post data are combined into a single `params` object. In general, controllers access these values agnostically. Although doing it that way would probably not cause problems in this system, to more clearly illustrate the OAuth protocol, I've separated params into query parameters (accessed with `request.query_parameters` within the controller) and body parameters (accessed with `request.request_parameters` within the controller). In cases where it truly does not matter, the default `params` hash is still used.

There is one important implication to the fact that query strings and post data are combined into a single `params` object: if the post data and query string contain the same key, one will overwrite the other since a hash can only contain a single value for each key. This prevents us from, say, raising an error when `client_id` is sent to the auth server's `/token` endpoint in both the query string and the post data the way an error is raised when the `client_id` is sent in both the `Authorization` header and the params. This is only a small issue in this application but it is worth being aware of if you decide to modify or extend the code.

## Extensions

In each section, _OAuth 2.0 in Action_ suggests possible extensions of the exercises provided. This system includes the extension suggested by the authors as well as an additional extension I independently chose to implement as a UX improvement.

### Suggested Extension

The basic system the book illustrates in its walkthrough - and the one the authors have published on GitHub - displays an error page in the event a call to fetch the protected resource fails due to a missing OAuth token. The suggested extension involves automatically prompting the user to (re-)authorise the client if the request for the protected resource fails.

On the [home/callback page](/client_frontend/src/components/home_page_content/home_page_content.js), the handler for the "Fetch Protected Resource" button is set based on the presence or absence of a `tokenValue` set with `useState`. If a token value is present, the user is taken to the protected resource page. If the token value is not present, they are prompted to re-authorise. This could lead to unexpected behaviour in a deployed application with multiple users, as in such an application, an access token could have been added on the back end since the last time the front end fetched. In this case, the user would be prompted to reauthorise and a new token would be issued. That isn't really a problem with this system anyway, since all access tokens ever issued work, but it is worth mentioning that this approach would need to be modified in a production system.

#### Implementation

On the [protected resource page](/client_frontend/src/pages/resource_page/resource_page.js), the re-authorisation prompt happens on page load, in the `useEffect` hook where the protected resource is requested from the client API. The API will always respond with the response status code it receives from the protected resource. If that status code is `401 Unauthorized`, then the user will be redirected to the auth server to re-authorise the application.

### Additional UX Improvement

Say a user has gone to the homepage and there is no access token but, users being users, has clicked on the "Fetch Protected Resource" button anyway. It stands to reason that what this user really wants is to see is the protected resource - they've already indicated this by navigating to that page and away from the homepage. It will be annoying to them to be directed back to the homepage after authorising the application when they've already told us that isn't the page they want to see. To improve this hypothetical user's experience, I've enabled them to be redirected directly to the protected resource page in this event. This is also the behaviour if they navigate directly to the resource page, bypassing the homepage entirely, and receive a 401 response from the server. Only if the user has clicked "Get OAuth Token" on the homepage will they be redirected to the `/callback` page.

#### Implementation

First, I needed to modify the client's redirect URIs. This needed to be changed in two places: the auth server's [seed data](/auth_server/db/seeds.rb) and the client's [OAuth config](/client/config/configatron/defaults.rb) I added `"http://localhost:4000/resource"` to the client's allowed redirect URIs in both places. Remember that attempting to redirect a user to a URI other than one of those registered with the auth server will result in an error.

Next, the front end needed a way to tell the client API which page the user should be redirected to. I opted to do this by including a `redirect_page` query param to the request sent to the API's `/authorize` endpoint and refactoring the client config to use a hash for redirect URIs instead of an array. This way, I could set the correct redirect URI by calling:

```ruby
configatron.oauth.client.redirect_uris[query_params[:redirect_page]&.to_sym]
```

In the event there is no such key in the redirect URI hash, the client API defaults to using `"http://localhost:4000/callback"`.

Finally, the front end needed to handle the case where the redirect came to the protected resource page. In the `useEffect` hook where the protected resource is fetched, the front end checks for a query param called `code`, which is the authorisation code sent from the auth server. If this param is included, it calls the client back end's `/callback` endpoint with the query params and waits for that request to resolve before attempting to fetch the protected resource. If there is no `code` query param, the front end requests the `/fetch_resource` endpoint immediately.

Note that the `code` query param will only be included in the callback query string if the client is using OAuth's `authorization_code` grant type. For that reason, in subsequent exercises where additional grant types are used, the approach of checking for a `code` query param will need to be modified.

## Disclaimer

As the authors of _OAuth 2.0 in Action_ have emphasised in their book, this system is appallingly insecure and is intended for illustration purposes only:

* Token values and client secrets are displayed in the GUI of the client and auth server, respectively
* Values of authorization codes and access tokens are stored in plain text in the database
* Authorization codes are not tied to client ID so any client could use them
* Authorization codes and tokens are logged for debugging and troubleshooting purposes
* CORS permissions are probably a little laxer than they need to be, although I'm not sure about this

None of these things should be the case in a production system so please use care.

Finally, these apps are intended for illustration purposes only. There are various unaccounted-for edge cases and exception handling is minimal. Comments in the code for this exercise will help you see what some of these issues are.
