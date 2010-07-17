require 'capistrano'
require 'capistrano/cli'

#little hack to create a blank cap configuration if one does not exist
#so we can run rake tasks even without a cap config
if Thread.current[:capistrano_configuration].nil?
  Capistrano::Configuration.instance = Capistrano::Configuration.new
end

require 'timetoastdeploy/recipes.rb'