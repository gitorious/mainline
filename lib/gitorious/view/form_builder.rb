# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

module Gitorious
  module View
    class FormBuilder < ActionView::Helpers::FormBuilder
      def text_input_block(field, label, options = {})
        input_block(field, label, text_field(field, :class => "input-xlarge"), options)
      end

      def select_block(field, label, choices, options = {}, html_options = {})
        sel = select(field, choices, options[:select] || {}, html_options)
        input_block(field, label, sel, options)
      end

      def checkbox_block(field, label)
        <<-HTML.html_safe
        <div class="control-group">
          <div class="controls">
            <label class="checkbox">
              #{check_box(field)}
              #{label}
            </label>
          </div>
        </div>
        HTML
      end

      def textarea_md_preview(field, label)
        id = "markdown-preview-#{field}"
        options = {
          :class => "input-xxlarge gts-live-markdown-preview",
          :"data-gts-preview-target" => id,
          :rows => 5
        }
        <<-HTML.html_safe
        <div id="#{id}" class="gts-markdown-preview help-block">
          <h2>#{label} preview</h2>
          <div></div>
        </div>
        <div class="control-group">
          #{label(field, label, :class => "control-label")}
          <div class="controls">
            #{text_area(field, options)}
            <p class="help-block">
              Use <a data-toggle="collapse" data-target="#markdown-help-#{field}" class="dropdown-toggle" href="#markdown-help-#{field}">Markdown</a> for formatting
            </p>
            #{markdown_help(field)}
          </div>
        </div>
        HTML
      end

      def markdown_help(field)
        <<-HTML.html_safe
          <div class="collapse gts-help" id="markdown-help-#{field}">
            <table class="table">
              <tr>
                <td><pre><code>[link](http://gitorious.org)</code></pre></td>
                <td><a href="http://gitorious.org">link</a></td>
              </tr>
              <tr>
                <td><pre><code>    if (true) {
        return;
    }</code></pre></td>
                <td><pre><code>if (true) {
    return;
}</code></pre></td>
              </tr>
              <tr>
                <td><pre><code>inline `code` here</code></pre></td>
                <td>      inline <code>code</code> here</td>
              </tr>
              <tr>
                <td><pre><code>**bold**</code></pre></td>
                <td><strong>bold</strong></td>
              </tr>
              <tr>
                <td><pre><code>_emphasized_</code></pre></td>
                <td><em>emphasized</em></td>
              </tr>
              <tr>
                <td><pre><code>* item 1
* item 2</code></pre></td>
                <td><ul><li>item 1</li><li>item 2</li></ul></td>
              </tr>
              <tr>
                <td><pre><code>1. item 1
2. item 2</code></pre></td>
                <td><ol><li>item 1</li><li>item 2</li></ol></td>
              </tr>
              <tr>
                <td><pre><code># Header 1#</code></pre></td>
                <td><h1>Header 1</h1></td>
              </tr>
              <tr>
                <td><pre><code>## Header 2</code></pre></td>
                <td><h2>Header 2</h2></td>
              </tr>
            </table>
            <p><a href="http://daringfireball.net/projects/markdown/">Full Markdown reference</a></p>
          </div>
        HTML
      end

      def owner_input_block(field, label, user)
        owner_type = "#{field}_type"
        radio_name = "#{@object_name}[#{owner_type}]"
        id_prefix = "#{@object_name}_#{owner_type}"
        user_selected = @object.send(field).class.name == "User"

        <<-HTML.html_safe
        <div class="control-group">
          #{label(field, label, :class => "control-label")}
          <div class="controls">
            <label class="radio">
              <input type="radio" name="#{radio_name}"
                     id="#{id_prefix}_user" value="User"
                     data-gts-owner="#{user.login}"#{' checked' if user_selected}>
              Me
            </label>
            <label class="radio">
              <input type="radio" name="#{radio_name}"
                     id="#{id_prefix}_group" value="Group">
              <select id="#{id_prefix}_id_group_select" name="#{@object_name}[#{field}_id]">
                #{owner_options_for(user)}
              </select>
            </label>
          </div>
        </div>
        HTML
      end

      def owner_options_for(user)
        Team.by_admin(user).inject("") do |html, group|
          "#{html}<option value=\"#{group.id}\">#{group.name}</option>"
        end
      end

      def private_toggle(params)
        <<-HTML.html_safe
        <div class="control-group">
          <label for="private" class="control-label">Private #{@object_name}?</label>
          <div class="controls">
            <label class="checkbox">
              <input type="checkbox" value="1" name="private" id="private"#{" checked" if params[:private]}>
            </label>
            <p class="help-block">
              Private #{@object_name.to_s.pluralize} can only be accessed by you and
              individuals/groups you grant access to.
            </p>
          </div>
        </div>
        HTML
      end

      def input_block(field, label, input, options = {})
        <<-HTML.html_safe
        <div class="control-group">
          #{label(field, label, :class => "control-label")}
          <div class="controls">
            #{input}
            #{'<p class="help-block">' + options[:help] + '</p>' if options[:help]}
          </div>
        </div>
        HTML
      end
    end
  end
end
