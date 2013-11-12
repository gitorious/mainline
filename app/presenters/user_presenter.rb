class UserPresenter < SimpleDelegator
  attr_reader :user, :view
  private :user, :view

  def initialize(user, view)
    @user = user
    @view = view
    super(user)
  end

  def avatar_link
    view.link_to("#{avatar} #{title}".html_safe, view.user_path(user))
  end

  def avatar
    view.avatar(user, :size => 16, :class => 'gts-avatar').html_safe
  end
end
