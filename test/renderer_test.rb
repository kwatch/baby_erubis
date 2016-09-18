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
require 'baby_erubis/renderer'


class HelloClass
  include BabyErubis::HtmlEscaper
  include BabyErubis::Renderer

  ERUBY_PATH     = ['_t']
  ERUBY_HTML_EXT = '.html.erb'
  ERUBY_TEXT_EXT = '.erb'

  def initialize(vars={})
    vars.each do |k, v|
      instance_variable_set("@#{k}", v)
    end
  end

end


describe 'BabyErubis::Renderer' do

  layout_template = <<'END'
<!doctype>
<html>
  <head>
    <meta charset="utf-8" />
    <title><%= @page_title %></title>
  </head>
  <body>
    <div id="main" class="main">
<%== @_content %>
    </div>
  </body>
</html>
END

  html_template = <<'END'
<%
   @page_title = 'Example'
%>
<h1><%= @page_title %></h1>
<ul>
<% for x in @items %>
  <li><%= x %></li>
<% end %>
</ul>
END

  layout2_template = <<'END'
<%
  @_layout = true
%>
<section>
<%== @_content %>
</section>
END

  text_template = <<'END'
title: <%= @title %>
date:  <%= @date %>
END

  before do
    Dir.mkdir('_t')
    File.open('_t/_layout.html.erb', 'w') {|f| f.write(layout_template) }
    File.open('_t/_layout2.html.erb', 'w') {|f| f.write(layout2_template) }
    File.open('_t/welcome.html.erb', 'w') {|f| f.write(html_template) }
    File.open('_t/example.text.erb', 'w') {|f| f.write(text_template) }
  end

  after do
    Dir.glob('_t/*').each {|fpath| File.unlink(fpath) if File.file?(fpath) }
    Dir.rmdir('_t')
  end


  describe '#eruby_render_html()' do

    it "renders html template." do
      expected = <<'END'
<h1>Example</h1>
<ul>
  <li>10</li>
  <li>20</li>
  <li>30</li>
</ul>
END
      #
      obj = HelloClass.new(:items=>[10, 20, 30])
      actual = obj.eruby_render_html(:'welcome', layout: false)
      assert_equal expected, actual
      #
      obj = HelloClass.new(:items=>[10, 20, 30])
      actual = obj.eruby_render_html('welcome.html.erb', layout: false)
      assert_equal expected, actual
    end

    it "renders with layout template." do
      obj = HelloClass.new(:items=>[10, 20, 30])
      actual = obj.eruby_render_html(:'welcome', layout: :'_layout')
      expected = <<'END'
<!doctype>
<html>
  <head>
    <meta charset="utf-8" />
    <title>Example</title>
  </head>
  <body>
    <div id="main" class="main">
<h1>Example</h1>
<ul>
  <li>10</li>
  <li>20</li>
  <li>30</li>
</ul>

    </div>
  </body>
</html>
END
      assert_equal expected, actual
    end

  end


  describe '#eruby_render_text()' do

    it "renders text template" do
      expected = <<'END'
