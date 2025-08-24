server "216.128.137.144", port: 22, roles: [ :web, :app, :db ], primary: true

set :stage,     :production
set :branch,    :main
set :rails_env, :production
set :rack_env,  :production
set :puma_env,  :production
set :ssh_options, {
  forward_agent: true,
  user: "deploy",
  auth_methods: %w[publickey]
}
