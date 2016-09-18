# -*- coding: utf-8 -*-

###
### $Release: 2.2.0 $
### $Copyright: copyright(c) 2014-2016 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

here = File.dirname(File.expand_path(__FILE__))
Dir.glob(here + '/**/*_test.rb').each do |fpath|
  require fpath
end
