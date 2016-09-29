server '', roles: [:web, :app, :db], primary: true
set :repo_url,        ''
set :application,     ''
set :user,            ''
set :puma_threads,    [4, 16]
set :puma_workers,    0
set :rvm_ruby_version, '2.1.1@dataplatform'

## Defaults:
set :stage,           :production
set :scm,             :git
set :branch,          :master
# set :format,        :pretty
# set :log_level,     :debug

# Don't change these unless you know what you're doing
set :pty,             false
set :use_sudo,        false
set :deploy_via,      :remote_cache
set :deploy_to,       "/path/to/app/#{fetch(:application)}"
set :puma_bind,       "unix://#{shared_path}/tmp/sockets/#{fetch(:application)}-puma.sock"
set :puma_state,      "#{shared_path}/tmp/pids/puma.state"
set :puma_pid,        "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.error.log"
set :puma_error_log,  "#{release_path}/log/puma.access.log"
set :ssh_options,     { forward_agent: true, user: fetch(:user) }
set :puma_preload_app, true
set :puma_worker_timeout, nil
set :puma_init_active_record, true  # Change to false when not using ActiveRecord

set :sidekiq_role, :app
set :sidekiq_env, 'production'
set :sidekiq_log,  "#{release_path}/log/sidekiq.log"
