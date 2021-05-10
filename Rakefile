require 'bundler/setup'
require 'rake/clean'
require 'logger'

# `rake clean` removes all intermediate files just leaving generate site
CLEAN.concat FileList['data/**/*'] + FileList['tmp/**/*']

# `rake clobber` also removes the generated site
CLOBBER.concat FileList['build/**/*']

LOGGER = Logger.new STDOUT

desc "Create final site distribution"
task :dist do
  sh 'bundle exec middleman build'
end
