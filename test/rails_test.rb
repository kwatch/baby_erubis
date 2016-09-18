# -*- coding: utf-8 -*-

###
### $Release: 2.2.0 $
### $Copyright: copyright(c) 2014-2016 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

libpath = File.class_eval { join(dirname(dirname(__FILE__)), 'lib') }
$: << libpath unless $:.include?(libpath)

require 'minitest/autorun'

require 'baby_erubis/rails'



describe 'BabyErubis::RailsTemplate' do

  let(:tmpl) { BabyErubis::RailsTemplate.new }

  def _modify(ruby_code)
    if (''.freeze).equal?(''.freeze)
      return ruby_code.gsub(/([^'])';/m, "\\1'.freeze;")
    else
      return ruby_code
    end
  end

  eruby_template = <<'END'
<h1>New Article</h1>

<%= form_for :article, url: articles_path do |f| %>
  <p>
    <%= f.label :title %><br>
    <%= f.text_field :title %>
  </p>

  <p>
    <%= f.label :text %><br>
    <%= f.text_area :text %>
  </p>

  <p>
    <%= f.submit %>
  </p>
<% end %>
END

  ruby_code = <<'END'
@output_buffer = output_buffer || ActionView::OutputBuffer.new;@output_buffer.safe_append='<h1>New Article</h1>

';@output_buffer.append= form_for :article, url: articles_path do |f| ;@output_buffer.safe_append='
  <p>
    ';@output_buffer.append=(f.label :title);@output_buffer.safe_append='<br>
    ';@output_buffer.append=(f.text_field :title);@output_buffer.safe_append='
  </p>

  <p>
    ';@output_buffer.append=(f.label :text);@output_buffer.safe_append='<br>
    ';@output_buffer.append=(f.text_area :text);@output_buffer.safe_append='
  </p>

  <p>
    ';@output_buffer.append=(f.submit);@output_buffer.safe_append='
  </p>
'; end;
@output_buffer.to_s
END


  describe '#parse()' do

    it "converts eRuby template into ruby code with Rails style." do
      tmpl = BabyErubis::RailsTemplate.new.from_str(eruby_template)
      expected = _modify(ruby_code)
      assert_equal expected, tmpl.src
    end

    it "can understand block such as <%= form_for do |x| %>." do
      s = <<-'END'
      <%= (1..3).each do %>
        Hello
      <% end %>
      END
      tmpl = BabyErubis::RailsTemplate.new.from_str(s)
      assert_match /\@output_buffer.append= \(1\.\.3\)\.each do ;/, tmpl.src
      #
      s = <<-'END'
      <%= (1..3).each do |x, y|%>
        Hello
      <% end %>
      END
      tmpl = BabyErubis::RailsTemplate.new.from_str(s)
      assert_match /\@output_buffer.append= \(1\.\.3\)\.each do \|x, y\| ;/, tmpl.src
    end

    it "doesn't misunderstand <%= @todo %> as block" do
      tmpl = BabyErubis::RailsTemplate.new.from_str("<b><%= @todo %></b>")
      assert_match /\@output_buffer\.append=\(\@todo\);/, tmpl.src
    end

  end


end
