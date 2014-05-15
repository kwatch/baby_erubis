#!/usr/bin/ruby

###
### $Release: 0.0.0 $
### $License: MIT License $
### $Copyright: copyright(c) 2014 kuwata-lab.com all rights reserved $
###

require 'rubygems'

Gem::Specification.new do |s|
  ## package information
  s.name        = "baby_erubis"
  s.author      = "makoto kuwata"
  s.email       = "kwa(at)kuwata-lab.com"
  s.version     = "$Release: 0.0.0 $".split()[1]
  s.platform    = Gem::Platform::RUBY
  s.homepage    = "https://github.com/kwatch/BabyErubis/tree/ruby"
  s.summary     = "yet another eRuby implementation based on Erubis"
  s.description = <<'END'
BabyErubis is an yet another eRuby implementation, based on Erubis.

* Small and fast
* Supports HTML as well as plain text
* Accepts both template file and template string
* Easy to customize

BabyErubis support Ruby 1.9 or higher, and will work on 1.8 very well.
END

  ## files
  files = []
  files += Dir.glob('lib/*.rb')
  files += Dir.glob('test/*.rb')
  files += ['bin/baby_erubis']
  files += %w[README.md MIT-LICENSE setup.rb baby_erubis.gemspec Rakefile]
  s.files       = files
  s.executables = ['baby_erubis']
  s.bindir      = 'bin'
  s.test_file   = 'test/run_all.rb'
end
