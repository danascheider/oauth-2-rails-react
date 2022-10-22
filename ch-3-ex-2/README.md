# OAuth 2.0 in Action Exercise 3-2

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

Each of the sections below assumes you are starting from the root directory of the `ch-3-ex-2` monorepo.

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

## Important Points and Surprising Behaviour

There are a couple ways in which this application differs from the one in _OAuth 2.0 in Action_. First of all, data is stored in a Postgres database instead of in variables or an in-memory data store. This means that persistence is slightly different. For example, there is a `/token` endpoint on the client backend that enables the client to fetch the most recent access token to display on the homepage when it loads.

As the authors of _OAuth 2.0 in Action_ have emphasised in their book, this system is appallingly insecure and is intended for illustration purposes only:

* Token values and client secrets are displayed in the GUI of the client and auth server, respectively
* Values of authorization codes and access tokens are stored in plain text in the database
* Authorization codes are not tied to client ID so any client could use them
* Authorization codes and tokens are logged for debugging and troubleshooting purposes

None of these things should be the case in a production system so please use care.

Finally, these apps are intended for illustration purposes only. There are various unaccounted-for edge cases and exception handling is minimal. Comments in the code for this exercise will help you see what some of these issues are.

### Notes on Parameters in Rails

The OAuth protocol is often very specific about how parameters and other data need to be passed, making use of headers, query strings, and post data. In Rails, query strings and post data are combined into a single `params` object. In general, controllers access these values agnostically. Although doing it that way would probably not cause problems in this system, to more clearly illustrate the OAuth protocol, I've separated params into query parameters (accessed with `request.query_parameters` within the controller) and body parameters (accessed with `request.request_parameters` within the controller). In cases where it truly does not matter, the default `params` hash is still used.

There is one important implication to the fact that query strings and post data are combined into a single `params` object: if the post data and query string contain the same key, one will overwrite the other since a hash can only contain a single value for each key. This prevents us from, say, raising an error when `client_id` is sent to the auth server's `/token` endpoint in both the query string and the post data the way an error is raised when the `client_id` is sent in both the `Authorization` header and the params. This is only a small issue in this application but it is worth being aware of if you decide to modify or extend the code.