Capistrano::Configuration.instance(:must_exist).load do
  
  set :rails_env, "production"
  
  set :proxy_port, 8000
  set :proxy_servers, 2
  set :proxy_server_type, "mongrel"
  set :proxy_server_user, proxy_server_type
  set :proxy_server_group, "deploy"
  
  set :web_server_type, "nginx"
  
namespace :ror do
    
    task :set_env do
      set :vhost_template, "ror_#{web_server_type}_vhost.erb"
    end
    
    task :ownership, :roles => [:app] do
       send(run_method, "chown -R #{proxy_server_user}:#{proxy_server_group} #{release_path}")
       send(run_method, "chown -R #{proxy_server_user}:#{proxy_server_group} #{shared_path}")
    end
    
    namespace :symlinks do
  
      desc "Setup application symlinks in the public"
      task :setup, :roles => [:app, :web] do
        if app_symlinks
          app_symlinks.each { |link| run "mkdir -p #{shared_path}/public/#{link}" }
        end
      end

      desc "Link public directories to shared location."
      task :update, :roles => [:app, :web] do
        if app_symlinks
          app_symlinks.each { |link| run "ln -nfs #{shared_path}/public/#{link} #{current_path}/public/#{link}" }
        end
      end
  
    end #end synmlinks
    
    namespace :config do
      
      task :default do
        begin
          #db.setup
        rescue
          puts "db:setup failed!"
        end
        app.setup
        # Call correct rake task depending on the web server type e.g. nginx, apache etc
        case web_server_type
          when 'nginx'
            nginx.shared
            nginx.vhost
          when 'apache'
            #apache.shared
            #apache.vhost
        end #end default
        
      end #end config
      
    
      namespace :app do
      
        desc 'Setup rails server'
        task :setup, :roles => :app  do
          set :rails_server_environment, rails_env
          set :proxy_server_port, proxy_port
          set :proxy_server_user, user unless proxy_server_user
          set :proxy_server_group, proxy_server_user unless proxy_server_group

          case proxy_server_type
          when 'mongrel'
            mongrel.cluster.configure
          when 'thin'
            thin.cluster.configure
          end
          
        end #end setup
        
      end #end app
      
      namespace :db do
      
        desc "Setup database server."
        task :setup, :roles => :db, :only => { :primary => true } do
          db_config = YAML.load_file('config/database.yml')
          set :db_user, db_config[rails_env]["username"]
          set :db_password, db_config[rails_env]["password"] 
          set :db_name, db_config[rails_env]["database"]
          set :db_host, "localhost"
          set :db_charset, "utf8"
          mysql.setup
        end
      end
      
    end
   
  end

    
  namespace :deploy do
    
      desc <<-DESC
      Start the rails server processes on the app server.
      DESC
      task :start, :roles => :app do
        case proxy_server_type
        when 'mongrel'
          mongrel.cluster.start
        when 'thin'
          thin.cluster.start
        end
      end
    
      desc <<-DESC
      Restart the rails server processes on the app server.
      DESC
      task :restart, :roles => :app do
        case proxy_server_type
        when 'mongrel'
          mongrel.cluster.restart
        when 'thin'
          thin.cluster.restart
        end
      end
    
      desc <<-DESC
      Stop the rails server processes on the app server.
      DESC
      task :stop, :roles => :app do
        case proxy_server_type
        when 'mongrel'
          mongrel.cluster.stop
        when 'thin'
          thin.cluster.stop
        end
      end
    
  end
    
  before  'deploy:setup', 'ror:set_env'
  after   'deploy:setup', 'ror:config'
  before  'deploy:update_code', 'ror:symlinks:setup'
  after   'deploy:symlink', 'ror:symlinks:update'
  after   'deploy:symlink', 'ror:ownership'
  after   :deploy,'deploy:cleanup'
  
end