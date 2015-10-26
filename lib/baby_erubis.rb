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


  class TemplateError < StandardError
  end


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
      src = ""
      add_preamble(src)            # preamble
      spc = ""
      pos = 0
      input.scan(pattern()) do |lspace, sharp, ch, code, rspace|
        match = Regexp.last_match
        text  = input[pos, match.begin(0) - pos]
        pos   = match.end(0)
        if sharp                   # comment
          code = ("\n" * code.count("\n"))
          if ! ch && lspace && rspace   # trimmed statement
            add_text(src, "#{spc}#{text}"); add_stmt(src, "#{code}#{rspace}")
            rspace = ""
          else                          # other statement or expression
            add_text(src, "#{spc}#{text}#{lspace}"); add_stmt(src, code)
          end
        else
          if ch                    # expression
            add_text(src, "#{spc}#{text}#{lspace}"); add_expr(src, code, ch)
          elsif lspace && rspace   # statement (trimming)
            add_text(src, "#{spc}#{text}"); add_stmt(src, "#{lspace} #{code};#{rspace}")
            rspace = ""
          else                     # statement (without trimming)
            add_text(src, "#{spc}#{text}#{lspace}"); add_stmt(src, " #{code};")
          end
        end
        spc = rspace
      end
      text = pos == 0 ? input : input[pos..-1]   # or $' || input
      add_text(src, "#{spc}#{text}")
      add_postamble(src)           # postamble
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

    def add_preamble(src)
      src << "_buf = '';"
    end

    def add_postamble(src)
      src << " _buf.to_s\n"
    end

    def add_text(src, text)
      return if !text || text.empty?
      freeze = @freeze ? '.freeze' : ''
      text.gsub!(/['\\]/, '\\\\\&')
      src << " _buf << '#{text}'#{freeze};"
    end

    def add_stmt(src, stmt)
      return if !stmt || stmt.empty?
      src << stmt
    end

    def add_expr(src, expr, indicator)
      return if !expr || expr.empty?
      if expr_has_block(expr)
        src << " _buf << #{expr}"
      elsif indicator == '='        # escaping
        src << " _buf << #{escaped_expr(expr)};"
      else                          # without escaping
        src << " _buf << (#{expr}).to_s;"
      end
    end

    def escaped_expr(code)
      return "(#{code}).to_s"
    end

    def expr_has_block(expr)
      return expr =~ /(\bdo|\{)\s*(\|[^|]*?\|\s*)?\z/
    end

    private

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
