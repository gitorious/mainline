module TabsHelper

  def user_edit_tabbable(options, &block)
    tabbable(
      :my_details, :ssh_keys, :change_password, :manage_favorites,
      options.merge(:position => 'left'), &block
    )
  end

  def tabbable(*args, &block)
    options  = args.pop
    position = options.fetch(:position, 'left')
    active   = options[:active].to_s.dasherize

    content_tag(:div, :class => "tabbable tabs-#{position}") {
      nav_tabs(args, active) + tab_content(&block)
    }.html_safe
  end

  def nav_tabs(tabs, active)
    content_tag(:ul, :class => 'nav nav-tabs', :data => { :active => active }) {
      tabs.map { |name|
        link = link_to(t("views.tabs.#{name}"), "##{name.to_s.dasherize}", :data => { :toggle => 'tab' })
        content_tag(:li, link)
      }.join("\n").html_safe
    }
  end

  def tab_content(&block)
    content_tag(:div, :class => "tab-content") {
      capture(&block)
    }.html_safe
  end

  def tab_pane(id, &block)
    content_tag(:div, :class => 'tab-pane', :id => id.to_s.dasherize) { capture(&block) }
  end

end