title: Homhom
date:  2015-01-01
END
      #
      obj = HelloClass.new(:title=>"Homhom", :date=>"2015-01-01")
      actual = obj.eruby_render_text(:'example.text', layout: false)
      assert_equal expected, actual
      #
      obj = HelloClass.new(:title=>"Homhom", :date=>"2015-01-01")
      actual = obj.eruby_render_text('example.text.erb', layout: false)
      assert_equal expected, actual
    end

  end


  describe '#_eruby_find_template()' do

    it "caches template object with timestamp." do
      cache = HelloClass.const_get :ERUBY_CACHE
      cache.clear()
      assert_equal 0, cache.length
      obj = HelloClass.new(:items=>[10, 20, 30])
      t1 = Time.now
      obj.eruby_render_html(:'welcome')
      t2 = Time.now
      assert_equal 2, cache.length
      tuple = cache['_t/welcome.html.erb']
      assert tuple.is_a?(Array)
      assert_equal 3, tuple.length
      assert_equal BabyErubis::HtmlTemplate, tuple[0].class
      assert_equal File.mtime('_t/welcome.html.erb'), tuple[1]
      assert t1 < tuple[2]
      assert t2 > tuple[2]
    end

    it "caches template object with timestamp." do
      cache = HelloClass.const_get :ERUBY_CACHE
      cache.clear()
      obj = HelloClass.new(:items=>[10, 20, 30])
      obj.eruby_render_html(:'welcome')
      tuple1 = cache['_t/welcome.html.erb']
      templ1 = tuple1[0]
      mtime1 = tuple1[1]
      #
      tstamp = Time.now - 30
      File.utime(tstamp, tstamp, '_t/welcome.html.erb')
      sleep(1.0)
      obj.eruby_render_html(:'welcome')
      tuple2 = cache['_t/welcome.html.erb']
      templ2 = tuple2[0]
      mtime2 = tuple2[1]
      assert templ1 != templ2
      assert mtime1 != mtime2
      assert templ2.is_a?(BabyErubis::HtmlTemplate)
      assert_equal tstamp.to_s, mtime2.to_s
    end

    it "raises BabyErubis::TempalteError when template file not found." do
      obj = HelloClass.new(:items=>[10, 20, 30])
      ex = assert_raises(BabyErubis::TemplateError) do
        obj.eruby_render_html(:'hello-homhom')
      end
      expected = "hello-homhom.html.erb: template not found in [\"_t\"]."
      assert_equal expected, ex.message
    end

  end


  describe '#_eruby_load_template()' do

    _prepare = proc {
      cache = HelloClass.const_get :ERUBY_CACHE
      cache.clear()
      obj = HelloClass.new(:items=>[10, 20, 30])
      obj.eruby_render_html(:'welcome')
      fpath = '_t/welcome.html.erb'
      ts = Time.now - 30
      File.utime(ts, ts, fpath)
      [cache, obj, fpath]
    }

    _render = proc {|cache, obj, fpath, n, expected|
      count = 0
      n.times do
        obj.eruby_render_html(:'welcome')
        if expected != cache[fpath]
          count += 1
          cache[fpath] = expected
        end
      end
      count
    }

    it "skips timestamp check in order to reduce syscall (= File.mtime())" do
      cache, obj, fpath = _prepare.call()
      #
      sleep(0.1)
      count = _render.call(cache, obj, fpath, 1000, cache[fpath])
      assert count == 0, "#{count} == 0: failed"
    end

    it "checks timestamp only for 5% request in order to avoid thundering herd" do
      cache, obj, fpath = _prepare.call()
      #
      sleep(0.6)
      count = _render.call(cache, obj, fpath, 1000, cache[fpath])
      assert count > 0,    "#{count} > 0: failed"
      assert count > 3,    "#{count} > 3: failed"
      assert count < 100,  "#{count} < 100: failed"
    end

    it "update last_checked in cache when file timestamp is not changed" do
      cache, obj, fpath = _prepare.call()
      _, _, old_last_checked = cache[fpath]
      #
      sleep(1.0)
      now = Time.now
      obj.eruby_render_html(:'welcome')
      _, _, new_last_checked = cache[fpath]
      assert_operator new_last_checked, :'!=', old_last_checked
      assert_operator (new_last_checked - old_last_checked), :'>=', 1.0
      assert_operator (new_last_checked - now), :'<', 0.001
    end

    it "remove cache entry when file timestamp is changed" do
      cache, obj, fpath = _prepare.call()
      #
      sleep(1.0)
      count = _render.call(cache, obj, fpath, 1000, cache[fpath])
      assert count == 1000, "#{count} == 1000: failed"
      #
      assert cache[fpath] != nil
      ret = obj.__send__(:_eruby_load_template, cache, fpath, Time.now)
      assert_nil ret
      assert_nil cache[fpath]
    end

  end


  describe '#_eruby_render_template()' do

    it "recognizes '@_layout' variable" do
      expected = <<'END'
<!doctype>
<html>
  <head>
    <meta charset="utf-8" />
    <title>Example</title>
  </head>
  <body>
    <div id="main" class="main">
<section>
<h1>Example</h1>
<ul>
  <li>10</li>
  <li>20</li>
  <li>30</li>
</ul>

</section>

    </div>
  </body>
</html>
END
      obj = HelloClass.new(:items=>[10,20,30])
      actual = obj.eruby_render_html(:'welcome', layout: :'_layout2')
      assert_equal expected, actual
    end

  end


end
