require 'timetoastdeploy/recipes/mysql'
require 'timetoastdeploy/recipes/nginx'
require 'timetoastdeploy/recipes/mongrel'

Capistrano::Configuration.instance(:must_exist).load do
  
  default_run_options[:pty] = true
  set :keep_releases, 3
  set :app_symlinks, nil
  set :use_sudo, true
  
end