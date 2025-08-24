# http://blog.blakesimpson.co.uk/read/80-sidekiq-tasks-for-capistrano-3

namespace :pumactl do
  task :start do
    on roles(:app) do
      execute :sudo, :systemctl, 'start puma'
    end
  end

  task :stop do
    on roles(:app) do
      execute :sudo, :systemctl, 'stop puma'
    end
  end

  task :status do
    on roles(:app) do
      execute :sudo, :systemctl, 'status puma'
    end
  end

  task 'phased-restart' do
    on roles(:app) do
      execute :sudo, :systemctl, 'reload puma'
    end
  end

  task :restart do
    on roles(:app) do
      execute :sudo, :systemctl, 'restart puma'
    end
  end
end