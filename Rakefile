require 'rubygems'
require 'rake'
require 'echoe'

Echoe.new('timetoastdeploy', '0.1.0') do |p|
  p.description    = "Timetoast deployment recipes."
  p.url            = "http://timetoast.com"
  p.author         = "Daniel Todd"
  p.email          = "todddaniel@gmail.com"
  p.ignore_pattern = ["tmp/*", "script/*"]
  p.development_dependencies = []
end

Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each { |ext| load ext }
