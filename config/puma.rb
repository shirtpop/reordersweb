plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]
threads ENV["RAILS_MIN_THREADS"], ENV["RAILS_MAX_THREADS"]
workers ENV["WEB_CONCURRENCY"]
preload_app!
port ENV.fetch("PORT", 3000)
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]
plugin :tmp_restart
