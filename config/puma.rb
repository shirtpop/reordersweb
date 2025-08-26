plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 4 }
threads threads_count, threads_count
workers ENV.fetch("WEB_CONCURRENCY") { 1 }
preload_app!
port ENV.fetch("PORT", 3000)
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]
plugin :tmp_restart
