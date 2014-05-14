# -*- coding: utf-8 -*-

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2014 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

libpath = File.class_eval { join(dirname(dirname(__FILE__)), 'lib') }
$: << libpath unless $:.include?(libpath)

require 'minitest/autorun'

## enforce not to use String#freeze() even if RUBY_VERSION >= 2.1
require 'baby_erubis'
BabyErubis::Template.class_eval do
  remove_const :FREEZE
  FREEZE = false
end

## load script file ('bin/baby_erubis.rb')
NOEXEC_SCRIPT = true
require File.join(File.dirname(libpath), 'bin', 'baby_erubis.rb')

## helper to steal stdin, stdout and stderr
require 'stringio'
def dummy_stdio(input=nil)
  stdin, stdout, stderr = $stdin, $stdout, $stderr
  $stdin  = StringIO.new(input || '')
  $stdout = StringIO.new
  $stderr = StringIO.new
  yield
  return $stdout.string, $stderr.string
ensure
  $stdin  = stdin
  $stdout = stdout
  $stderr = stderr
end

## helper to create dummy file temporarily
def with_tmpfile(filename, content)
  File.open(filename, 'wb') {|f| f.write(content) }
  yield filename
ensure
  File.unlink(filename) if File.exist?(filename)
end

## helper to create eruby file temporarily
def with_erubyfile(content=nil)
  content ||= ERUBY_TEMPLATE
  filename = "test_eruby.rhtml"
  with_tmpfile(filename, content) do
    yield filename
  end
end


describe Main do

  help_message = <<"END"
Usage: [..options..] #{File.basename($0)}
  -h, --help                  : help
  -v, --version               : version
  -x                          : show ruby code
  -X                          : show ruby code only (no text part)
  -N                          : numbering: add line numbers   (for '-x/-X')
  -U                          : unique: compress empty lines  (for '-x/-X')
  -C                          : compact: remove empty lines   (for '-x/-X')
  -c context                  : context string (yaml inline style or ruby code)
  -f file                     : context data file ('*.yaml' or '*.rb')
  -H                          : same as --format=html
      --format={text|html}    : format (default: text)
      --encoding=name         : encoding (default: utf-8)
      --freeze={true|false}   : use String#freeze() or not
END

  ERUBY_TEMPLATE = <<'END'
<html>
  <body>
    <h1><%= @title %></h1>
    <h1><%== @title %></h1>
    <div>
      <ul>
        <% for item in @items %>
        <li><%= item %></li>
        <% end %>
      </ul>
    </div>
  </body>
</html>
END
  SOURCE_TEXT = <<'END'
_buf = ''; _buf << '<html>
  <body>
    <h1>'; _buf << (@title).to_s; _buf << '</h1>
    <h1>'; _buf << (@title).to_s; _buf << '</h1>
    <div>
      <ul>
';         for item in @items;
 _buf << '        <li>'; _buf << (item).to_s; _buf << '</li>
';         end;
 _buf << '      </ul>
    </div>
  </body>
</html>
'; _buf.to_s
END
  SOURCE_HTML = <<'END'
_buf = ''; _buf << '<html>
  <body>
    <h1>'; _buf << escape(@title); _buf << '</h1>
    <h1>'; _buf << (@title).to_s; _buf << '</h1>
    <div>
      <ul>
';         for item in @items;
 _buf << '        <li>'; _buf << escape(item); _buf << '</li>
';         end;
 _buf << '      </ul>
    </div>
  </body>
</html>
'; _buf.to_s
END
  SOURCE_NO_TEXT = <<'END'
_buf = '';

         _buf << (@title).to_s;
         _buf << (@title).to_s;


         for item in @items;
             _buf << (item).to_s;
         end;



 _buf.to_s
END
  OUTPUT_HTML = <<'END'
<html>
  <body>
    <h1>Love&amp;Peace</h1>
    <h1>Love&Peace</h1>
    <div>
      <ul>
        <li>A</li>
        <li>B</li>
        <li>C</li>
      </ul>
    </div>
  </body>
