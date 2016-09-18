# -*- coding: utf-8 -*-

###
### $Release: 2.2.0 $
### $Copyright: copyright(c) 2014-2016 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

libpath = File.class_eval { join(dirname(dirname(__FILE__)), 'lib') }
$: << libpath unless $:.include?(libpath)

require 'minitest/autorun'

require 'baby_erubis'



describe 'BabyErubis::TemplateContext' do

  let(:ctx) { BabyErubis::TemplateContext.new }


  describe '#initialize()' do

    it "[!p69q1] takes hash object and sets them into instance variables." do
      ctx = BabyErubis::TemplateContext.new(:x=>10, :y=>20)
      assert_equal 10, ctx.instance_variable_get('@x')
      assert_equal 20, ctx.instance_variable_get('@y')
      assert_equal [:@x, :@y], ctx.instance_variables
    end

    it "[!p853f] do nothing when vars is nil." do
      ctx = BabyErubis::TemplateContext.new(nil)
      assert_equal [], ctx.instance_variables
    end

  end


  describe '#[]' do

    it "returns context value." do
      ctx = BabyErubis::TemplateContext.new(:x=>10)
      assert_equal 10, ctx[:x]
    end

  end


  describe '#[]=' do

    it "returns context value." do
      ctx = BabyErubis::TemplateContext.new
      ctx[:y] = 20
      assert_equal 20, ctx[:y]
    end

  end


  describe '#escape()' do

    it "converts any value into string." do
      assert_equal '10',   ctx.escape(10)
      assert_equal 'true', ctx.escape(true)
      assert_equal '',     ctx.escape(nil)
      assert_equal '["A", "B"]', ctx.escape(['A', 'B'])
    end

    it "does not escape html special chars." do
      assert_equal '<>&"',   ctx.escape('<>&"')
    end

  end


end



describe 'BabyErubis::HtmlTemplateContext' do

  let(:ctx) { BabyErubis::HtmlTemplateContext.new }


  describe '#escape()' do

    it "escapes html special chars." do
      assert_equal '&lt;&gt;&amp;&quot;&#39;', ctx.__send__(:escape, '<>&"\'')
      assert_equal '&lt;a href=&quot;?x=1&amp;y=2&amp;z=3&quot;&gt;click&lt;/a&gt;',
                   ctx.__send__(:escape, '<a href="?x=1&y=2&z=3">click</a>')
    end

  end


end
