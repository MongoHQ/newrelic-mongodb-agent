#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"
require "newrelic_plugin"
require "mongo"

include Mongo

module NewRelic::MongodbAgent

  class Agent < NewRelic::Plugin::Agent::Base
    agent_guid "com.mongohq.mongo-agent"
    agent_config_options :endpoint, :username, :password, :database, :port, :agent_name, :ssl
    agent_human_labels("MongoDB") { "#{agent_name}" }
    agent_version '2.4.4-3'

    def setup_metrics
      self.port ||= 27017 
      self.agent_name ||= "#{endpoint}:#{port}/#{database}"
    end

    def poll_cycle
      stats = mongodb_server_stats()
      db_stats = mongodb_db_stats()

      #Network metrics
      report_counter_metric("Network/Bytes Out", "bytes/sec", stats["network"]["bytesOut"])
      report_counter_metric("Network/Bytes In", "bytes/sec", stats['network']['bytesIn'])
      report_counter_metric("Network/Requests", "requests/sec", stats['network']['numRequests'])

      # Ops counters
      report_counter_metric("Opcounters/Insert", "inserts",    stats['opcounters']['insert'])      
      report_counter_metric("Opcounters/Query", "queries",     stats['opcounters']['query'])      
      report_counter_metric("Opcounters/Update", "updates",    stats['opcounters']['update'])
      report_counter_metric("Opcounters/Delete", "deletes",    stats['opcounters']['delete'])
      report_counter_metric("Opcounters/GetMore", "getmores",  stats['opcounters']['getmore'])
      report_counter_metric("Opcounters/Command", "commands",  stats['opcounters']['command'])  

      # Faults and assertions 
      report_counter_metric("Extra/Page Faults", "pagefaults/sec",  stats['extra_info']['page_faults'])
      report_counter_metric("Asserts/Regular",           "regular",         stats['asserts']['regular'])
      report_counter_metric("Asserts/Warning",           "warning",         stats['asserts']['warning'])
      report_counter_metric("Asserts/Msg",               "msg",             stats['asserts']['msg'])
      report_counter_metric("Asserts/User",              "user",            stats['asserts']['user'])

      # Connection metrics
      report_metric("Connections/Current",                "current",         stats['connections']['current'])
      report_metric("Connections/Available",              "available",       stats['connections']['available'])
      report_counter_metric("Connections/Total Created",  "connections/sec", stats['connections']['totalCreated'])

      # Cursor metrics
      report_metric("Cursors/Total Open",        "open",            stats['cursors']['totalOpen'])
      report_metric("Cursors/Client Cursors",    "size",            stats['cursors']['clientCursors_size'])
      report_metric("Cursors/Timed Out",         "timedout",        stats['cursors']['timedOut'])

      # DBStats metrics
      report_metric("DBStats/dataSize/Data Size",  "bytes",         db_stats['dataSize'])
      report_metric("DBStats/dataSize/Index Size", "bytes",         db_stats['indexSize'])
      report_metric("DBStats/Objects",             "Objects",       db_stats['objects'])
      report_metric("DBStats/Collections",         "Collections",   db_stats['collections'])
      report_metric("DBStats/Average Object Size", "Size",          db_stats['avgObjSize'])

      # Memory metrics retrived in MB from MongoDB, converted to bytes for New Relic graphing
      report_metric("Memory/Resident",             "bytes",            stats['mem']['resident'] * 1024 * 1024)
      report_metric("Memory/Virtual",              "bytes",            stats['mem']['virtual'] * 1024 * 1024)
      report_metric("Memory/Mapped",               "bytes",            stats['mem']['mapped'] * 1024 * 1024)
      report_metric("Memory/Mapped with Journal",  "bytes",            stats['mem']['mappedWithJournal'] * 1024 * 1024)

      # Locks
      report_lock_counter_metric("Locks/Global/Lock",              "%",         stats, "globalLock|lockTime")
      report_lock_counter_metric("Locks/DB/Read Locked",           "%",         stats, "locks|#{database}|timeLockedMicros|r")
      report_lock_counter_metric("Locks/DB/Write Locked",          "%",         stats, "locks|#{database}|timeLockedMicros|w")
      report_lock_counter_metric("Locks/DB/Acquiring Read Lock",   "%",         stats, "locks|#{database}|timeAcquiringMicros|r")
      report_lock_counter_metric("Locks/DB/Acquiring Write Lock",  "%",         stats, "locks|#{database}|timeAcquiringMicros|w")

      # Queues
      report_metric("Queue/Current Readers",       "reads",         stats['globalLock']['currentQueue']['readers'])
      report_metric("Queue/Current Writers",       "writes",        stats['globalLock']['currentQueue']['writers'])

      @prior = stats
    rescue => e
      $stderr.puts "#{e}: #{e.backtrace.join("\n   ")}"
    end

    def client
      @client ||= begin
                    client = MongoClient.new(endpoint, port.to_i, :slave_ok => true, :ssl => ssl || false)

                    unless username.nil?
                      client.db("admin").authenticate(username, password)
                      client.db(database)
                    else
                      client.db(database)
                    end
                  end
    rescue Mongo::AuthenticationError
      $stderr.puts "Error authententicating to MongoDB database.  Requires a user on the admin database"
      exit 1
    rescue Mongo::ConnectionFailure
      $stderr.puts "Error connecting to host port provided: #{endpoint}:#{port}"
      exit 1
    end

    def mongodb_server_stats
      client.command('serverStatus' => 1)
    end

    def mongodb_db_stats
      if !@client_stats.nil? && @client_stats_retrieved_at < Time.now - (60 * 60) # only retrieve size stats once / hour
        @client_stats
      else
        @client_stats_retrieved_at = Time.now
        @client_stats = client.stats
      end
    end

    def report_counter_metric(metric, type, value)
      @counter_metrics ||= {}

      if @counter_metrics[metric].nil?
        @counter_metrics[metric] = NewRelic::Processor::EpochCounter.new
      end

      report_metric(metric, type, @counter_metrics[metric].process(value))
    end

    def report_lock_counter_metric(metric, type, stats, path)
      current_value = path.split(/\|/).inject(stats) { |v,p| v[p] }

      if @prior
        prior_value   = path.split(/\|/).inject(@prior) { |v,p| v[p] }
        uptimeMillis  = (stats["uptimeMillis"] - @prior["uptimeMillis"]) * 1.0

        lockRatio = (current_value - prior_value) / uptimeMillis / (uptimeMillis / 1000)

        report_metric(metric, type, lockRatio)
      end
    end

  end

  #
  # Register this agent.
  #
  NewRelic::Plugin::Setup.install_agent :mongodb, self

  #
  # Launch the agent; this never returns.
  #
  NewRelic::Plugin::Run.setup_and_run

end