</html>
END
  OUTPUT_TEXT = OUTPUT_HTML.sub(/&amp;/, '&')


  describe '-h, --help' do

    it "prints help message." do
      sout, serr = dummy_stdio { Main.main(["-h"]) }
      assert_equal help_message, sout
      assert_equal "", serr
      sout, serr = dummy_stdio { Main.main(["--help"]) }
      assert_equal help_message, sout
      assert_equal "", serr
    end

  end


  describe '-v, --version' do

    it "prints release version." do
      expected = "#{Main::RELEASE}\n"
      sout, serr = dummy_stdio { Main.main(["-v"]) }
      assert_equal expected, sout
      assert_equal "", serr
      sout, serr = dummy_stdio { Main.main(["--version"]) }
      assert_equal expected, sout
      assert_equal "", serr
    end

  end


  describe '-x' do

    it "shows ruby code compiled." do
      sout, serr = with_erubyfile do |fname|
        dummy_stdio { Main.main(['-x', fname]) }
      end
      assert_equal SOURCE_TEXT, sout
      assert_equal "", serr
    end

    it "reads stdin when no file specified." do
      sout, serr = dummy_stdio(ERUBY_TEMPLATE) { Main.main(['-x']) }
      assert_equal SOURCE_TEXT, sout
      assert_equal "", serr
    end

  end


  describe '-X' do

    it "shows ruby code only (no text part)." do
      expected = <<'END'
_buf = '';

         _buf << (@title).to_s;
         _buf << (@title).to_s;


         for item in @items;
             _buf << (item).to_s;
         end;




 _buf.to_s
END
      sout, serr = with_erubyfile do |fname|
        dummy_stdio { Main.main(['-X', fname]) }
      end
      assert_equal expected, sout
      assert_equal "", serr
    end

  end


  describe '-N' do

    it "adds line numbers." do
      expected = <<'END'
   1: _buf = '';
   2: 
   3:          _buf << (@title).to_s;
   4:          _buf << (@title).to_s;
   5: 
   6: 
   7:          for item in @items;
   8:              _buf << (item).to_s;
   9:          end;
  10: 
  11: 
  12: 
  13: 
  14:  _buf.to_s
END
      sout, serr = with_erubyfile do |fname|
        dummy_stdio { Main.main(['-XN', fname]) }
      end
      assert_equal expected, sout
      assert_equal "", serr
    end

  end


  describe '-U' do

    it "compresses empty lines." do
      expected = <<'END'
   1: _buf = '';

   3:          _buf << (@title).to_s;
   4:          _buf << (@title).to_s;

   7:          for item in @items;
   8:              _buf << (item).to_s;
   9:          end;

  14:  _buf.to_s
END
      sout, serr = with_erubyfile do |fname|
        dummy_stdio { Main.main(['-XNU', fname]) }
      end
      assert_equal expected, sout
      assert_equal "", serr
    end

  end


  describe '-C' do

    it "removes empty lines." do
      expected = <<'END'
   1: _buf = '';
   3:          _buf << (@title).to_s;
   4:          _buf << (@title).to_s;
   7:          for item in @items;
   8:              _buf << (item).to_s;
   9:          end;
  14:  _buf.to_s
