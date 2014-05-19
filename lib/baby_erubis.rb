# -*- coding: utf-8 -*-

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2014 kuwata-lab.com all rights reserved $
### $License: MIT License $
###


##
## Yet another eRuby implementation, based on Erubis.
## See https://github.com/kwatch/baby_erubis/tree/ruby for details.
##
## Example:
##     template = BabyEruibs::Html.new.from_str <<'END', __FILE__, __LINE__+1
##     <% for item in @items %>
##     - item = <%= item %>
##     <% end %>
##     END
##     print template.render(:items=>['A', 'B', 'C'])
##     ## or
##     template = BabyErubis::Html.new.from_file('example.html.erb', 'utf-8')
##     print template.render(:items=>['A', 'B', 'C'])
##

module BabyErubis

  RELEASE = '$Release: 0.0.0 $'.split(' ')[1]


  class Template

    FREEZE = (''.freeze).equal?(''.freeze)   # Ruby 2.1 feature

    def initialize(opts=nil)
      @freeze    = self.class.const_get(:FREEZE)
      if opts
        @freeze = (v=opts[:freeze   ]) != nil ? v : @freeze
      end
    end

    def from_file(filename, encoding='utf-8')
      mode = "rb:#{encoding}"
      mode = "rb" if RUBY_VERSION < '1.9'
      input = File.open(filename, mode) {|f| f.read() }
      compile(parse(input), filename, 1)
      return self
    end

    def from_str(input, filename=nil, linenum=1)
      compile(parse(input), filename, linenum)
      return self
    end

    attr_reader :src

    #PATTERN = /(^[ \t]*)?<%(\#)?(==?)?(.*?)%>([ \t]*\r?\n)?/m
    PATTERN = /(^[ \t]*)?<%-?(\#)?(==?)? ?(.*?) ?-?%>([ \t]*\r?\n)?/m

    def pattern
      return self.class.const_get(:PATTERN)
    end

    def compile(src, filename=nil, linenum=1)
      @src = src
      @proc = eval("proc { #{src} }", empty_binding(), filename || '(eRuby)', linenum)
      return self
    end

    def parse(input)
      src = "_buf = '';"       # preamble
      spc = ""
      pos = 0
      input.scan(pattern()) do |lspace, sharp, ch, code, rspace|
        match = Regexp.last_match
        text  = input[pos, match.begin(0) - pos]
        pos   = match.end(0)
        if sharp               # comment
          code = ("\n" * code.count("\n"))
          if ! ch && lspace && rspace   # trimmed statement
            src << _t("#{spc}#{text}") << code << rspace
            spc = ""
          else                          # other statement or expression
            src << _t("#{spc}#{text}#{lspace}") << code
            spc = rspace
          end
        elsif ! ch             # statement
          if lspace && rspace
            src << _t("#{spc}#{text}") << "#{lspace} #{code};#{rspace}"
            spc = ""
          else
            src << _t("#{spc}#{text}#{lspace}") << " #{code};"
            spc = rspace
          end
        else                   # expression
          if ch == '='           # expression (escaping)
            src << _t("#{spc}#{text}#{lspace}") << " _buf << #{escaped_expr(code)};"
            spc = rspace
          elsif ch == '=='       # expression (without escaping)
            src << _t("#{spc}#{text}#{lspace}") << " _buf << (#{code}).to_s;"
            spc = rspace
          else
            raise "** unreachable: ch=#{ch.inspect}"
          end
        end
      end
      text = pos == 0 ? input : input[pos..-1]   # or $' || input
      src << _t("#{spc}#{text}")
      src << " _buf.to_s\n"    # postamble
      return src
    end

    def render(context={})
      ctxobj = context.nil? || context.is_a?(Hash) ? new_context(context) : context
      return ctxobj.instance_eval(&@proc)
    end

    def new_context(hash)
      return TemplateContext.new(hash)
    end

    protected

    def escaped_expr(code)
      return "(#{code}).to_s"
    end

    private

    def build_text(text)
      freeze = @freeze ? '.freeze' : ''
      return text && !text.empty? ? " _buf << '#{escape_text(text)}'#{freeze};" : ''
      #return text && !text.empty? ? " _buf << %q`#{escape_text(text)}`#{freeze};" : ''
    end
    alias _t build_text

    def escape_text(text)
      return text.gsub!(/['\\]/, '\\\\\&') || text
      #return text.gsub!(/[`\\]/, '\\\\\&') || text
    end

    def empty_binding
      return binding()
    end

  end
  Text = Template              # for shortcut


  class TemplateContext

    def initialize(vars={})
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

    def escape(value)
      return value.to_s
    end

  end


  class HtmlTemplate < Template

    def escaped_expr(code)
      return "escape(#{code})"   # escape() is defined in HtmlTemplateContext
    end
    protected :escaped_expr

    def new_context(hash)
      return HtmlTemplateContext.new(hash)
    end

  end
  Html = HtmlTemplate          # for shortcut


  module HtmlEscaper

    HTML_ESCAPE = {'&'=>'&amp;', '<'=>'&lt;', '>'=>'&gt;', '"'=>'&quot;', "'"=>'&#39;'}

    module_function

    def escape(value)
      return value.to_s.gsub(/[<>&"']/, HTML_ESCAPE)  # for Ruby 1.9 or later
    end

    if RUBY_VERSION < '1.9'
      def escape(value)
        return value.to_s.gsub(/&/, '&amp;').gsub(/</, '&lt;').gsub(/>/, '&gt;').gsub(/"/, '&quot;').gsub(/'/, '&#39;')
      end
    end

  end


  class HtmlTemplateContext < TemplateContext
    include HtmlEscaper
  end


end
