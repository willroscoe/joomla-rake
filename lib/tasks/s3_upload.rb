# -*- mode: ruby -*-
# -*- coding: utf-8 -*-

##
# Get the S3 Credentials
def s3_credentials

  {
    :access_key_id => ENV['AWS_ACCESS_KEY_ID'] || $package['s3']['access_key_id'],
    :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'] || $package['s3']['secret_access_key'],
    :region => ENV['AWS_REGION'] || $package['s3']['region']
  }

end


desc 'Upload the package to S3'
task :upload => [:package] do

  require 'aws-sdk'
  s3 = Aws::S3::Client.new(s3_credentials)
  #bucket = s3.bucket(s3_bucket)

  package_files = [
           File.join( $package['s3']['path'] , package_name + '.zip'),
           File.join( $package['s3']['path'] , $package['name'] + '-latest.zip')
          ]

  package_files.each do |file|
    File.open(Pathname.new( File.join('.' , 'packages', package_name + '.zip' )), 'rb') do |f|
      s3.put_object(
        acl: 'public-read',
        body: f,
        bucket: s3_bucket,
        key: file,
      )
    end
  end

  s3.put_object(
    bucket: s3_bucket,
    key: File.join($package['s3']['path'] , 'updates.xml'),
    acl: 'public-read',
    body: update_manifest
    )

  p "Uploaded package #{package_name}.zip and update manifest to S3"

end


desc "Make a new Release (bump, package and upload)"
task :release => [:bump, :package, :upload]
