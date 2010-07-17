require 'yaml'
require 'capistrano'
require 'capistrano/cli'

module MySQLMethods
  
  def execute(sql, mysqluser)
    run "mysql --user=#{mysqluser} -p --execute=\"#{sql}\"" do |channel, stream, data|
      handle_mysql_password(mysqluser, channel, stream, data)
    end
  end
  
  private
  def handle_mysql_password(mysqluser, channel, stream, data)
    logger.info data, "[database on #{channel[:host]} asked for password]"
    if data =~ /^Enter password:/
      pass = Capistrano::CLI.password_prompt "Enter database password for '#{mysqluser}':"
      channel.send_data "#{pass}\n" 
    end
  end
end

Capistrano.plugin :mysql_helper, MySQLMethods

Capistrano::Configuration.instance(:must_exist).load do
  namespace :mysql do
    desc "Create MySQL database and user"
    task :setup, :roles => :db, :only => { :primary => true } do
      
      sql = "CREATE DATABASE #{db_name};"
      sql += "GRANT ALL PRIVILEGES ON #{db_name}.* TO #{db_user}@localhost IDENTIFIED BY '#{db_password}';"  
      mysql_helper.execute sql, "root"
    end
  end
  
end