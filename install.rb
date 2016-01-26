Dir.chdir(File.dirname(__FILE__))

require 'rbconfig'
require 'fileutils'
include RbConfig

path = CONFIG["sitelibdir"]
FileUtils.mkdir_p(path)
file = path + "/dxruby.rb"
FileUtils.install("./lib/dxsdl2r.rb" , file, :preserve => true)

FileUtils.mkdir_p(path + "/" + "dxsdl2r")

Dir.chdir(File.dirname(__FILE__) + "/lib/dxsdl2r")
Dir.glob("./*.*").each do |name|
  file = path + "/dxsdl2r/" + name
  FileUtils.install(name , file, :preserve => true)
end