END
      sout, serr = with_erubyfile do |fname|
        dummy_stdio { Main.main(['-XNC', fname]) }
      end
      assert_equal expected, sout
      assert_equal "", serr
    end

  end


  describe '-H' do

    it "escapes expressions." do
      sout, serr = with_erubyfile do |fname|
        dummy_stdio { Main.main(['-Hx', fname]) }
      end
      assert_equal SOURCE_HTML, sout
      assert_equal "", serr
    end

  end


  describe '-c cotnext' do

    it "can specify context data in YAML format." do
      context_str = "{title: Love&Peace, items: [A, B, C]}"
      sout, serr = with_erubyfile do |fname|
        dummy_stdio { Main.main(['-Hc', context_str, fname]) }
      end
      assert_equal OUTPUT_HTML, sout
      assert_equal "", serr
    end

    it "can specify context data as Ruby code." do
      context_str = "@title = 'Love&Peace'; @items = ['A','B','C']"
      sout, serr = with_erubyfile do |fname|
        dummy_stdio { Main.main(['-Hc', context_str, fname]) }
      end
      assert_equal OUTPUT_HTML, sout
      assert_equal "", serr
    end

  end


  describe '-f datafile' do

    it "can specify context data in YAML format." do
      ctx_str = "{title: Love&Peace, items: [A, B, C]}"
      ctx_file = "tmpdata.yaml"
      sout, serr = with_erubyfile do |fname|
        with_tmpfile(ctx_file, ctx_str) do
          dummy_stdio { Main.main(['-Hf', ctx_file, fname]) }
        end
      end
      assert_equal OUTPUT_HTML, sout
      assert_equal "", serr
    end

    it "can specify context data as Ruby code." do
      ctx_str = "@title = 'Love&Peace'; @items = ['A','B','C']"
      ctx_file = "tmpdata.rb"
      sout, serr = with_erubyfile do |fname|
        with_tmpfile(ctx_file, ctx_str) do
          dummy_stdio { Main.main(["-Hf#{ctx_file}", fname]) }
        end
      end
      assert_equal OUTPUT_HTML, sout
      assert_equal "", serr
    end

  end


  describe '--format={text|html}' do

    it "can enforce text format." do
      ctx_str = "{title: Love&Peace, items: [A, B, C]}"
      sout, serr = with_erubyfile do |fname|
        dummy_stdio { Main.main(['--format=text', '-c', ctx_str, fname]) }
      end
      assert_equal OUTPUT_TEXT, sout
      assert_equal "", serr
    end

    it "can enforce html format." do
      ctx_str = "{title: Love&Peace, items: [A, B, C]}"
      sout, serr = with_erubyfile do |fname|
        dummy_stdio { Main.main(['--format=html', '-c', ctx_str, fname]) }
      end
      assert_equal OUTPUT_HTML, sout
      assert_equal "", serr
    end

    it "reports error when argument is missng." do
      status = nil
      sout, serr = with_erubyfile do |fname|
        dummy_stdio { status = Main.main(['-x', '--format', fname]) }
      end
      assert_equal "", sout
      assert_equal "#{File.basename($0)}: --format: argument required.\n", serr
      assert_equal 1, status
    end

    it "reports error when unknown argument." do
      status = nil
      sout, serr = with_erubyfile do |fname|
        dummy_stdio { status = Main.main(['-x', '--format=json', fname]) }
      end
      assert_equal "", sout
      assert_equal "#{File.basename($0)}: --format=json: 'text' or 'html' expected\n", serr
      assert_equal 1, status
    end

  end


  describe '--encoding=name' do

    it "can specify encoding of file content." do
      sout, serr = with_erubyfile do |fname|
        dummy_stdio { status = Main.main(['-x', '--encoding=utf-8', fname]) }
      end
      assert_equal SOURCE_TEXT, sout
      assert_equal "" , serr
    end

  end


  describe '--freeze={true|false}' do

    it "can generate ruby code using String#freeze." do
      sout, serr = with_erubyfile do |fname|
        dummy_stdio { Main.main(['-x', '--freeze=true', fname]) }
      end
      expected = SOURCE_TEXT.gsub(/([^'])';/, "\\1'.freeze;")
      assert_equal expected, sout
    end

    it "can generate ruby code without String#freeze." do
      sout, serr = with_erubyfile do |fname|
        dummy_stdio { Main.main(['-x', '--freeze=false', fname]) }
      end
      expected = SOURCE_TEXT
      assert_equal expected, sout
    end

    it "reports error when argument is missing." do
      status = nil
      sout, serr = with_erubyfile do |fname|
        dummy_stdio { status = Main.main(['-x', '--freeze', fname]) }
      end
      assert_equal "", sout
      assert_equal "#{File.basename($0)}: --freeze: argument required.\n", serr
      assert_equal 1, status
    end

    it "reports error when unknown argument." do
      status = nil
      sout, serr = with_erubyfile do |fname|
        dummy_stdio { status = Main.main(['-x', '--freeze=yes', fname]) }
      end
      assert_equal "", sout
      assert_equal "#{File.basename($0)}: --freeze=yes: 'true' or 'false' expected\n", serr
      assert_equal 1, status
    end

  end


end
