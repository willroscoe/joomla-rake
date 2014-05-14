# -*- coding: utf-8 -*-
require_relative 'helpers'


def next_verison(current_version)
  # Semantic Versioning Bump
  v = current_version.split '.'
  
  # Increase PATCH version
  v[-1] = v[-1].to_i + 1

  v.join '.'
end

def bump_version
  version_file = File.read("./package.yml")
  old_version_line = old_file[/^\s{4}version\s*.*$/]
  new_version = next_version($package.version)
  
  version_file.sub!( old_version_line , "    version: #{new_version}")
  
  File.write("./package.yml", version_file)

  new_version
end

task :bump do |t|
  puts "Version upgrade: #{version_name} → #{bump_version}"
end
