class CommittershipPresenter
  def self.for(committership, view_context)
    new(committership, view_context)
  end

  def self.collection(committerships, view_context)
    committerships.map { |c| CommittershipPresenter.for(c, view_context) }
  end

  attr_reader :committership, :view_context
  alias :v :view_context

  def initialize(committership, view_context)
    @committership = committership
    @view_context = view_context
  end

  def label
    label_type = " (#{committership.committer.class.human_name})"
    if super_group?
      v.link_to("Super Group", "/about/faq")
    else
      v.link_to(committership.committer.title, committership.committer)
    end + label_type
  end

  def permissions
    committership.permission_list.join(', ')
  end

  def creator
    v.link_to(committership.creator.login, committership.creator) if committership.creator
  end

  def created_at
    v.l(committership.created_at, :format => :short)
  end

  def actions
    return super_group_actions if super_group?
    edit_link + delete_link
  end

  private

  def edit_link
    edit_url_params = [:edit, project, repository, committership]
    v.link_to(v.t("views.common.edit"), edit_url_params, :method => :get, :class => "btn")
  end

  def delete_link
    delete_url_params = [project, repository, committership]
    v.link_to(v.t("views.common.remove"), delete_url_params,
              :method => :delete, :class => "btn btn-danger",
              :confirm => confirmation_required?)
  end

  def confirmation_required?
    if last_admin?
      "You are about to remove the last committer with admin rights. Are you sure about this?"
    end
  end

  def last_admin?
    repository.committerships.last_admin?(committership)
  end

  def super_group_actions
    "<p>Super group can be disabled in global configuration</p>".html_safe
  end

  def project
    repository.project
  end

  def repository
    committership.repository
  end

  def super_group?
    committership.id == SuperGroup.id
  end
end
