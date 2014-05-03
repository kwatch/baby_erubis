BabyErubis.rb
=============

$Release: 0.0.0 $

BabyErubis.rb is an yet another eRuby implementation, based on Erubis.

* Small and fast
* Easy to customize
* Supports HTML as well as plain text
* Accepts both template file and template string

BabyErubis.rb support Ruby 1.9 or higher.



Examples
========


Render template string:

    require 'baby_erubis'
    template = BabyErubis::Html.new <<'END', __FILE__, __LINE__+1
      <h1><%= @title %></h1>
      <% for item in @items %>
        <p><%= item %></p>
      <% end %>
    END
    context = {:title=>'Example', :items=>['A', 'B', 'C']}
    output = template.render(context)
    print output


Render template file:

    require 'baby_erubis'
    templat = BabyErubis::Html.load('example.html.erb', 'utf-8')
    context = {:title=>'Example', :items=>['A', 'B', 'C']}
    output = template.render(context)
    print output



Template Syntax
===============

* <% ... %> : Ruby statement
* <%= ... %> : Ruby expression with escaping
* <%== ... %> : Ruby expression without escaping

Expression in `<%= ... %>` is escaped according to template class.

* `BabyErubis::Text` doesn't escape anything.
  It justs converts expression into a string.
* `BabyErubis::Html` escapes html special characters.
  It converts '< > & " \'' into '&lt; &gt; &amp; &quot; &#39;' respectively.



Template Context
================

When rendering template, you can pass not only Hash object but also any object
as context values. Internally, rendering method converts Hash object into
`BabyErubis::TemplateContext` object automatically.

Example:

    require 'baby_erubis'

    class MyApp
      include BabyErubis::HtmlEscaper  # necessary to define escape()

      TEMPLATE = BabyErubis::Html.new <<-'END', __FILE__, __LINE__+1
        <html>
          <body>
            <p>Hello <%= @name %>!</p>
          </body>
        </html>
      END

      def initialize(name)
        @name = name
      end

      def render()
        return TEMPLATE.render(self)
      end

    end

    if __FILE__ == $0
      print MyApp.new('World').render()
    end



Customizing
============


Strip Spaces in HTML Template
-----------------------------

Sample code:

    require './lib/baby_erubis'

    class MyTemplate < BabyErubis::Html

      def convert(input, *args)
        stripped = input.gsub(/^[ \t]+</, '<')
        return super(stripped, *args)
      end

    end

    template = MyTemplate.new <<-'END'
      <html>
        <body>
          <p>Hello <%= @name %>!</p>
        </body>
      </html>
    END

    print template.render(:name=>"Hello")

Output:

    <html>
    <body>
    <p>Hello Hello!</p>
    </body>
    </html>


Layout Template
---------------

Sample code:

    require 'baby_erubis'

    class MyApp
      include BabyErubis::HtmlEscaper  # necessary to define escape()

      LAYOUT = BabyErubis::Html.new <<-'END', __FILE__, __LINE__+1
        <html>
          <body>
            <% _buf << @_content %>    # or <%== @_content %>
          </body>
        </html>
      END

      TEMPLATE = BabyErubis::Html.new <<-'END', __FILE__, __LINE__+1
        <p>Hello <%= @name %>!</p>
      END

      def initialize(name)
        @name = name
      end

      def render()
        @_content = TEMPLATE.render(self)
        return LAYOUT.render(self)
      end

    end

    if __FILE__ == $0
      print MyApp.new('World').render()
    end

Output:

      <html>
        <body>
              <p>Hello World!</p>
        </body>
      </html>



License
=======

$License: MIT License $



Copyright
=========

$Copyright: copyright(c) 2014 kuwata-lab.com all rights reserved $
