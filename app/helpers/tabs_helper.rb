module TabsHelper

  def user_edit_tabbable(options, &block)
    tabbable({
      'my-details'       => user_edit_my_details_path(current_user),
      'change-password'  => user_edit_password_path(current_user),
      'ssh-keys'         => user_edit_ssh_keys_path(current_user),
      'manage-favorites' => user_edit_favorites_path(current_user) },
      options.reverse_merge(:position => 'left', :active => 'my-details'), &block
    )
  end

  def tabbable(tabs, options = {}, &block)
    position = options.fetch(:position, 'left')
    active   = (tabs.key?(params[:tab]) && params[:tab]) || options[:active]

    content_tag(:div, :class => "tabbable tabs-#{position}") {
      nav_tabs(tabs, active) + tab_content(&block)
    }.html_safe
  end

  def nav_tabs(tabs, active)
    content_tag(:ul, :class => 'nav nav-tabs', :data => { :active => active }) {
      tabs.map { |name, path|

        content_tag(:li, nav_link(name, path))
      }.join("\n").html_safe
    }
  end

  def nav_link(name, path)
    link_to(t("views.tabs.#{name.underscore}"), path,
      :data => { :toggle => 'tab', :target => "##{name.to_s.dasherize}" })
  end

  def tab_content(&block)
    content_tag(:div, :class => "tab-content") { capture(&block) }.html_safe
  end

  def tab_pane(id, &block)
    content_tag(:div, :class => 'tab-pane', :id => id.to_s.dasherize) { capture(&block) }
  end

end
