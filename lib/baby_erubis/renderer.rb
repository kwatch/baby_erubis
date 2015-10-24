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
  ##     #ERUBY_PATH      = ['.', 'templates']
  ##     #ERUBY_LAYOUT    = :_layout
  ##     #ERUBY_HTML_EXT  = '.html.eruby'
  ##     #ERUBY_TEXT_EXT  = '.eruby'
  ##     #ERUBY_CACHE     = {}
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

    ERUBY_PATH      = ['.']
    ERUBY_LAYOUT    = :_layout
    ERUBY_HTML_EXT  = '.html.eruby'
    ERUBY_TEXT_EXT  = '.eruby'
    ERUBY_CACHE     = {}

    def eruby_render_html(template_name, layout: true, encoding: 'utf-8')
      return _eruby_render_template(template_name, layout) {|tmpl_name|
        ext = self.class.const_get :ERUBY_HTML_EXT
        _eruby_find_template("#{tmpl_name}#{ext}") {|fpath|
          BabyErubis::Html.new.from_file(fpath, encoding)
        }
      }
    end

    def eruby_render_text(template_name, layout: false, encoding: 'utf-8')
      return _eruby_render_template(template_name, layout) {|tmpl_name|
        ext = self.class.const_get :ERUBY_TEXT_EXT
        _eruby_find_template("#{tmpl_name}#{ext}") {|fpath|
          BabyErubis::Text.new.from_file(fpath, encoding)
        }
      }
    end

    private

    def _eruby_find_template(filename)
      cache = self.class.const_get :ERUBY_CACHE
      paths = self.class.const_get :ERUBY_PATH
      dir =  paths.find {|path| cache.key?("#{path}/#{filename}") } \
          || paths.find {|path| File.file?("#{path}/#{filename}") }  or
        raise BabyErubis::TemplateError.new("#{filename}: template not found in #{paths.inspect}.")
      fpath = "#{dir}/#{filename}"
      #
      now = Time.now
      template = _eruby_load_template(cache, fpath, now)
      unless template
        mtime = File.mtime(fpath)
        template = yield fpath
        ## retry when file timestamp changed during template loading
        unless mtime == (mtime2 = File.mtime(fpath))
          mtime = mtime2
          template = yield fpath
          mtime == File.mtime(fpath)  or
            raise "#{fpath}: timestamp changes too frequently. something wrong."
        end
        _eruby_store_template(cache, fpath, template, mtime, now)
      end
      return template
    end

    def _eruby_load_template(cache, fpath, now)
      tuple = cache[fpath]
      template, timestamp, last_checked = tuple
      return nil unless template
      ## skip timestamp check in order to reduce syscall (= File.mtime())
      interval = now - last_checked
      return template if interval < 0.5
      ## check timestamp only for 5% request in order to avoid thundering herd
      return template if interval < 1.0 && rand() > 0.05
      ## update last_checked in cache when file timestamp is not changed
      if timestamp == File.mtime(fpath)
        tuple[2] = now
        return template
      ## remove cache entry when file timestamp is changed
      else
        cache[fpath] = nil
        return nil
      end
    end

    def _eruby_store_template(cache, fpath, template, timestamp, last_checked)
      cache[fpath] = [template, timestamp, last_checked]
    end

    def _eruby_render_template(template_name, layout)
      template = yield template_name
      s = template.render(self)
      unless @_layout.nil?
        layout = @_layout; @_layout = nil
      end
      while layout
        layout = self.class.const_get :ERUBY_LAYOUT if layout == true
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
