Capistrano::Configuration.instance(:must_exist).load do
  set :proxy_servers, 2
  set :proxy_port, 8000
  set :proxy_address, "127.0.0.1"
  set :proxy_environment, "production"
  
  set :mongrel_conf, nil
  set :mongrel_user, nil
  set :mongrel_group, nil
  set :mongrel_prefix, nil
  set :mongrel_rails, 'mongrel_rails'
  set :mongrel_clean, false
  set :mongrel_pid_file, nil
  set :mongrel_log_file, nil
  set :mongrel_config_script, nil
    namespace :mongrel do
      
      namespace :cluster do
        desc <<-DESC
        Configure Mongrel processes on the app server. This uses the :use_sudo
        variable to determine whether to use sudo or not. By default, :use_sudo is
        set to true.
        DESC
        task :configure, :roles => :app do
          set_mongrel_conf
          set_mongrel_pid_file
              
          argv = []
          argv << "#{mongrel_rails} cluster::configure"
          argv << "-N #{proxy_servers.to_s}"
          argv << "-p #{proxy_port.to_s}"
          argv << "-e #{proxy_environment}"
          argv << "-a #{proxy_address}"
          argv << "-c #{current_path}"
          argv << "-C #{mongrel_conf}"
          argv << "-P #{mongrel_pid_file}"
          argv << "-l #{mongrel_log_file}" if mongrel_log_file
          argv << "--user #{proxy_server_user}" if proxy_server_user
          argv << "--group #{proxy_server_group}" if proxy_server_group
          argv << "--prefix #{mongrel_prefix}" if mongrel_prefix
          argv << "-S #{mongrel_config_script}" if mongrel_config_script
          cmd = argv.join " "
          send(run_method, cmd)
        end
        
        desc <<-DESC
        Start Mongrel processes on the app server.  This uses the :use_sudo variable to determine whether to use sudo or not. By default, :use_sudo is
        set to true.
        DESC
        task :start, :roles => :app do
          set_mongrel_conf
          cmd = "#{mongrel_rails} cluster::start -C #{mongrel_conf}"
          cmd += " --clean" if mongrel_clean    
          send(run_method, cmd)
        end
        
        desc <<-DESC
        Restart the Mongrel processes on the app server by starting and stopping the cluster. This uses the :use_sudo
        variable to determine whether to use sudo or not. By default, :use_sudo is set to true.
        DESC
        task :restart, :roles => :app do
          set_mongrel_conf
          cmd = "#{mongrel_rails} cluster::restart -C #{mongrel_conf}"
          cmd += " --clean" if mongrel_clean    
          send(run_method, cmd)
        end
        
        desc <<-DESC
        Stop the Mongrel processes on the app server.  This uses the :use_sudo
        variable to determine whether to use sudo or not. By default, :use_sudo is
        set to true.
        DESC
        task :stop, :roles => :app do
          set_mongrel_conf
          cmd = "#{mongrel_rails} cluster::stop -C #{mongrel_conf}"
          cmd += " --clean" if mongrel_clean    
          send(run_method, cmd)
        end
        
        desc <<-DESC
        Check the status of the Mongrel processes on the app server.  This uses the :use_sudo
        variable to determine whether to use sudo or not. By default, :use_sudo is
        set to true.
        DESC
        task :status, :roles => :app do
          set_mongrel_conf
          send(run_method, "#{mongrel_rails} cluster::status -C #{mongrel_conf}")
        end
      end
    end
  def set_mongrel_conf
    set :mongrel_conf, "/etc/mongrel_cluster/#{application}.yml" unless mongrel_conf
  end

  def set_mongrel_pid_file
    set :mongrel_pid_file, "/var/run/mongrel_cluster/#{application}.pid" unless mongrel_pid_file
  end
end