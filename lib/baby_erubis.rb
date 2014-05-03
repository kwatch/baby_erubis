# -*- coding: utf-8 -*-

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2014 kuwata-lab.com all rights reserved $
### $License: MIT License $
###


##
## Yet another eRuby implementation, based on Erubis.
##
## * Small and fast
## * Easy to customize
## * Supports HTML as well as plain text
## * Accepts both template file and template string
##
## Example:
##
##   ## render template string
##   template = BabyErubis::Html.new <<'END', __FILE__, __LINE__+1
##     <h1><%= @title %></h1>
##     <% for item in @items %>
##       <p><%= item %></p>
##     <% end %>
##   END
##   context = {:title=>'Example', :items=>['<AAA>', 'B&B', '"CCC"']}
##   output = template.render(context)
##   print output
##
##   ## render template file
##   templat = BabyErubis::Html.load('example.html.erb', 'utf-8')
##   context = {:title=>'Example', :items=>['<AAA>', 'B&B', '"CCC"']}
##   output = template.render(context)
##   print output
##

module BabyErubis


  class Template

    def self.load(filename, encoding='utf-8')
      input = File.open(filename, "rb:#{encoding}") {|f| f.read() }
      return self.new(input, filename)
    end

    def initialize(input=nil, filename=nil, linenum=1)
      compile(input, filename, linenum) if input
    end

    attr_reader :src

    EMBED_REXP = /(^[ \t]*)?<%(==?|\#)?(.*?)%>([ \t]*\r?\n)?/m

    def compile(input, filename=nil, linenum=1)
      src = convert(input)
      @src = src
      @_proc = eval("proc { #{src} }", TOPLEVEL_BINDING, filename || '(eRuby)', linenum)
      return self
    end

    def convert(input)
      #; [!118pw] converts template string into ruby code.
      #; [!7ht59] escapes single quotation and backslash characters.
      src = "_buf = '';"       # preamble
      pos = 0
      rexp = EMBED_REXP
      input.scan(rexp) do |lspace, ch, code, rspace|
        match = Regexp.last_match
        text  = input[pos...match.begin(0)]
        pos   = match.end(0)
        src << _t(text)
        #; [!u93y5] appends embedded expression in '<%= %>'.
        #; [!auj95] appends embedded expression in '<%= %>' without escaping.
        #; [!qveql] appends linefeeds when '<%# %>' found.
        if ch == '='           # expression (escaping)
          src << _t(lspace) << " _buf << #{escaped_expr(code)};" << _t(rspace)
        elsif ch == '=='       # expression (without escaping)
          src << _t(lspace) << " _buf << (#{code}).to_s;" << _t(rspace)
        elsif ch == '#'        # comment
          src << _t(lspace) << ("\n" * code.count("\n")) << _t(rspace)
        else                   # statement
          #; [!3bx3d] not print extra linefeeds when line starts with '<%' and ends with '%>'
          if lspace && rspace
            src << "#{lspace}#{code};#{rspace}"
          else
            src << _t(lspace) << code << ';' << _t(rspace)
          end
        end
      end
      #; [!b10ns] generates ruby code correctly even when no embedded code.
      rest = $' || input
      src << _t(rest)
      src << "; _buf.to_s\n"   # postamble
      return src
    end

    def render(context={})
      ctxobj = context.is_a?(Hash) ? new_context(context) : context
      return ctxobj.instance_eval(&@_proc)
    end

    protected

    def escaped_expr(code)  # :abstract:
      raise NotImplementedError.new("#{self.class.name}#escaped_expr(): not implemented yet.")
    end

    def new_context(hash)  # :abstract:
      raise NotImplementedError.new("#{self.class.name}#new_context(): not implemented yet.")
    end

    private

    def build_text(text)
      return text && !text.empty? ? " _buf << '#{escape_text(text)}';" : ''
      #return text && !text.empty? ? " _buf << %q`#{escape_text(text)}`;" : ''
    end
    alias _t build_text

    def escape_text(text)
      return text.gsub!(/['\\]/, '\\\\\&') || text
      #return text.gsub!(/[`\\]/, '\\\\\&') || text
    end

  end


  class TextTemplate < Template

    protected

    def escaped_expr(code)
      return "(#{code}).to_s"
    end

    def new_context(hash)
      return TextTemplateContext.new(hash)
    end

  end
  Text = TextTemplate


  class HtmlTemplate < Template

    protected

    def escaped_expr(code)
      return "escape(#{code})"   # escape() is defined in HtmlTemplateContext
    end

    def new_context(hash)
      return HtmlTemplateContext.new(hash)
    end

  end
  Html = HtmlTemplate


  class TemplateContext

    def initialize(vars={})
      #; [!p69q1] takes hash object and sets them into instance variables.
      #; [!p853f] do nothing when vars is nil.
      vars.each do |k, v|
        instance_variable_set("@#{k}", v)
      end if vars
    end

    def [](key)
      return instance_variable_get("@#{key}")
    end

    def []=(key, value)
      instance_variable_set("@#{key}", value)
    end

    def escape(value)  # :abstract:
      raise NotImplementedError.new("#{self.class.name}#escape(): not implemented yet.")
    end

  end


  class TextTemplateContext < TemplateContext

    def escape(value)
      return value.to_s
    end

  end


  class HtmlTemplateContext < TemplateContext

    def escape(value)
      #return value.to_s.gsub(/&/, '&amp;').gsub(/</, '&lt;').gsub(/>/, '&gt;').gsub(/"/, '&quot;').gsub(/'/, '&#39;')
      return value.to_s.gsub(/[<>&"']/, BabyErubis::HTML_ESCAPE)
    end

  end

  HTML_ESCAPE = {'&'=>'&amp;', '<'=>'&lt;', '>'=>'&gt;', '"'=>'&quot;', "'"=>'&#39;'}


end
