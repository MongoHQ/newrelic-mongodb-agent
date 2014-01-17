# New Relic+MongoDB Extension

A plugin to gather metrics from your MongoDB deployment and send the
metrics to the New Relic Platform.

## Requirements

While this project is gaining steam, you will need a base knowledge of
Ruby and Ruby Gems.  If you have this knowledge, and feel that you
breezed through the installation, please consider writing a tutorial for
others.  If you are lacking knowledge on the Ruby and Ruby gems
configuration, please post questions to the Issues section of the
project, and we will help as quickly as possible. 

## Metrics

Everyone loves metrics.  Everyone loves metrics beside their application
metrics.  The New Relic platform is a hit.

MongoDB will monitor the following metrics:

* Operations / Second
* RAM Usage
* Disk Size
* Lock %
* Page Faults

This extension will work for single servers, replica sets, and sharding.

## Using with Replica Sets and Sharding

To use with Replica Sets and Sharding, you will need to run one agent
per host being monitored.  In the future, we are planning to do
inspection and automated monitoring for complete environments.

## Base Installation and Configuration

Prior to installation, you will need to configure Ruby and Gems with `foreman`.  There are 

1. Download the latest release from (https://github.com/MongoHQ/newrelic-mongodb-agent/releases)
2. Copy `config/newrelic_plugin.yml.example` to `config/newrelic_plugin.yml` 
3. Modify `config/newrelic_plugin.yml` as required
3. Install required Ruby gems for the agent by running `bundle install` from the plugins parent directory.
4. Run `foreman start` OR `./new_relic_mongodb_agent` to run in the foreground for testing/debuggin and `./new_relic_mongodb_agent.daemon start` to run in the background.
5. See "MongoDB" on the left side of your New Relic screen with available metrics

*It is best not to run this with `sudo` or `root` privileges.  If you find permissions errors, please consider creating a `~/.gems` directory for an unprivileged user, and setting the `GEM_HOME=~.gems` evironmental variable.*

## Production Deployment Methods

Two (of many) methods for deploying this New Relic Platform plugin:

1. On Linux (with upstart)
2. On Linux (with using Daemons and/or Monit)
3. Heroku 

If you have documentation for other deployment methods, please submit a
pull request.

### On Host Deployment

Run the above steps on base installation and configuration.  Then, run:

`foreman export upstart /etc/init -a newrelic_mongodb`

This will create an upstart manageable process that will run on server
start.

### On Host Deployment using Monit

Using monit over upstart seems easier as the process can be monitored for status and resource usage rather that just system and manual starts.

`sudo apt-get install monit`

Example monit config:

```
# /etc/monit/conf.d/new_relic_mongodb_agent.conf
check process newrelic_mongodb_agent
  with pidfile /home/ubuntu/newrelic_mongodb_agent/newrelic_mongodb_agent.pid
  start program = "/bin/su - ubuntu -c '/home/ubuntu/newrelic_mongodb_agent/newrelic_mongodb_agent.daemon start'" with timeout 90 seconds
  stop program = "/bin/su - ubuntu -c '/home/ubuntu/newrelic_mongodb_agent/newrelic_mongodb_agent.daemon stop'" with timeout 90 seconds
  if totalmem is greater than 250 MB for 2 cycles then restart
  group newrelic_agent
```

### Heroku

For off sight manage of your resources, which is great "in the cloud".
If you are familure with Heroku, you can run

1. Clone this repo
2. Create a new heroku application: `git apps:create --app=<unique name>`
3. Make modifications to the `config/newrelic_plugin.yml` file from the
   template
4. Commit the change
5. Run `git push heroku master`
6. Add a full-time runner for the worker: `git ps:scale mongodb=2 --app=<unique name>`


## Requesting Changes

To request additions to the New Relic dashboard or platform, please
complete a Github issue with the errors, features, or dashboard changes.
The more information and diagrams you can provide the quicker and easier the
communication process will proceed.

If you know the error, and would like to make changes, we do accept pull
requests.
