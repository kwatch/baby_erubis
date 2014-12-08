# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2014 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require 'baby_erubis'


module BabyErubis


  class RailsTemplate < Template

    protected

    def add_preamble(src)
      src << "@output_buffer = output_buffer || ActionView::OutputBuffer.new;"
    end

    def add_postamble(src)
      src << "@output_buffer.to_s\n"
    end

    def add_text(src, text)
      return if !text || text.empty?
      freeze = @freeze ? '.freeze' : ''
      text.gsub!(/['\\]/, '\\\\\&')
      src << "@output_buffer.safe_append='#{text}'#{freeze};"
    end

    def add_stmt(src, stmt)
      return if !stmt || stmt.empty?
      src << stmt
    end

    def add_expr(src, expr, indicator)
      return if !expr || expr.empty?
      l = '('; r = ')'
      l = r = ' ' if expr_has_block(expr)
      if indicator == '='           # escaping
        src << "@output_buffer.append=#{l}#{expr}#{r};"
      else                          # without escaping
        src << "@output_buffer.safe_append=#{l}#{expr}#{r};"
      end
    end

  end


end
