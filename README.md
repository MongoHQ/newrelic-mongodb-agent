# New Relic+MongoDB Extension

A plugin to gather metrics from your MongoDB deployment and send the
metrics to the New Relic Platform.

## Requirements

While this project is gaining steam, you will need a base knowledge of
Ruby and Ruby Gems.  If you have this knowledge, and feel that you
breezed through the installation, please consider writing a tutorial for
others.  If you are lacking knowledge on the Ruby and Ruby gems
configuration, please post questions to the Issues second of the
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

1. Download the latest release from (https://github.com/MongoHQ/newrelic_mongodb_extension/tags)
2. Copy `config/template_newrelic_plugin.yml` to `config/newrelic_plugin.yml` 
3. Modify `config/newrelic_plugin.yml` as required
3. Install required Ruby gems for the agent by running `bundle install` from the plugins parent directory.
4. Run `foreman start` 
5. See "MongoDB" on the left side of your New Relic screen with available metrics

*It is best not to run this with `sudo` or `root` privileges.  If you find permissions errors, please consider creating a `~/.gems` directory for an unprivileged user, and setting the `GEM_HOME=~.gems` evironmental variable.*

## Production Deployment Methods

Two (of many) methods for deploying this New Relic Platform plugin:

1. On Linux (with upstart)
2. Heroku 

If you have documentation for other deployment methods, please submit a
pull request.

### On Host Deployment

Run the above steps on base installation and configuration.  Then, run:

`foreman export upstart /etc/init -a newrelic_mongodb`

This will create an upstart manageable process that will run on server
start.

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
