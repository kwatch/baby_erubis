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


describe BabyErubis::Template do

  let(:template) { BabyErubis::Text.new() }

  def _modify(ruby_code)
    if (''.freeze).equal?(''.freeze)
      return ruby_code.gsub(/([^'])';/m, "\\1'.freeze;")
    else
      return ruby_code
    end
  end


  describe '#parse()' do

    it "[!118pw] parses template string into ruby code." do
      input = <<'END'
title: <%= @title %>
items:
<% for item in @items %>
  - <%= item %>
<% end %>
END
      expected = <<'END'
_buf = ''; _buf << 'title: '; _buf << (@title).to_s; _buf << '
'; _buf << 'items:
'; for item in @items;
 _buf << '  - '; _buf << (item).to_s; _buf << '
'; end;
 _buf.to_s
END
      expected = _modify(expected)
      code = template.parse(input)
      assert_equal expected, code
    end

    it "[!7ht59] escapes single quotation and backslash characters." do
      input = <<'END'
who's who?
'''
\w
\\\
END
      expected = <<'END'
_buf = ''; _buf << 'who\'s who?
\'\'\'
\\w
\\\\\\
'; _buf.to_s
END
      expected = _modify(expected)
      assert_equal expected, template.parse(input)
    end

    it "[!u93y5] appends embedded expression in '<%= %>'." do
      input = <<'END'
x = <%= x %>
END
      expected = <<'END'
_buf = ''; _buf << 'x = '; _buf << (x).to_s; _buf << '
'; _buf.to_s
END
      expected = _modify(expected)
      assert_equal expected, template.parse(input)
    end

    it "[!auj95] appends embedded expression in '<%= %>' without escaping." do
      input = <<'END'
x = <%== x %>
END
      expected = <<'END'
_buf = ''; _buf << 'x = '; _buf << (x).to_s; _buf << '
'; _buf.to_s
END
      expected = _modify(expected)
      assert_equal expected, template.parse(input)
    end

    it "[!qveql] appends linefeeds when '<%# %>' found." do
      input = <<'END'
<%#
  for x in xs
%>
x = <%#=
  x
 %>
<%#
  end
%>
END
      expected = <<'END'
_buf = '';

 _buf << '
'; _buf << 'x = ';

 _buf << '
';

 _buf << '
'; _buf.to_s
END
      expected = _modify(expected)
      assert_equal expected, template.parse(input)
    end

    it "[!b10ns] generates ruby code correctly even when no embedded code." do
      input = <<'END'
abc
def
END
      expected = <<'END'
_buf = ''; _buf << 'abc
def
'; _buf.to_s
END
      expected = _modify(expected)
      assert_equal expected, template.parse(input)
    end

    it "[!3bx3d] not print extra linefeeds when line starts with '<%' and ends with '%>'" do
      input = <<'END'
  <% for item in items %>
    <% if item %>
    item = <%= item %>
    <% end %>
  <% end %>
END
      expected = <<'END'
_buf = '';   for item in items;
     if item;
 _buf << '    item = '; _buf << (item).to_s; _buf << '
';     end;
   end;
 _buf.to_s
END
      expected = _modify(expected)
      assert_equal expected, template.parse(input)
    end

    it "handles '<%- -%>' (but do nothing)." do
      input = <<'END'
  <%- for item in @items -%>
    <%-== item -%>
  <%- end -%>
END
      expected = <<'END'
_buf = '';   for item in @items;
 _buf << '    '; _buf << (item).to_s; _buf << '
';   end;
 _buf.to_s
END
      expected = _modify(expected)
      assert_equal expected, template.parse(input)
    end

    it "uses String#freeze forcedly when ':freeze=>true' passed to constructor." do
      input = "value=<%== value %>"
      expected = "_buf = ''; _buf << 'value='.freeze; _buf << (value).to_s; _buf.to_s\n"
      template = BabyErubis::Text.new(:freeze=>true)
      assert_equal expected, template.parse(input)
    end

    it "doesn't use String#freeze when ':freeze=>false' passed to constructor." do
      input = "value=<%== value %>"
      expected = "_buf = ''; _buf << 'value='; _buf << (value).to_s; _buf.to_s\n"
      template = BabyErubis::Text.new(:freeze=>false)
      assert_equal expected, template.parse(input)
    end

  end


  describe '#pattern()' do

    it "returns default embed pattern." do
      template = BabyErubis::Template.new
      assert_equal BabyErubis::Template::PATTERN, template.pattern
    end

    it "returns new embed pattern when overrided in subclass." do
      class FooTemplate < BabyErubis::Template
        rexp = BabyErubis::Template::PATTERN
        PATTERN = Regexp.compile(rexp.to_s.sub(/<%/, '\{%').sub(/%>/, '%\}'))
      end
      template = FooTemplate.new
      refute_equal BabyErubis::Template::PATTERN, template.pattern
      assert_equal FooTemplate::PATTERN, template.pattern
    end

  end


  describe '#render()' do

    it "renders template with context values." do
      input = <<'END'
title: <%== @title %>
items:
<% for item in @items %>
  - <%== item %>
<% end %>
END
      expected = <<'END'
title: Example
items:
  - <AAA>
  - B&B
  - "CCC"
END
      context = {:title=>'Example', :items=>['<AAA>', 'B&B', '"CCC"']}
      output = template.from_str(input).render(context)
      assert_equal expected, output
    end

    it "renders context values with no escaping." do
      input = <<'END'
title: <%= @title %>
items:
<% for item in @items %>
  - <%= item %>
<% end %>
END
      expected = <<'END'
title: <b>Example</b>
items:
  - <AAA>
  - B&B
  - "CCC"
END
      tmpl = BabyErubis::Text.new.from_str(input)
      context = {:title=>'<b>Example</b>', :items=>['<AAA>', 'B&B', '"CCC"']}
      output = tmpl.render(context)
      assert_equal expected, output
    end

    it "uses arg as context object when arg is not a hash object." do
      input = <<'END'
title: <%= @title %>
items:
<% for item in @items %>
  - <%= item %>
<% end %>
END
      expected = <<'END'
title: Example
items:
  - <AAA>
  - B&B
  - "CCC"
END
      obj = Object.new
      obj.instance_variable_set('@title', 'Example')
      obj.instance_variable_set('@items', ['<AAA>', 'B&B', '"CCC"'])
      output = template.from_str(input).render(obj)
      assert_equal expected, output
    end

    it "accepts nil as argument." do
      input    = "self.class is <%= self.class %>"
      expected = "self.class is BabyErubis::TemplateContext"
      context = nil
      output = template.from_str(input).render(context)
      assert_equal expected, output
    end

  end


  describe '#compile()' do

    it "compiles ruby code into proc object." do
      assert_nil template.instance_variable_get('@_proc')
      template.compile("_buf = ''; _buf << (x).to_s; _buf")
      assert_kind_of Proc, template.instance_variable_get('@proc')
    end

    it "returns self." do
      assert_same template, template.compile("_buf = ''; _buf << (x).to_s; _buf")
    end

    it "takes filename and linenum." do
      begin
        template.compile("_buf = ''; _buf << (x).to_s; _buf", 'example.erb', 3)
      rescue SyntaxError => ex
        assert_match /\Aexample\.erb:3: syntax error/, ex.message
      end
    end

    it "uses '(eRuby)' as default filename and 1 as default linenum." do
      begin
        template.compile("_buf = ''; _buf << (x).to_s; _buf")
      rescue SyntaxError => ex
        assert_match /\A\(eRuby\):1: syntax error/, ex.message
      end
    end

  end


  describe '.from_file()' do

    it "reads template file and returns template object." do
      input = <<'END'
title: <%= @title %>
items:
<% for item in @items %>
  - <%= item %>
<% end %>
END
      expected = <<'END'
title: Example
items:
  - <AAA>
  - B&B
  - "CCC"
END
      tmpfile = "test.#{rand()}.erb"
      File.open(tmpfile, 'wb') {|f| f.write(input) }
      begin
        template = BabyErubis::Text.new.from_file(tmpfile)
        context = {:title=>'Example', :items=>['<AAA>', 'B&B', '"CCC"']}
        output = template.render(context)
        assert_equal expected, output
      ensure
        File.unlink(tmpfile) if File.exist?(tmpfile)
      end
    end

    it "reads template file with specified encoding." do
      input    = "タイトル: <%= @title %>"
      expected = "タイトル: サンプル"
      tmpfile = "test.#{rand()}.erb"
      File.open(tmpfile, 'wb:utf-8') {|f| f.write(input) }
      begin
        # nothing should be raised
        template = BabyErubis::Text.new.from_file(tmpfile, 'utf-8')
        output = template.render(:title=>"サンプル")
        assert_equal expected, output
        assert_equal 'UTF-8', output.encoding.name
        # exception should be raised
        ex = assert_raises ArgumentError do
          template = BabyErubis::Text.new.from_file(tmpfile, 'us-ascii')
        end
        assert_equal "invalid byte sequence in US-ASCII", ex.message
      ensure
        File.unlink(tmpfile) if File.exist?(tmpfile)
      end
    end

  end


end



describe BabyErubis::HtmlTemplate do

  def _modify(ruby_code)
    if (''.freeze).equal?(''.freeze)
      return ruby_code.gsub(/([^'])';/m, "\\1'.freeze;")
    else
      return ruby_code
    end
  end

  input = <<'END'
<html>
  <h1><%= @title %></h1>
  <ul>
    <% for item in @items %>
    <!-- <%== item %> -->
    <li><%= item %></li>
    <% end %>
  </ul>
</html>
END
  source = <<'END'
_buf = ''; _buf << '<html>
  <h1>'; _buf << escape(@title); _buf << '</h1>
  <ul>
';     for item in @items;
 _buf << '    <!-- '; _buf << (item).to_s; _buf << ' -->
    <li>'; _buf << escape(item); _buf << '</li>
';     end;
 _buf << '  </ul>
</html>
'; _buf.to_s
END
  output = <<'END'
<html>
  <h1>Example</h1>
  <ul>
    <!-- <AAA> -->
    <li>&lt;AAA&gt;</li>
    <!-- B&B -->
    <li>B&amp;B</li>
    <!-- "CCC" -->
    <li>&quot;CCC&quot;</li>
  </ul>
</html>
END


  describe '#parse()' do

    it "handles embedded expression with escaping." do
      tmpl = BabyErubis::Html.new.from_str(input)
      assert_equal _modify(source), tmpl.src
    end

  end


  describe '#render()' do

    it "renders context values with escaping." do
      tmpl = BabyErubis::Html.new.from_str(input)
      context = {:title=>'Example', :items=>['<AAA>', 'B&B', '"CCC"']}
      assert_equal output, tmpl.render(context)
    end

  end


end
