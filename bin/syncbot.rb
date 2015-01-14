#!/usr/bin/env ruby

require 'rb-fsevent'
require 'open3'
require 'syncbot'

include Open3

options = { :latency => 2 }

host = "#{ENV['USER']}.dev.cloud.vitrue.com"
data_path = "/data/publisher"

# exclude patterns
exclude_patterns = %w(
  fsevent_rync.rb
  vendor/cache/***
  .*.swp
  log/***
  tmp/***
  public/media
  public/stylesheets/*.css
  public/stylesheets/jquery/*.css
  public/stylesheets/oocss/*.css
  public/stylesheets/legacy
  public/javascripts/apps/create_post_build/***
)

rsync_exclude_options = exclude_patterns.map { |p| "--exclude='#{p}'" }.join(' ')

rsync = "rsync -avzit --delete -e ssh #{rsync_exclude_options} . deploy@#{host}:#{data_path}"

def run_with_output command
  popen3(command) do |stdin, stdout, stderr|
    stdout.read.split("\n").map { |line|
      puts "rsync: #{line}"
    }
  end
end

# initialize the sync before monitoring
run_with_output rsync

# monitoring changes
fsevent = FSEvent.new
fsevent.watch Dir.pwd, options do |directories|
  puts "Detected change inside: #{directories.inspect}"
  run_with_output rsync
end
fsevent.run
