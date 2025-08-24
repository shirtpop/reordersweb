# Change these
set :repo_url,        "git@github.com:shirtpop/reordersweb.git"
set :application,     "reordersweb"
set :user,            "deploy"
set :puma_threads,    [ 4, 16 ]
set :puma_workers,    0

# Don't change these unless you know what you're doing
set :pty,             true
set :use_sudo,        false
set :stage,           :production
set :deploy_via,      :remote_cache
set :deploy_to,       "/home/#{fetch(:user)}/apps/#{fetch(:application)}"
set :puma_bind,       "unix://#{shared_path}/tmp/sockets/#{fetch(:application)}-puma.sock"
set :puma_state,      "#{shared_path}/tmp/pids/puma.state"
set :puma_pid,        "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.error.log"
set :puma_error_log,  "#{release_path}/log/puma.access.log"
set :ssh_options,     { forward_agent: true, user: fetch(:user), keys: %w[~/.ssh/id_rsa.pub] }
set :puma_preload_app, true
set :puma_worker_timeout, nil
set :puma_init_active_record, true # Change to false when not using ActiveRecord

## Defaults:
# set :scm,           :git
# set :branch,        :master
# set :format,        :pretty
# set :log_level,     :debug
set :keep_releases, 1
set :sitemap_roles, :web # default

## Linked Files & Directories (Default None):
set :linked_files, %w[config/google_client_secret.json config/google_token.yaml]
# set :linked_dirs,  %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

namespace :deploy do
  desc "Initial Deploy"
  task :initial do
    on roles(:app) do
      before "deploy:restart", "pumactl:start"
      invoke "deploy"
    end
  end

  desc "Create Directories for Puma Pids and Socket"
  task :make_dirs do
    on roles(:app) do
      execute "mkdir #{shared_path}/tmp/sockets -p"
      execute "mkdir #{shared_path}/tmp/pids -p"
    end
  end

  desc "Restart application"
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      invoke "pumactl:restart"
    end
  end

  desc "Cleanup old assets"
  task :clear_assets do
    on roles(:app) do
      within release_path do
        execute :rm, "-rf", "public/assets/*"
      end
    end
  end

  after  :finishing,    :compile_assets
  after  :finishing,    :cleanup
  # after  :finishing,    'sitemap:refresh'
  after  :finishing,    :restart
  before :started, :make_dirs
  before :compile_assets, :clear_assets
end
