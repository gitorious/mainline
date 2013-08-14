# encoding: utf-8
#--
#   Copyright (C) 2011-2013 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 August Lilleaas <augustlilleaas@gmail.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
#   Copyright (C) 2009 Fabio Akita <fabio.akita@gmail.com>
#   Copyright (C) 2009 Bill Marquette <bill.marquette@gmail.com>
#   Copyright (C) 2010 Christian Johansen <christian@shortcut.no>
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
require "libdolt"
require "gitorious"
require "gitorious/view/dolt_url_helper"
require "gitorious/view/repository_helper"
require "gitorious/view/avatar_helper"

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include ActsAsTaggableOn::TagsHelper
  include UsersHelper
  include BreadcrumbsHelper
  include EventRenderingHelper
  include RoutingHelper
  include SiteWikiPagesHelper
  include Gitorious::Authorization
  include GroupRoutingHelper
  include Gitorious::CacheInPrivateHelper
  include DoltViewHelpers
  include Gitorious::View::AvatarHelper

  GREETINGS = ["Hello", "Hi", "Greetings", "Howdy", "Heya", "G'day"]

  STYLESHEETS = {
    :common => ["content", "sidebar", "forms", "buttons", "base"],
    :external => ["external"]
  }

  def random_greeting
    GREETINGS[rand(GREETINGS.length)]
  end

  def help_box(style = :side, icon = :help, options = {}, &block)
    raw <<-HTML
      <div id="#{options.delete(:id)}" style="#{options.delete(:style)}"
           class="help-box #{style} #{icon} round-5">
        <div class="icon #{icon}"></div>
        #{capture(&block)}
      </div>
    HTML
  end

  def pull_box(title, options = {}, &block)
    title_html = title.nil? ? "" : "<div class=\"pull-box-header\"><h3>#{title}</h3></div>"
    raw <<-HTML
      <div class="pull-box-container #{options.delete(:class)}">
        #{title_html}
        <div class="pull-box-content">
          #{capture(&block)}
        </div>
      </div>
    HTML
  end

  def dialog_box(title, options = {}, &block)
    title_html = title.nil? ? "" : "<h3 class=\"round-top-5 dialog-box-header\">#{title}</h3>"
    raw <<-HTML
      <div class="dialog-box #{options.delete(:class)}">
        #{title_html}
        <div class="dialog-box-content">
          #{capture(&block)}
        </div>
      </div>
    HTML
  end

  def markdown(text, options = [:smart])
    renderer = MarkupRenderer.new(text, :markdown => options)
    renderer.to_html.html_safe
  end

  def render_markdown(text, *options)
    # RDiscount < 1.4 doesn't support the :auto_link, use Rails' instead
    auto_link = options.delete(:auto_link)
    markdown_options = [:smart] + options
    markdownized_text = markdown(text, markdown_options)
    if auto_link
      markdownized_text = auto_link(markdownized_text, :urls)
    end
    sanitize(markdownized_text).html_safe
  end

  def feed_icon(url, alt_title = "Atom feed", size = :small)
    link_to(image_tag("silk/feed.png", :class => "feed_icon"), url,
            :alt => alt_title, :title => alt_title)
  end

  def default_css_tag_sizes
    %w(tag_size_1 tag_size_2 tag_size_3 tag_size_4)
  end

  def linked_tag_list_as_sentence(tags)
    tags.map do |tag|
      link_to(h(tag.name), search_path(:q => "@category #{h(tag.name)}"))
    end.to_sentence.html_safe
  end

  def build_notice_for(object, options = {})
    out =  %Q{<div class="being_constructed round-10">}
    out <<  %Q{<div class="being_constructed_content round-10">}
    out << %Q{  <p>#{I18n.t( "application_helper.notice_for", :class_name => object.class.name.humanize.downcase)}</p>}
    if options.delete(:include_refresh_link)
      out << %Q{<p class="spin hint"><a href="#{url_for()}">Click to refresh</a></p>}
    else
      out << %Q{<p class="spin">#{image_tag("spinner.gif")}</p>}
    end
    out << %Q{  <p class="hint">If this message persists beyond what is reasonable, feel free to #{link_to("contact us", contact_path)}</p>}
    out << %Q{</div></div>}
    out.html_safe
  end

  def render_if_ready(object, options = {})
    if object.respond_to?(:ready?) && object.ready?
      yield
    else
      raw build_notice_for(object, options)
    end
  end

  def selected_if_current_page(url_options, slack = false)
    if slack
      if controller.request.fullpath.index(CGI.escapeHTML(url_for(url_options))) == 0
        "selected"
      end
    else
      "selected" if current_page?(url_options)
    end
  end

  def submenu_selected_class_if_current?(section)
    case section
    when :overview
     if %w[projects].include?(controller.controller_name )
       return "selected"
     end
    when :repositories
      if %w[repositories trees logs commits comitters comments merge_requests
            blobs committers].include?(controller.controller_name )
        return "selected"
      end
    when :pages
      if %w[pages].include?(controller.controller_name )
        return "selected"
      end
    end
  end

  def link_to_with_selected(name, options = {}, html_options = nil)
    html_options = current_page?(options) ? {:class => "selected"} : nil
    link_to(name, options = {}, html_options)
  end

  def syntax_themes_css
    out = []
    if @load_syntax_themes
      # %w[ active4d all_hallows_eve amy blackboard brilliance_black brilliance_dull
      #     cobalt dawn eiffel espresso_libre idle iplastic lazy mac_classic
      #     magicwb_amiga pastels_on_dark slush_poppies spacecadet sunburst
      #     twilight zenburnesque
      # ].each do |syntax|
      #   out << stylesheet_link_tag("syntax_themes/#{syntax}")
      # end
      return stylesheet_link_tag("syntax_themes/idle")
    end
    out.join("\n").html_safe
  end

  def flashes
    flash.map do |type, content|
      content_tag(:div, content_tag(:p, content), :class => "flash_message #{type}")
    end.join("\n").html_safe
  end

  def action_and_body_for_event(event)
    target = event.target
    if target.nil?
      return ["", "", ""]
    end
    # These are defined in event_rendering_helper.rb:
    begin
      action, body, category = self.send("render_event_#{Action::css_class(event.action)}", event)
    rescue ActiveRecord::RecordNotFound
      return ["","",""]
    end
    body = sanitize(body, :tags => %w[a em i strong b])
    [action, body, category]
  end

  def link_to_remote_if(condition, name, options, html_options = {})
    if condition
      link_to_remote(name, options, html_options)
    else
      content_tag(:span, name)
    end
  end

  def render_readme(repository)
    possibilities = []
    repository.git.git.ls_tree({:name_only => true}, "master").each do |line|
      possibilities << line[0, line.length-1] if line =~ /README.*/
    end

    return "" if possibilities.empty?
    text = repository.git.git.show({}, "master:#{possibilities.first}")
    markdown(text) rescue simple_format(sanitize(text))
  end

  def render_markdown_help
    render(:partial => "/site/markdown_help")
  end

  def link_to_help_toggle(dom_id, style = :image)
    if style == :image
      link_to_function(image_tag("help_grey.png", {
        :alt => t("application_helper.more_info")
      }), "$('##{dom_id}').toggle()", :class => "more_info")
    else
      %Q{<span class="hint">(} +
      link_to_function("?", "$('##{dom_id}').toggle()", :class => "more_info") +
      ")</span>"
    end
  end

  FILE_EXTN_MAPPINGS = {
    ".cpp" => "cplusplus-file",
    ".c" => "c-file",
    ".h" => "header-file",
    ".java" => "java-file",
    ".sh" => "exec-file",
    ".exe"  => "exec-file",
    ".rb" => "ruby-file",
    ".png" => "image-file",
    ".jpg" => "image-file",
    ".gif" => "image-file",
    "jpeg" => "image-file",
    ".zip" => "compressed-file",
    ".gz" => "compressed-file"}

  def class_for_filename(filename)
    return FILE_EXTN_MAPPINGS[File.extname(filename)] || "file"
  end

  def render_download_links(project, repository, head, options={})
    head = desplat_path(head) if head.is_a?(Array)

    (["tar.gz", "zip"].map do |extension|
      link_html = link_to("Download #{refname(head)} as #{extension}",
                          archive_url(repository.path_segment, head, extension),
                          :title => "Download #{refname(head)} as #{extension}",
                          :class => "download-link")
      content_tag(:li, link_html, :class => extension.split('.').last)
    end).join("\n").html_safe
  end

  def paragraphs_with_more(text, identifier)
    return if text.blank?
    first, rest = text.split("</p>", 2)
    if rest.blank?
      (first + "</p>").html_safe
    else
      (<<-HTML).html_safe
        #{first}
        <a href="#more"
           onclick="$('#description-rest-#{identifier}').toggle(); $(this).hide()">more&hellip;</a></p>
        <div id="description-rest-#{identifier}" style="display:none;">#{rest}</div>
      HTML
    end
  end

  def markdown_hint
    t("views.common.format_using_markdown",
      :markdown => %(<a href="http://daringfireball.net/projects/markdown/">Markdown</a>)).html_safe
  end

  def current_site
    controller.current_site
  end

  def force_utf8(str)
    if str.respond_to?(:force_encoding)
      str.force_encoding("UTF-8")
      if str.valid_encoding?
        str
      else
        str.encode("binary", :invalid => :replace, :undef => :replace).encode("utf-8")
      end
    else
      str.mb_chars
    end
  end

  # Creates a CSS styled <button>.
  #
  #  <%= styled_button :big, "Create user" %>
  #  <%= styled_button :medium, "Do something!", :class => "foo", :id => "bar" %>
  def styled_button(size_identifier, label, options = {})
    options.reverse_merge!(:type => "submit", :class => size_identifier.to_s)
    content_tag(:button, content_tag(:span, label), options)
  end

  # Similar to styled_button, but creates a link_to <a>, not a <button>.
  #
  #  <%= button_link :big, "Sign up", new_user_path %>
  def button_link(size_identifier, label, url, options = {})
    options[:class] = "#{size_identifier} button_link"
    link_to(%{<span>#{label}</span>}, url, options)
  end

  # Array => HTML list. The option hash is applied to the <ul> tag.
  #
  #  <%= list(items) {|i| i.title } %>
  #  <%= list(items, :class => "foo") {|i| link_to i, foo_path }
  def list(items, options = {})
    list_items = items.map {|i| %{<li>#{block_given? ? yield(i) : i}</li>} }.join("\n")
    content_tag(:ul, list_items, options)
  end

  def summary_box(title, content, image)
    %{
      <div class="summary_box">
        <div class="summary_box_image">
          #{image}
        </div>

        <div class="summary_box_content">
          <strong>#{title}</strong>
          #{content}
        </div>

        <div class="clear"></div>
      </div>
    }.html_safe
  end

  def project_summary_box(project)
    summary_box link_to(project.title, project),
      truncate(project.descriptions_first_paragraph, 80),
      glossy_homepage_avatar(default_avatar)
  end

  def team_summary_box(team)
    text = list([
      "Created: #{team.created_at.strftime("%B #{team.created_at.strftime("%d").to_i.ordinalize} %Y")}",
      "Total activities: #{team.event_count}"
    ], :class => "simple")

    summary_box link_to(team.name, group_path(team)),
      text,
      glossy_homepage_avatar(team.avatar? ? image_tag(team.avatar.url(:thumb), :width => 30, :height => 30) : default_avatar)
  end

  def user_summary_box(user)
    text = text = list([
      "Projects: #{user.projects.count}",
      "Total activities: #{user.events.count}"
    ], :class => "simple")

    summary_box link_to(user.login, user),
      text,
      glossy_homepage_avatar_for_user(user)
  end

  def glossy_homepage_avatar(avatar)
    content_tag(:div, avatar + "<span></span>", :class => "glossy_avatar_wrapper")
  end

  def glossy_homepage_avatar_for_user(user)
    glossy_homepage_avatar(avatar(user, :size => 30, :default => "images/icon_default.png"))
  end

  def default_avatar
    image_tag("icon_default.png", :width => 30, :height => 30)
  end

  def comment_applies_to_merge_request?(parent)
    MergeRequest === parent && (logged_in? && can_resolve_merge_request?(current_user, parent))
  end

  def statuses_for_merge_request_for_select(merge_request)
    merge_request.target_repository.project.merge_request_statuses.map do |status|
      if status.description.blank?
        [h(status.name), h(status.name)]
      else
        [h("#{status.name} - #{status.description}"), h(status.name)]
      end
    end
  end

  def include_stylesheets(group)
    stylesheets = STYLESHEETS[group]
    cache_name = "gts-#{group}"
    additional = Gitorious::Configuration.get("#{group}_stylesheets")

    unless additional.nil?
      additional = [additional] unless Array === additional
      stylesheets.concat(additional)
      cache_name << "-#{additional.join('-').gsub(/[^a-z0-9_\-]/, '-')}"
      cache_name = cache_name.gsub(/-+/, '-')
    end

    stylesheet_link_tag stylesheets, :cache => cache_name
  end

  # The javascripts to be included in all layouts
  def include_javascripts
    jquery = ["", "/autocomplete", "/cookie", "/color_picker", "/cycle.all.min",
              "/ui", "/ui/selectable", "/scrollto", "/expander",
              "/timeago","/pjax"].collect { |f| "lib/jquery#{f}" }

    gitorious = ["", "/observable", "/application", "/resource_toggler", "/jquery",
                 "/merge_requests", "/diff_browser", "/messages", "/live_search",
                 "/repository_search"].collect { |f| "gitorious#{f}" }

    scripts = jquery + ["core_extensions"] + gitorious + ["rails.js", "lib/spin.js/spin.js", "application"]

    javascript_include_tag(scripts, :cache => true)
  end

  def favicon_link_tag
    url = Gitorious::Configuration.get("favicon_url", "/favicon.ico")
    "<link rel=\"shortcut icon\" href=\"#{url}\" type=\"image/x-icon\">".html_safe
  end

  def logo_link
    logo = Gitorious::Configuration.get("logo_url", "/ui3/images/gitorious2013.png")
    link_to(logo.blank? ? "Gitorious" : image_tag(logo), root_path)
  end

  # inserts a <wbr> tag somewhere in the middle of +str+
  def wbr_middle(str)
    half_size = str.length / 2
    (str.to_s[0..half_size-1] + "<wbr />" + str[half_size..-1]).html_safe
  end

  def time_ago(time, options = {})
    return unless time
    options[:class] ||= "timeago"
    content_tag(:abbr, time.to_s, options.merge(:title => time.getutc.iso8601))
  end

  def white_button_link_to(label, url, options = {})
    size = options.delete(:size) || "small"
    css_classes = ["white-button", "#{size}-button"]
    if extra_class = options.delete(:class)
      css_classes << extra_class
    end
    content_tag(:div, link_to(label, url, :class => "round-10"),
        :id => options.delete(:id), :class => css_classes.flatten.join(" "))
  end

  def link_button_link_to(label, url, options = {})
    size = options.delete(:size) || "small"
    css_classes = ["button", "#{size}-button"]
    if extra_class = options.delete(:class)
      css_classes << extra_class
    end
    content_tag(:div, link_to(label, url, :class => "", :confirm => options[:confirm]),
        :id => options.delete(:id), :class => css_classes.flatten.join(" "))
  end

  def render_pagination_links(collection, options = {})
    default_options = {
      :previous_label => "Previous",
      :next_label => "Next",
      :container => "True"
    }
    (will_paginate(collection, options.merge(default_options)) || "").html_safe
  end

  def dashboard_path
    root_url(:host => Gitorious.host, :protocol => Gitorious.scheme)
  end

  def site_domain
    host = Gitorious.host
    port = Gitorious.port
    port = port.to_i != 80 ? ":#{port}" : ""
    "#{host}#{port}"
  end

  def fq_root_link
    Gitorious.url("/")
  end

  def url?(setting)
    !Gitorious::View.send(:"#{setting}_url").blank?
  end

  def footer_link(setting, html_options={})
    url = Gitorious::View.send(:"#{setting}_url")
    text = t("views.layout.#{setting}")
    "<li>#{link_to text, url, html_options}</li>".html_safe
  end

  def namespaced_atom_feed(options={}, &block)
    options["xmlns:gts"] = "http://gitorious.org/schema"
    atom_feed(options, &block)
  end

  # Temporary - Rails 3 removed error_messages_for
  def error_messages(model)
    errors = model.is_a?(Array) ? model : model.errors.full_messages
    return "" if !errors.any?
    result = errors.inject("") { |memo, obj| memo << content_tag(:li, obj) }
    header = content_tag(:h2, pluralize(errors.size, "error"))
    %[<div class="errorExplanation alert alert-block alert-error" id="errorExplanation">#{header}<ul>#{result}</ul></div>].html_safe
  end

  def vcs_link_tag(options)
    content_for :extra_head do
      (<<-HTML).html_safe
        <link rel="vcs-git" href="#{h(options[:href])}" title="#{h(options[:title])}">
      HTML
    end
  end

  def long_ordinal(date)
    date.strftime("%B #{date.day.ordinalize}, %Y")
  end

  def live_md_preview_textarea(form, method, label)
    <<-HTML.html_safe
      <div id="markdown-preview" class="gts-markdown-preview help-block">
        <h2>#{label} preview</h2>
        <div></div>
      </div>
      <div class="control-group">
        #{form.label(method, label, :class => "control-label")}
        <div class="controls">
          #{form.text_area(method, :class => "input-xxlarge gts-live-markdown-preview", :"data-gts-preview-target" => "markdown-preview", :rows => 5)}
          <p class="help-block">
            Use <a data-toggle="collapse" data-target="#markdown-help" class="dropdown-toggle" href="#markdown-help">Markdown</a> for formatting
          </p>
          #{markdown_help}
        </div>
      </div>
    HTML
  end

  # Used for compatibility with Dolt views
  def partial(template, locals = {})
    render(:template => template, :locals => locals).html_safe
  end
end
