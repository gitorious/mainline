module Breadcrumb
  class Branch
    def initialize(obj, parent)
      @object = obj
      @parent = parent
    end
    def breadcrumb_parent
      @parent
    end
    def title
      @object.name
    end
  end

  class Folder
    attr_reader :paths
    def initialize(options)
      @paths = options[:paths]
      @head = options[:head]
      @repository = options[:repository]
    end
    def breadcrumb_parent
      if @paths.blank?
        Branch.new(@head, @repository)
      else
        Folder.new(:paths => @paths[0..-2], :head => @head, :repository => @repository)
      end
    end

    def title
      @paths.last || '/'
    end

    def breadcrumb_css_class
      @paths.last.blank? ? "tree" : "folder"
    end
  end

  class Blob
    attr_reader :path
    def initialize(options)
      @name = options[:name]
      @path = options[:paths]
      @parent = Folder.new(:paths => options[:paths][0..-2], :head => options[:head], :repository => options[:repository])
    end

    def title
      @name
    end

    def breadcrumb_parent
      @parent
    end

    def breadcrumb_css_class
      'file'
    end
  end

  class Commit
    attr_reader :sha
    def initialize(options)
      @repository = options[:repository]
      @sha = options[:id]
    end

    def breadcrumb_parent
      @repository
    end

    def title
      @sha
    end
  end

  class Wiki
    attr_reader :project
    def initialize(project)
      @project = project
    end

    def breadcrumb_parent
      @project
    end

    def title
      "Wiki"
    end

    def breadcrumb_css_class
      'wiki'
    end
  end

  class Page
    attr_reader :project, :page
    def initialize(page, project)
      @page = page
      @project = project
    end

    def breadcrumb_parent
      Wiki.new(@project)
    end

    def title
      @page.title
    end
    def breadcrumb_css_class
      'file'
    end
  end

  class Memberships
    def initialize(group)
      @group = group
    end
    attr_reader :group

    def breadcrumb_parent
      @group
    end

    def title
      "Members"
    end

    def breadcrumb_css_class
      "memberships"
    end
  end

  class NewMembership
    def initialize(group)
      @group = group
    end

    def breadcrumb_parent
      Memberships.new(@group)
    end

    def title
      I18n.t("views.memberships.new_breadcrumb")
    end

    def breadcrumb_css_class
      "add_membership"
    end
  end

  class GroupEdit
    def initialize(group)
      @group = group
    end

    def breadcrumb_parent
      @group
    end

    def title
      I18n.t("views.groups.edit_breadcrumb")
    end

    def breadcrumb_css_class
      "edit_group"
    end
  end

  class Committerships
    def initialize(repository)
      @repository = repository
    end

    def breadcrumb_parent
      @repository
    end

    def title
      "Collaborators"
    end
  end

  class MergeRequests
    def initialize(repository)
      @repository = repository
    end

    def breadcrumb_parent
      @repository
    end

    def title
      "Merge requests"
    end

    def breadcrumb_css_class
      "merge_requests"
    end
  end

  class EditRepository
    def initialize(repository)
      @repository = repository
    end

    def breadcrumb_parent
      @repository
    end

    def title
      I18n.t("views.repos.edit_breadcrumb")
    end

    def breadcrumb_css_class
      "update_repository"
    end
  end

  class NewRepository
    def initialize(project)
      @project = project
    end

    def breadcrumb_parent
      @project
    end

    def title
      I18n.t("views.projects.add_repository_breadcrumb")
    end

    def breadcrumb_css_class
      "add_project_repository"
    end
  end

  class CloneRepository
    def initialize(repository)
      @repository = repository
    end

    def breadcrumb_parent
      @repository
    end

    def title
      I18n.t("views.repos.clone_breadcrumb")
    end

    def breadcrumb_css_class
      "clone_repository"
    end
  end

  class EditProject
    def initialize(project)
      @project = project
    end

    def breadcrumb_parent
      @project
    end

    def title
      I18n.t("views.projects.edit_breadcrumb")
    end

    def breadcrumb_css_class
      "edit_project"
    end
  end

  class NewProject
    def initialize
    end

    def breadcrumb_parent
      nil
    end

    def title
      I18n.t("views.projects.new_breadcrumb")
    end

    def breadcrumb_css_class
      "new_project"
    end
  end

  class UserEdit
    def initialize(user)
      @user = user
    end

    def breadcrumb_parent
      Dashboard.new(@user)
    end

    def title
      I18n.t("views.users.edit_breadcrumb")
    end

    def breadcrumb_css_class
      "edit_account"
    end
  end

  class UserChangePassword
    def initialize(user)
      @user = user
    end

    def breadcrumb_parent
      Dashboard.new(@user)
    end

    def title
      I18n.t("views.users.chg_passwd_breadcrumb")
    end

    def breadcrumb_css_class
      "edit_account_password"
    end
  end

  class Aliases
    def initialize(user)
      @user = user
    end

    def breadcrumb_parent
      Dashboard.new(@user)
    end

    def title
      I18n.t("views.aliases.aliases_title")
    end

    def breadcrumb_css_class
      "alias"
    end
  end

  class NewAlias
  def initialize(user)
      @user = user
    end

    def breadcrumb_parent
      Aliases.new(@user)
    end

    def title
      I18n.t("views.aliases.new_alias_breadcrumb")
    end

    def breadcrumb_css_class
      "new_alias"
    end
  end

 class Keys
    def initialize(user)
      @user = user
    end

    def breadcrumb_parent
      Dashboard.new(@user)
    end

    def title
      I18n.t("views.keys.ssh_keys_breadcrumb")
    end

    def breadcrumb_css_class
      "key"
    end
  end

  class NewKey
  def initialize(user)
      @user = user
    end

    def breadcrumb_parent
      Keys.new(@user)
    end

    def title
      I18n.t("views.keys.add_ssh_key_breadcrumb")
    end

    def breadcrumb_css_class
      "new_key"
    end
  end

  class Messages
    def initialize(user)
      @user = user
    end

    def title
      I18n.t("views.messages.collection_title")
    end

    def breadcrumb_parent
      @user
    end

    def breadcrumb_css_class
      "emails"
    end
  end

  class Mailbox
    def initialize(user)
      @user = user
    end

    def breadcrumb_parent
      Messages.new(@user)
    end
  end

  class ReceivedMessages < Mailbox
    def title
      I18n.t("views.messages.received_messages")
    end

    def breadcrumb_css_class
      "received_emails"
    end
  end

  class AllMessages < Mailbox
    def title
      I18n.t("views.messages.all_messages")
    end

    def breadcrumb_css_class
      "all_emails"
    end
  end


  class SentMessages < Mailbox
    def title
      I18n.t("views.messages.sent_messages")
    end

    def breadcrumb_css_class
      "sent_emails"
    end
  end

  class EditOAuthSettings
    def initialize(project)
      @project = project
    end

    def breadcrumb_parent
      @project
    end

    def title
      "Contribution settings"
    end

    def breadcrumb_css_class
      "merge_requests"
    end
  end

  class Favorites
    def initialize(user)
      @user = user
    end

    def breadcrumb_parent
      Dashboard.new(@user)
    end

    def title
      "Favorites"
    end

    def breadcrumb_css_class
      "favorite"
    end
  end

  class Dashboard
    def initialize(user)
      @user = user
    end

    def breadcrumb_parent
      @user
    end

    def title
      "Dashboard"
    end

    def breadcrumb_css_class
      "dashboard"
    end
  end
end
