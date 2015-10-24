# -*- coding: utf-8 -*-

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2014 kuwata-lab.com all rights reserved $
### $License: MIT License $
###


module BabyErubis

  ##
  ## Module to define template rendering methods.
  ##
  ## ex:
  ##   class MyController
  ##     include BabyErubis::HtmlEscaper
  ##     include BabyErubis::Renderer
  ##
  ##     #ERUBY_TEMPLATE_DIR       = 'templates'
  ##     #ERUBY_TEMPLATE_LAYOUT    = :_layout
  ##     #ERUBY_TEMPLATE_HTML_EXT  = '.html.eruby'
  ##     #ERUBY_TEMPLATE_TEXT_EXT  = '.eruby'
  ##     #ERUBY_TEMPLATE_CACHE     = {}
  ##
  ##     def index
  ##       @items = ['A', 'B', 'C']
  ##       ## renders 'templates/welcome.html.eruby'
  ##       html = eruby_render_html(:welcome)
  ##       return html
  ##     end
  ##   end
  ##
  ##
  module Renderer

    ERUBY_TEMPLATE_DIR       = '.'
    ERUBY_TEMPLATE_LAYOUT    = :_layout
    ERUBY_TEMPLATE_HTML_EXT  = '.html.eruby'
    ERUBY_TEMPLATE_TEXT_EXT  = '.eruby'
    ERUBY_TEMPLATE_CACHE     = {}

    def eruby_render_html(template_name, layout: true, encoding: 'utf-8')
      return _eruby_render_template(template_name, layout) {|tmpl_name|
        c = self.class
        dir   = c.const_get :ERUBY_TEMPLATE_DIR
        ext   = c.const_get :ERUBY_TEMPLATE_HTML_EXT
        cache = c.const_get :ERUBY_TEMPLATE_CACHE
        _eruby_find_template("#{dir}/#{tmpl_name}#{ext}", cache) {|fpath|
          BabyErubis::Html.new.from_file(fpath, encoding)
        }
      }
    end

    def eruby_render_text(template_name, layout: false, encoding: 'utf-8')
      return _eruby_render_template(template_name, layout) {|tmpl_name|
        c = self.class
        dir   = c.const_get :ERUBY_TEMPLATE_DIR
        ext   = c.const_get :ERUBY_TEMPLATE_TEXT_EXT
        cache = c.const_get :ERUBY_TEMPLATE_CACHE
        _eruby_find_template("#{dir}/#{tmpl_name}#{ext}", cache) {|fpath|
          BabyErubis::Text.new.from_file(fpath, encoding)
        }
      }
    end

    private

    def _eruby_find_template(fpath, cache)
      mtime = File.mtime(fpath)
      template, timestamp = cache[fpath]
      if ! template || timestamp != mtime
        template = yield fpath
        ## retry when file timestamp changed during template loading
        unless mtime == (mtime2 = File.mtime(fpath))
          mtime = mtime2
          template = yield fpath
          mtime == File.mtime(fpath)  or
            raise "#{fpath}: timestamp changes too frequently. something wrong."
        end
        cache[fpath] = [template, mtime]
      end
      return template
    end

    def _eruby_render_template(template_name, layout)
      template = yield template_name
      s = template.render(self)
      unless @_layout.nil?
        layout = @_layout; @_layout = nil
      end
      while layout
        layout = self.class.const_get :ERUBY_TEMPLATE_LAYOUT if layout == true
        template = yield layout
        @_content = s
        s = template.render(self)
        @_content = nil
        layout = @_layout; @_layout = nil
      end
      return s
    end

  end


end
