# OAuth 2.0 in Action on Rails

This repo contains the exercises for the excellent and highly-recommended book [_OAuth 2.0 in Action_](https://www.manning.com/books/oauth-2-in-action) ported to Ruby on Rails and React. The authors' original [exercises](https://github.com/oauthinaction/oauth-in-action-code) are written in Express.js. I was working through these exercises with the goal of implementing an OAuth client with a separate front and back end in React and Rails, respectively, instead of the monoliths implemented in the book's examples, so I decided to reimplement the systems the authors provided using these frameworks. In all aspects, including visual design, I've attempted to adhere closely to the examples in the book.

Since my focus is on writing a client application and not an authorisation server or protected resource, only the client applications in this app are split-stack - authorisation servers and protected resource servers are monoliths (to the extent they have GUIs at all - each just has a single home page to view information about the application and an error page in case there's an issue rendering the homepage).

## Table of Contents

* [Assumptions](#assumptions)
* [Organisation](#organisation)
* [System Requirements](#system-requirements)
  * [Dependencies](#dependencies)
* [Setup](#setup)
* [Running Locally](#running-locally)
  * [Auth Server](#auth-server)
  * [Protected Resource](#protected-resource)
  * [Client Backend](#client-backend)
  * [Client Frontend](#client-frontend)
* [Utility Scripts](#utility-scripts)
  * [Reset Databases and Logs](#reset-databases-and-logs)
  * [Set Up Dev Environments](#set-up-dev-environments)
* [Configuration and Architecture](#configuration-and-architecture)
* [Disclaimer](#disclaimer)

## Assumptions

OAuth is a pretty advanced topic to begin with, so I'm assuming you have some development experience and are familiar with the [model-view-controller](https://developer.mozilla.org/en-US/docs/Glossary/MVC) (MVC) pattern, Ruby, JavaScript (ES6), Rails, and React. These applications use Rails 7 and React 18. I've refrained from too much fancy refactoring in order to keep application flow as obvious as possible. All React applications use exclusively functional components.

I'm additionally assuming that you have read or are reading _OAuth 2.0 in Action_. (If you haven't, please do - it'll explain things better than I ever could.) There is no documentation in this repo explaining the details of how OAuth 2.0 works, what it is used for, grant types, etc., so if you haven't read the book, a basic knowledge of the OAuth 2.0 protocol is essential to understanding these examples.

## Organisation

Each directory in this repo is a monorepo containing four applications:

* `auth_server`, an authorisation server written in Ruby on Rails
* `protected_resource`, a protected resource server written in Ruby on Rails
* `client`, the Rails back-end for the OAuth client
* `client_frontend`, the React front-end for the OAuth client, built using [Create React App](https://create-react-app.dev/)

The monorepos each contain a README with the specifics on the applications contained there.

Where applicable, I have added functionality "left as an exercise for the reader" to these systems, and in certain cases, additional improvements that seemed appropriate or interesting to me. These are noted in the READMEs for the relevant monorepo, along with implementation details.

## System Requirements

Each of the systems included here requires the following software be installed on your system:

* PostgreSQL (I'm running 14.2.1)
* Ruby 3.1.2
* Node.js 18.10.0
* Yarn 1.22.19

It is recommended to use [asdf](https://asdf-vm.com) to manage versions of Ruby, Node, and Yarn in the event you need other versions installed on your system. If you use asdf, it will automatically detect which dependency versions to use based on the `.tool-versions` file included in each directory. You will need the `ruby`, `nodejs`, and `yarn` asdf plugins before this will work.

These examples were developed on a MacBook Pro with an M1 chip running OS X Monterey v. 12.5.

### Dependencies

In line with my own preference to avoid [excessive dependencies](https://dana-scheider.medium.com/choosing-a-third-party-library-e8b0f7aa9497), I've added as few Ruby gems and npm packages as I could get away with. This README tells which dependencies have been added to applications in every example. If a particular example requires additional dependencies, this will be noted in the README for its monorepo.

In addition to the gems Rails 7 includes by default, the following dependencies have been added:

* `rack-cors` (all Rails systems): Enables [CORS configuration](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) so the different systems can talk to each other
* `faraday` (client only): Used for making HTTP requests to the auth server and protected resource
* `configatron` (client only): Used for application config

In addition to the default packages included by Create React App for React 18, the following have been added to the React client front end applications:

* `proptypes`: Warns when unexpected props are passed into React components or required props are missing
* `react-helmet-async`: Enables contents of `<head>` to be changed when navigating with the React Router
* `react-router-dom`: Includes bindings for React Router

I've chosen not to use TypeScript for these applications because I'm not that proficient with it and it seemed like overkill for apps only intended to illustrate OAuth 2.0 system behaviour.

## Setup

Once you have the appropriate system requirements and are using the correct versions of system software (PostgreSQL, Ruby, Node.js, and Yarn), you can run the setup scripts in each monorepo. These instructions assume you have the correct versions of Ruby, Node.js, and Yarn already installed using asdf.

You can install dependencies and set up databases (create, migrate, and seed) for all four apps by running the following from the root directory of a given monorepo:

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

In order for the system to function properly, each of the four applications in a given monorepo must be running. Additionally, they must be running on the appropriate ports since this is required by the [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) configurations for the applications.

You'll want to open a separate terminal window for each application to run in. Although the apps have to run together in order for the system to operate, it doesn't matter in which order you start the Rails servers. (The client front ends do make requests to the client APIs on initial page load, so the front ends should be started last.) The apps run on ports 4000-4003, inclusive. This is different from the _OAuth 2.0 in Action_ examples, which run on ports 9000-9002, inclusive. I've done this so that the authors' examples may be run concurrently with these. That way, you can compare results at each step.

Be sure you have run the dev environment setup script prior to starting the servers or you will get errors.

Each of the sections below assumes you are starting from the root directory of one of the monorepos.

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

You can view the protected resource's informational page in the browser at `http://localhost:4002` once you've completed these steps.

### Client Backend

The client backend should run on port 4001:

```
cd client
bundle exec rails s -p 4001
```

The client back end is a pure API and has no Rails views that could be viewed in a browser.

### Client Frontend

The client frontend runs on port 4000. This will happen automatically when you start the server using the script defined in the `package.json` file - you don't have to specify the port the way you do for the Rails apps:

```
cd client_frontend
yarn start
```

## Utility Scripts

Each monorepo contains handy scripts to enable you to do various tasks for all the apps in that monorepo at once. This way you don't have to `cd` into multiple directories executing commands every time you want to, say, set up a dev environment or truncate and re-seed all the databases to put the systems back in their starting state. Rails commands and React scripts are, of course, available within each app's subdirectory.

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

## Configuration and Architecture

All apps use default configuration for Rails or Create React App except where it specifically needs to be modified for functionality to work (CORS, Configatron config, etc.). Databases have been configured with a naming scheme corresponding to the exercise number. So, for instance, the development database for the auth server in `ch-3-ex-1` is named `auth_server_development_3_1`.

In some exercises, the auth server's database is shared with the protected resource server to enable the protected resource to access data about access tokens. When this is the case, I've created an `ActiveRecord::Base` subclass for models in that database that makes these models strictly read-only - protected resources cannot modify, create, or destroy records in the shared database. Protected resources also have their own databases for models that aren't shared, such as the `Resource` itself.

## Disclaimer

As the authors of _OAuth 2.0 in Action_ have emphasised in their book, these systems are appallingly insecure and are intended for illustration purposes only. The specific security concerns vary from exercise to exercise but there are a few common ones to be aware of:

* Token values and client secrets are displayed in the GUI of the client and auth server
* Values of authorization codes and access tokens are stored in plain text in the database
* Authorization codes are not tied to client ID so any client could use them
* Authorization codes and tokens are logged for debugging and troubleshooting purposes
* CORS permissions are probably a little laxer than they need to be (although I'm not totally sure this is the case)

None of these things should be the case in a production system so please use care and judgment when implementing these concepts in a real-world situation.

There are various unaccounted-for edge cases in these examples, and exception handling is minimal. Comments in the code for each exercise will help you see what some of these issues are, but in general it's safe to assume that there will be edge cases that aren't handled for each exercise.

Lastly, **these examples have been directly ported from the examples given in _OAuth 2.0 in Action_.** Although the Rails and React implementations are my original work, the algorithms and protocol implementation are not, nor are the visual designs. I give full credit to authors Justin Richer and Antonio Sanso for their work developing these examples.