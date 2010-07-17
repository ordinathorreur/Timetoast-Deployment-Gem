Capistrano::Configuration.instance(:must_exist).load do
  
  set :nginx_server_name, nil
  set :domain, nil
  set :nginx_server_aliases, []
  set :nginx_binary, "/etc/init.d/nginx"
  set :proxy_port, 8000
  set :proxy_servers, 2
  set :proxy_address, "127.0.0.1"
  
  namespace :nginx do
    
    desc "Sets default environment variables"
    task :set_env do
      set :domain, application unless domain
      set :nginx_server_name, domain unless nginx_server_name
      set :nginx_vhost_available_conf, "/etc/nginx/sites-available/#{application}"
      set :nginx_vhost_enabled_conf, "/etc/nginx/sites-enabled/#{application}"
    end
    
    desc "Creates shared folder structure"
    task :shared, :roles => [:web] do      
      send(run_method, "mkdir -p #{shared_path}/public")
      #little hack to make sure there is document root when restarting nginx
      send(run_method, "ln -nfs #{shared_path} #{current_path}")
      send(run_method, "chown -R www-data:deploy #{shared_path}")
      send(run_method, "chmod -R g+w #{shared_path}")
    end
    
    task :vhost, :roles => [:web] do
      server_aliases = []
      server_aliases << "www.#{nginx_server_name}"
      server_aliases.concat nginx_server_aliases
      set :nginx_server_aliases_array, server_aliases
      
      file = File.join(File.dirname(__FILE__), "templates", vhost_template)
      template = File.read(file)
      buffer = ERB.new(template).result(binding)
      put buffer, "#{shared_path}/nginx.conf", :mode => 0444
      send(run_method, "cp #{shared_path}/nginx.conf #{nginx_vhost_available_conf}")
      send(run_method, "rm -f #{shared_path}/nginx.conf")
      send(run_method, "ln -nfs #{nginx_vhost_available_conf} #{nginx_vhost_enabled_conf}")
    end
    
    desc "Start Nginx "
    task :start, :roles => :web do
      sudo "#{nginx_binary} start"
    end
    
    desc "Restart Nginx "
    task :restart, :roles => :web do
      sudo "#{nginx_binary} restart"
    end
    
    desc "Stop Nginx "
    task :stop, :roles => :web do
      sudo "#{nginx_binary} stop"
    end
  end
  
  before 'nginx:vhost', 'nginx:set_env'
  after 'nginx:vhost', 'nginx:restart'
  
end