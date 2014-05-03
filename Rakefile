# -*- coding: utf-8 -*-

###

RELEASE   = '0.0.1'
COPYRIGHT = 'copyright(c) 2014 kuwata-lab.com all rights reserved'
LICENSE   = 'MIT License'

###

task :default => :test

def edit_content(content)
  s = content
  s = s.gsub /\$Release\:.*?\$/,   "$Release\: #{RELEASE} $"
  s = s.gsub /\$Copyright\:.*?\$/, "$Copyright\: #{COPYRIGHT} $"
  s = s.gsub /\$License\:.*?\$/,   "$License\: #{LICENSE} $"
  s = s.gsub /\$Release\$/,   RELEASE
  s = s.gsub /\$Copyright\$/, COPYRIGHT
  s = s.gsub /\$License\$/,   LICENSE
  s
end


desc "run test scripts"
task :test do
  sh "ruby -r minitest/autorun test/*_test.rb"
end


desc "copy files into 'dist/#{RELEASE}'"
task :dist do
  spec_src = File.open('baby_erubis.gemspec') {|f| f.read }
  spec = eval spec_src
  dir = "dist/#{RELEASE}"
  rm_rf dir
  mkdir_p dir
  sh "tar cf - #{spec.files.join(' ')} | (cd #{dir}; tar xvf -)"
  spec.files.each do |fpath|
    #filepath = File.join(dir, fpath)
    #content = File.open(filepath, 'rb:utf-8') {|f| f.read }
    #new_content = edit_content(content)
    #File.open(filepath, 'wb:utf-8') {|f| f.write(new_content) }
    content = File.open(File.join(dir, fpath), 'r+b:utf-8') do |f|
      content = f.read
      new_content = edit_content(content)
      f.rewind()
      f.truncate(0)
      f.write(new_content)
    end
  end
end


desc "create rubygem pacakge"
task :package => :dist do
  chdir "dist/#{RELEASE}" do
    sh "gem build *.gemspec"
  end
  mv Dir.glob("dist/#{RELEASE}/*.gem"), 'dist'
end
