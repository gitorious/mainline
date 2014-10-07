# encoding: utf-8
#--
#   Copyright (C) 2011-2014 Gitorious AS
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
require "gitorious/authorized_filter"

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include ActsAsTaggableOn::TagsHelper
  include UsersHelper
  include EventRenderingHelper
  include RoutingHelper
  include SiteWikiPagesHelper
  include Gitorious::Authorization
  include GroupRoutingHelper
  include Gitorious::CacheInPrivateHelper
  include DoltViewHelpers
  include Gitorious::View::AvatarHelper

  STYLESHEETS = {
    :common => ["content", "sidebar", "forms", "buttons", "base"],
    :external => ["external"]
  }

  def link_to_help(id)
    link_to(
      '<i class="icon icon-question-sign"></i>'.html_safe,
      "##{id}", :class => 'gts-help-link', :data => { :toggle => 'modal' }
    )
  end

  def modal_box(title, id, &block)
    content_tag(:div, :class => 'modal hide', :id => id) {
      body_html = content_tag(:div, :class => 'modal-header') {
        header_html = button_tag 'x', :class => 'close', :data => { :dismiss => 'modal' }
        header_html << content_tag(:h3, title)
        header_html.html_safe
      }
      body_html << content_tag(:div, capture(&block), :class => 'modal-body')
      body_html.html_safe
    }.html_safe
  end

  # TODO: refactor this and make it more flexible - solnic
  def pull_box(title, options = {}, &block)
    dom_id  = options[:id]
    opened  = options.fetch(:opened, true)

    classes = %w(pull-box-container).concat(Array(options.fetch(:class, [])).compact)
    classes << 'closed' unless opened

    title_html =
      if title
        content_tag(:div, "<h3>#{title}</h3>".html_safe, :class => 'pull-box-header')
      else
        ""
      end

    tag_opts = { :class => classes }
    tag_opts.update(:id => dom_id) if dom_id

    content_tag(:div, tag_opts) {
      title_html + content_tag(:div, capture(&block), :class => 'pull-box-content')
    }.html_safe
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

  def render_markdown(text)
    renderer = Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(filter_html: true, hard_wrap: true),
      no_intra_emphasis: true,
      autolink: true
    )

    renderer.render(text).html_safe
  end

  def feed_icon(url, alt_title = "Atom feed", size = :small)
    link_to(image_tag("silk/feed.png", :class => "feed_icon"), url,
            :alt => alt_title, :title => alt_title)
  end

  def linked_tag_list_as_sentence(tags)
    tags.map do |tag|
      link_to(h(tag.name), search_path(:q => "@category #{h(tag.name)}"))
    end.to_sentence.html_safe
  end

  def build_notice_for(object, options = {})
    out =  %Q{<div class="being_constructed round-10">}
    out <<  %Q{<div class="being_constructed_content round-10">}
    out << %Q{  <p>#{I18n.t( "application_helper.notice_for_html", :class_name => object.class.name.humanize.downcase)}</p>}
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

  def current_site
    controller.current_site
  end

  # Array => HTML list. The option hash is applied to the <ul> tag.
  #
  #  <%= list(items) {|i| i.title } %>
  #  <%= list(items, :class => "foo") {|i| link_to i, foo_path }
  def list(items, options = {})
    list_items = items.map {|i| %{<li>#{block_given? ? yield(i) : i}</li>} }.join("\n")
    content_tag(:ul, list_items, options)
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

  def merge_request_statuses_json(merge_request)
    if can_resolve_merge_request?(current_user, merge_request)
      statuses = merge_request.target_repository.project.merge_request_statuses.map(&:name)
    else
      statuses = []
    end

    statuses.to_json
  end

  def logo_link
    logo = Gitorious::Configuration.get("logo_url", "/dist/images/gitorious2013.png")
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

  def render_pagination_links(collection, options = {})
    default_options = {
      :previous_label => '',
      :next_label => "Next",
      :container => "True"
    }
    (will_paginate(collection, options.merge(default_options)) || "").html_safe
  end

  def site_domain
    host = Gitorious.host
    port = Gitorious.port
    port = port.to_i != 80 ? ":#{port}" : ""
    "#{host}#{port}"
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
    content_for(:head) do
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

  def site_header(options = {}, &block)
    content_tag(:div, options.merge(:class => 'gts-site-header')) {
      content_tag(:div, :class => 'container', &block)
    }
  end

  def inside_layout(name, locals = {})
    view_flow.set :layout, capture { yield }
    render template: "layouts/#{name}", :locals => locals
  end
end
