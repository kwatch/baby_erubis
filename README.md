BabyErubis.rb
=============

$Release: 0.0.0 $

BabyErubis is an yet another eRuby implementation, based on Erubis.

* Small and fast
* Easy to customize
* Supports HTML as well as plain text
* Accepts both template file and template string

BabyErubis supports Ruby >= 1.8 and Rubinius >= 2.0.



Examples
========


Render template string:

    require 'baby_erubis'
    template = BabyErubis::Html.new.from_str <<'END', __FILE__, __LINE__+1
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
    templat = BabyErubis::Html.new.from_file('example.html.erb', 'utf-8')
    context = {:title=>'Example', :items=>['A', 'B', 'C']}
    output = template.render(context)
    print output


(Use `BabyErubis::Text` instead of `BabyErubis::Html` when rendering plain text.)


Command-line examples (see `baby_erubis.rb --help` for details):

    ## convert eRuby file into Ruby code
    $ baby_erubis -x   file.erb     # text
    $ baby_erubis -xH  file.erb     # html
    $ baby_erubis -X   file.erb     # embedded code only
    ## render eRuby file with context data
    $ baby_erubis -c '{items: [A, B, C]}'   file.erb    # YAML
    $ baby_erubis -c '@items=["A","B","C"]' file.erb    # Ruby
    $ baby_erubis -f data.yaml file.erb                 # or -f *.json, *.rb
    ## debug eRuby file
    $ baby_erubis -xH file.erb | ruby -wc     # check syntax error
    $ baby_erubis -XHNU file.erb              # show embedded ruby code



Template Syntax
===============

* `<% ... %>` : Ruby statement
* `<%= ... %>` : Ruby expression with escaping
* `<%== ... %>` : Ruby expression without escaping

Expression in `<%= ... %>` is escaped according to template class.

* `BabyErubis::Text` doesn't escape anything.
  It justs converts expression into a string.
* `BabyErubis::Html` escapes html special characters.
  It converts `< > & " '` into `&lt; &gt; &amp; &quot; &#39;` respectively.

(Experimental) `<%- ... -%>` and `<%-= ... -%>` are handled same as
`<% ... %>` and `<%= ... %>` respectively.



Advanced Topics
===============


Template Context
----------------

When rendering template, you can pass not only Hash object but also any object
as context values. Internally, rendering method converts Hash object into
`BabyErubis::TemplateContext` object automatically.

Example:

    require 'baby_erubis'

    class MyApp
      include BabyErubis::HtmlEscaper  # necessary to define escape()

      TEMPLATE = BabyErubis::Html.new.from_str <<-'END', __FILE__, __LINE__+1
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
        return TEMPLATE.render(self)   # use self as context object
      end

    end

    if __FILE__ == $0
      print MyApp.new('World').render()
    end


String#freeze()
---------------

BabyErubis supports String#freeze() automatically when on Ruby version >= 2.1.
And you can control whether to use freeze() or not.

    template_str = <<'END'
    <div>
    <b><%= message %></b>
    </div>
    END

    ## don't use freeze()
    t = BabyErubis::Text.new(:freeze=>false).from_str(template_str)
    print t.src
    # --- result ---
    # _buf = ''; _buf << '<div>
    # <b>'; _buf << (message).to_s; _buf << '</b>
    # </div>
    # '; _buf.to_s

    ## use freeze() forcedly
    t = BabyErubis::Text.new(:freeze=>true).from_str(template_str)
    print t.src
    # --- result ---
    # _buf = ''; _buf << '<div>
    # <b>'.freeze; _buf << (message).to_s; _buf << '</b>
    # </div>
    # '.freeze; _buf.to_s



Customizing
===========


Change Embed Pattern from '<% %>' to '{% %}'
--------------------------------------------

Sample code:

    require 'baby_erubis'

    class MyTemplate < BabyErubis::Html

      rexp = BabyErubis::Template::PATTERN
      PATTERN = Regexp.compile(rexp.to_s.sub(/<%/, '\{%').sub(/%>/, '%\}'))

      def pattern
        PATTERN
      end

    end

    template = MyTemplate.new <<-'END'
    {% for item in @items %}
    - {%= item %}
    {% end %}
    END

    print template.render(:items=>['A', 'B', 'C'])

Output:

    - A
    - B
    - C


Strip Spaces in HTML Template
-----------------------------

Sample code:

    require 'baby_erubis'

    class MyTemplate < BabyErubis::Html

      def parse(input, *args)
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

      LAYOUT = BabyErubis::Html.new.from_str <<-'END', __FILE__, __LINE__+1
        <html>
          <body>
            <% _buf << @_content %>    # or <%== @_content %>
          </body>
        </html>
      END

      TEMPLATE = BabyErubis::Html.new.from_str <<-'END', __FILE__, __LINE__+1
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


Template Cache File
-------------------

Sample code:

    require 'baby_erubis'
    require 'logger'

    $logger = Logger.new(STDERR)

    class MyTemplate < BabyErubis::Html

      def from_file(filename, encoding='utf-8')
        cachefile = "#{filename}.cache"
        timestamp = File.mtime(filename)
        has_cache = File.file?(cachefile) && File.mtime(cachefile) == timestamp
        if has_cache
          $logger.info("loading template from cache file: #{cachefile}")
          ruby_code = File.open(cachefile, "rb:#{encoding}") {|f| f.read }
          compile(ruby_code, filename, 1)
        else
          super(filename, encoding)
          $logger.info("creating template cache file: #{cachefile}")
          ruby_code = self.src
          tmpname = "#{cachefile}.#{rand().to_s[2,5]}"
          File.open(tmpname, "wb:#{encoding}") {|f| f.write(ruby_code) }
          File.utime(timestamp, timestamp, tmpname)
          File.rename(tmpname, cachefile)
        end
        return self
      end

    end

    p File.exist?('example.html.erb.cache')   #=> false
    t = MyTemplate.new.from_file('example.html.erb')
    p File.exist?('example.html.erb.cache')   #=> true



Todo
====

* Support Rails syntax (= `<%= form_for do |f| %>`)



Changes
=======

Release 0.1.0 (2014-05-06)
--------------------------

* Public release



License
=======

$License: MIT License $



Copyright
=========

$Copyright: copyright(c) 2014 kuwata-lab.com all rights reserved $
