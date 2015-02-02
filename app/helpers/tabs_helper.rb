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

module TabsHelper

  def user_edit_tabbable(options, &block)
    tabs = {
      'account'       => edit_user_path(current_user),
      'email-aliases' => user_edit_email_aliases_path(current_user),
    }

    unless Gitorious::Authentication::Configuration.authentication_method('LDAP')
      tabs['change-password'] = user_edit_password_path(current_user)
    end

    tabs.merge!({
      'ssh-keys'         => user_edit_ssh_keys_path(current_user),
      'manage-favorites' => user_edit_favorites_path(current_user)
    })

    tabbable(tabs, options.reverse_merge(:active => 'account'), &block)
  end

  def activity_tabbable(options = {}, &block)
    pjax_tabbable({
      'activities'    => root_path,
      'my-activities' => dashboard_my_activities_path },
      options.reverse_merge(:active => 'activities'), &block
    )
  end

  def tabbable(tabs, options = {}, &block)
    position = options.fetch(:position, 'top')
    names    = tabs.is_a?(Hash) ? tabs.keys : tabs
    active   = (names.include?(params[:tab]) && params[:tab]) || options[:active]

    content_tag(:div, :class => "tabbable tabs-#{position}") {
      classes = %w(nav nav-tabs)
      classes << 'gts-pjax' if options[:pjax]

      opts = {
        :active => active,
        :class  => options.fetch(:nav, classes),
        :pjax   => options[:pjax]
      }

      html =  nav_tabs(tabs, opts)
      html << tab_content(options, &block) if block
      html
    }.html_safe
  end

  def pjax_tabbable(tabs, options = {}, &block)
    tabbable(tabs, options.merge(:pjax => true), &block)
  end

  def nav_tabs(tabs, opts = {})
    active  = opts.fetch(:active, false)
    classes = opts.fetch(:class)

    content_tag(:ul, :class => classes, :data => { :active => active }) {
      tabs.map { |name, path|
        class_names = []
        class_names << 'active' if name == active
        content_tag(:li, nav_link(name, path, opts), :class => class_names)
      }.join("\n").html_safe
    }
  end

  def nav_link(name, path, options = {})
    path ||= "##{name}"
    data = options[:pjax] ? {} : { :toggle => 'tab', :target => "##{name.to_s.dasherize}" }

    link_to(t("views.tabs.#{name.underscore}"), path, :data => data)
  end

  def tab_content(options = {}, &block)
    class_names = %w(tab-content)
    dom_id      = 'gts-pjax-container' if options[:pjax]

    content_tag(:div, :class => class_names, :id => dom_id) {
      capture(&block) if block
    }.html_safe
  end

  def tab_pane(id, options = {}, &block)
    active = options.fetch(:active, false)

    class_names = %w(tab-pane)
    class_names << 'active' if active

    content_tag(:div, :class => class_names, :id => id.to_s.dasherize) {
      capture(&block) if block
    }
  end

end
