# Securitybot
### Distributed alerting for the masses!
Securitybot is an open-source implementation of a distributed alerting chat bot, as described in Ryan Huber's [blog post][slack-blog].
Distributed alerting improves the monitoring efficiency of your security team and can help you catch security incidents faster and more efficiently.
We've tried to remove all Dropbox-isms from this code so that setting up your own instance should be fairly painless.
It should be relatively easy to install the listed requirements in a virtualenv/Docker container and simply have the bot do its thing.
We also provide a simple front end to dive through the database, receive API calls, and create custom alerts for the bot to reach out to people as desired.

## Deploying
This guide runs through setting up a Securitybot instance as quickly as possible with no frills.
We'll be connecting it to Slack, SQL, and Duo.
Once we're done, we'll have a file that looks something like `main.py`.

### SQL
You'll need a database called `securitybot` on some MySQL server somewhere.
We've provided a function called `init_sql` located in `securitybot/sql.py` that will initialize SQL.
Currently it's set up to use the host `localhost` with user `root` and no password.
You'll need to change this because of course that's not how your database is set up.

### Slack
You'll need a token to be able to integrate with Slack.
The best thing to do would be to [create a bot user][bot-user] and use that token for Securitybot.
You'll also want to set up a channel to which the bot will report when users specify that they haven't performed an action.
Find the unique ID for that channel (it'll look similar to `C123456`) and be sure to invite the bot user into that channel, otherwise it won't be able to send messages.

### Duo
For Duo, you'll want to create an [Auth API][auth-api] instances, name it something clever, and keep track of the integration key, secret key, and auth API endpoint URI.

### Running the bot
Take a look at the provided `main.py` in the root directory for an example on how to use all of these.
Replace all of the global variables with whatever you found above.
If the following were all generated successfully, Securitybot should be up and running.
To test it, message the bot user it's assigned to and say `hi`.
To test the process of dealing with an alert, message `test` to test the bot.

#### Environment variable
To prevent having to modify the scripts, you can set the following environment variables to configure the bot:

|Variable|Setting|
|--------|-------|
|SLACK_API_TOKEN|Slack API Token|
|REPORTING_CHANNEL|Slack Channel ID|
|DUO_INTEGRATION_KEY|Duo Integration Key|
|DUO_SECRET_KEY|Duo Secret Key|
|DUO_ENDPOINT|Duo Endpoint|
|DB_HOST|MySQL Hostname|
|DB_USER|MySQL Username|
|DB_PASS|MySQL Password|
|DB_NAME|MySQL Database name|

#### Docker

Dockerfile is included to generate a Docker Image to run the bot.  Entrypoint script will wait for database startup and initialize database if it does not already exist.  Entrypoint takes one of two arguments:

* bot: Starts the main bot
* frontend: starts the frontend and API server

Run configuration will be based on the environment variables above.

Example:

Bot:
```
docker build --tag securitybot
docker run -e DB_NAME=securitybot DB_NAME=securitybot -e DB_USER=root -e DB_HOST=127.0.0.1 -e DB_PASS=password -e SLACK_API_TOKEN=<your api token> -e DUO_INTEGRATION_KEY=<your integration key> -e DUO_SECRET_KEY=<your secret key> -e DUO_ENDPOINT=<your endpoint> securitybot bot
```

Frontend:
```
docker build --tag securitybot
docker run -p 8888:8888 -e DB_NAME=securitybot -e DB_USER=root -e DB_HOST=127.0.0.1 -e DB_PASS=password securitybot frontend
```

A docker-compose file is provided for ease of use. docker-compose up will start database, bot and frontend.  Frontend and API server will be available on port 8888.  Database content will be stored in persistent volume `mysql-securitybot`. Slack-related, Duo related and database password environment variables must be set for docker-compose stack to run properly.

## Architecture
Securitybot was designed to be as modular as possible.
This means that it's possible to easily swap out chat systems, 2FA providers, and alerting data sources.
The only system that is tightly integrated with the bot is SQL, but adding support for other databases shouldn't be difficult.
Having a database allows alerts to be persistent and means that the bot doesn't lose (too much) state if there's some transient failure.

### Securitybot proper
The bot itself performs a small set of functions:

1. Reads messages, interpreting them as commands.
1. Polls each user object to update their state of applicable.
1. Grabs new alerts from the database and assigns them to users or escalates on an unknown user.

Messaging, 2FA, and alert management are provided by configurable modules, and added to the bot upon initialization.

#### Commands
The bot handles incoming messages as commands.
Command parsing and handling is done in the `Securitybot` class and the commands themselves are provided in two places.
The functions for the commands are defined in `commands.py` and their structure is defined in `commands.yaml` under the `config/` directory.

### Messaging
Securitybot is designed to be compatible with a wide variety of messaging systems.
We currently provide bindings for Slack, but feel free to contribute any other plugins, like for Gitter or Zulip, upstream.
Messaging is made possible by `securitybot/chat/chat.py` which provides a small number of functions for querying users in a messaging group, messaging those users, and sending messages to a specific channel/room.
To add bindings for a new messaging system, subclass `Chat`.

### 2FA
2FA support is provided by `auth/auth.py`, which wraps async 2FA in a few functions that enable checking for 2FA capability, starting a 2FA session, and polling the state of the 2FA session.
We provide support for Duo Push via the Duo Auth API, but adding support for a different product or some in-house 2FA solution is as easy as creating a subclass of `Auth`.

### Task management
Task management is provided by `tasker/tasker.py` and the `Tasker` class.
Since alerts are logged in an SQL database, the provided Tasker is `SQLTasker`.
This provides support for grabbing new tasks and updating them via individual `Task` objects.

### Blacklists
Blacklists are handled by the SQL database, provided in `blacklist/blacklist.py` and the subclass `blacklist/sql_blacklist.py`.

### Users
The `User` object provides support for handling user state.
We keep track of whatever information a messaging system gives to us, but really only ever use a user's unique ID and username in order to contact them.

### Alerts
Alerts are uniquely identified by a SHA-256 hash which comes from some hash of the event that generated them.
We assume that a SHA-256 hash is sufficiently random for there to be no collisions.
If you encounter a SHA-256 collision, please contact someone at your nearest University and enjoy the fame and fortune it brings upon you.

## FAQ

Please ask us things

## Contributing
Contributors must abide by the [Dropbox Contributor License Agreement][cla].

## License

Copyright 2016 Dropbox, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.



[slack-blog]: https://slack.engineering/distributed-security-alerting-c89414c992d6 "Distributed Alerting"
[bot-user]: https://api.slack.com/bot-users "Slack Bot Users"
[auth-api]: https://duo.com/docs/authapi "Duo Auth API"
[cla]: https://opensource.dropbox.com/cla/ "Dropbox CLA"
