Capistrano::Configuration.instance(:must_exist).load do
  set :proxy_servers, 2
  set :proxy_port, 8000
  set :proxy_address, "127.0.0.1"
  set :proxy_environment, "production"
  
  set :thin_conf, nil
  set :thin_user, nil
  set :thin_group, nil
  set :thin_prefix, nil
  set :thin_rails, 'thin'
  set :thin_pid_file, nil
  set :thin_log_file, nil
  set :thin_config_script, nil
  
  namespace :thin do
    
    namespace :cluster do
      desc <<-DESC
      Configure Thin processes on the app server. This uses the :use_sudo
      variable to determine whether to use sudo or not. By default, :use_sudo is
      set to true.
      DESC
      task :configure, :roles => :app do
        set_thin_conf
        set_thin_pid_file
        
        argv = []
        argv << "#{thin_rails} config"
        argv << "-s #{proxy_servers.to_s}"
        argv << "-p #{proxy_port.to_s}"
        argv << "-e #{proxy_environment}"
        argv << "-a #{proxy_address}"
        argv << "-c #{current_path}"
        argv << "-C #{thin_conf}"
        argv << "-P #{thin_pid_file}"
        argv << "-l #{thin_log_file}" if thin_log_file
        argv << "--user #{proxy_server_user}" if proxy_server_user
        argv << "--group #{proxy_server_group}" if proxy_server_group
        argv << "--prefix #{thin_prefix}" if thin_prefix
        argv << "-C #{thin_config_script}" if thin_config_script
        cmd = argv.join " "
        send(run_method, cmd)
      end
      
      desc <<-DESC
      Start Thin processes on the app server.  This uses the :use_sudo variable to determine whether to use sudo or not. By default, :use_sudo is
      set to true.
      DESC
      task :start, :roles => :app do
        set_thin_conf
        cmd = "#{thin_rails} start -C #{thin_conf}"
        send(run_method, cmd)
      end
      
      desc <<-DESC
      Restart the Thin processes on the app server by starting and stopping the cluster. This uses the :use_sudo
      variable to determine whether to use sudo or not. By default, :use_sudo is set to true.
      DESC
      task :restart, :roles => :app do
        set_thin_conf
        cmd = "#{thin_rails} restart -C #{thin_conf}"
        send(run_method, cmd)
      end
      
      desc <<-DESC
      Stop the Thin processes on the app server.  This uses the :use_sudo
      variable to determine whether to use sudo or not. By default, :use_sudo is
      set to true.
      DESC
      task :stop, :roles => :app do
        set_thin_conf
        cmd = "#{thin_rails} stop -C #{thin_conf}"
        send(run_method, cmd)
      end

    end #end cluster
  end #end thin
    
  def set_thin_conf
    set :thin_conf, "/etc/thin/#{application}.yml" unless thin_conf
  end

  def set_thin_pid_file
    set :thin_pid_file, "/var/run/thin/#{application}.pid" unless thin_pid_file
  end
end