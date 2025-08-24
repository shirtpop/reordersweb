server '216.128.137.144', port: 22, roles: [:web, :app, :db], primary: true

set :stage,     :staging
set :branch,    :staging
set :rails_env, :staging
set :rack_env,  :staging
set :puma_env,  :staging
set :ssh_options, {
  forward_agent: true,
  user: 'deploy',
  auth_methods: %w[publickey],
  keys: %w[~/.ssh/shirtpop]
}