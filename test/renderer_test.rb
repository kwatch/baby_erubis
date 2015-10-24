# -*- coding: utf-8 -*-

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2014 kuwata-lab.com all rights reserved $
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

  ERUBY_TEMPLATE_DIR      = '_t'
  ERUBY_TEMPLATE_HTML_EXT = '.html.erb'
  ERUBY_TEMPLATE_TEXT_EXT = '.erb'

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
      obj = HelloClass.new(:items=>[10, 20, 30])
      actual = obj.eruby_render_html(:'welcome', layout: false)
      expected = <<'END'
<h1>Example</h1>
<ul>
  <li>10</li>
  <li>20</li>
  <li>30</li>
</ul>
END
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
      obj = HelloClass.new(:title=>"Homhom", :date=>"2015-01-01")
      actual = obj.eruby_render_text(:'example.text', layout: false)
      expected = <<'END'
title: Homhom
date:  2015-01-01
END
      assert_equal expected, actual
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
