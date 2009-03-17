module EventRenderingHelper
  def render_event_create_project(event)
    action = action_for_event(:event_status_created) do 
      link_to h(event.target.title), project_path(event.target)
    end
    body = truncate(event.target.stripped_description, :length => 100)
    category = "project"
    [action, body, category]
  end
  
  def render_event_delete_project(event)
    action = action_for_event(:event_status_deleted){ h(event.data) }
    category = "project"
    [action, "", category]
  end
  
  def render_event_update_project(event)
    action = action_for_event(:event_status_updated) do
      link_to h(event.target.title), project_path(event.target)
    end
    category = "project"
    [action, "", category]
  end
  
  def render_event_clone_repository(event)
    original_repo = Repository.find_by_id(event.data.to_i)
    return ["", "", ""] if original_repo.nil?
    
    project = event.target.project
    
    action = action_for_event(:event_status_cloned) do
      link_to(h(project.slug), project_path(project)) + "/" + 
      link_to(h(original_repo.name), project_repository_url(project, original_repo)) + 
      " in " + link_to(h(event.target.name), project_repository_url(project, event.target))
    end
    category = "repository"
    [action, "", category]
  end
  
  def render_event_delete_repository(event)
    action = action_for_event(:event_status_deleted) do 
      link_to(h(event.target.title), project_path(event.target)) + "/" + h(event.data)
    end
    category = "project"
    [action, "", category]
  end
  
  def render_event_commit(event)
    project = event.project
    repo = event.target
    
    case repo.kind
    when Repository::KIND_WIKI
      action = action_for_event(:event_status_push_wiki) do
        "to " + link_to(h(project.slug), project_path(project)) + 
        "/" + link_to(h(t("views.layout.pages")), project_pages_url(project))
      end
      body = h(truncate(event.body, :length => 150))
      category = "wiki"
    when 'commit'
      action = action_for_event(:event_status_committed) do
        link_to(event.data[0,8], project_repository_commit_path(project, repo, event.data)) + 
        " to " + link_to(h(project.slug), project)
      end
      body = link_to(h(truncate(event.body, :length => 150)), 
              project_repository_commit_path(project, repo, event.data))
      category = "commit"
    else
      action = action_for_event(:event_status_committed) do
        link_to(event.data[0,8], repo_owner_path(repo, :project_repository_commit_path, project, repo, event.data)) +
        " to " + link_to(h(project.slug), project)
      end
      body = link_to(h(truncate(event.body, :length => 150)), project_repository_commit_path(project, repo, event.data))
      category = "commit"
    end
    
    [action, body, category]
  end
  
  def render_event_create_branch(event)
    project = event.target.project
    if event.data == "master"
      action = action_for_event(:event_status_started) do
        "of " + link_to(h(project.slug), project_path(project)) + "/" + 
        link_to(h(event.target.name), project_repository_url(project, event.target))
      end
      body = h(event.body)
    else
      action = action_for_event(:event_branch_created) do
        link_to(h(event.data), project_repository_tree_path(project, event.target, event.data)) + 
        " on " + link_to(h(project.slug), project_path(project)) + "/" + 
        link_to(h(event.target.name), project_repository_url(project, event.target))
      end
    end
    category = "commit"
    [action, "", category]
  end
  
  def render_event_delete_branch(event)
    project = event.target.project
    action = action_for_event(:event_branch_deleted) do 
      h(event.data)  + " on " + link_to(h(project.slug), project_path(project)) + 
      "/" + link_to(h(event.target.name), project_repository_url(project, event.target))
    end
    category = "commit"
    [action, "", category]
  end
  
  def render_event_create_tag(event)
    project = event.target.project
    action = action_for_event(:event_tagged) do
      link_to(h(project.slug), project_path(project))  + "/" + 
      link_to(h(event.target.name), project_repository_url(project, event.target))
    end
    body = link_to(h(event.data), project_repository_commit_path(project, event.target, h(event.data))) + 
            "<br/>" + h(event.body)
    category = "commit"
    [action, body, category]
  end
  
  def render_event_delete_tag(event)
    action = action_for_event(:event_tag_deleted) do
      h(event.data) + " on " + link_to(h(project.slug), project_path(event.project.project)) + 
      "/" + link_to(h(event.target.name), @template.project_repository_url(event.project, event.target))
    end
    category = "commit"
    [action, "", category]
  end
  
  def render_event_add_committer(event)
    repo = event.target
    action = action_for_event(:event_committer_added, :committer => h(event.data)) do
      " to " + link_to(h(repo.project.slug), project_path(repo.project)) + "/" + 
      link_to(h(repo.name), project_repository_url(repo.project, repo))
    end
    category = "repository"
    [action, "", category]
  end
  
  def render_event_remove_committer(event)
    repo = event.target
    action = action_for_event(:event_committer_removed, :committer => h(event.data)) do
      " from " + link_to(h(repo.project.slug), project_path(repo.project)) + "/" + 
      link_to(h(repo.name), project_repository_url(repo.project, repo))
    end
    category = "repository"
    [action, "", category]
  end
  
  def render_event_comment(event)
    project = event.target.project
    repo = event.target.target.target
    
    action = action_for_event(:event_commented) do
      " on " +  link_to(h(project.slug), project_path(project)) + "/" + 
      link_to(h(repo.name), [project, repo])
    end
    unless event.target.sha1.blank?
      action << "/" + link_to(h(event.target.sha1[0,7]), 
          repo_owner_path(repo, :project_repository_commit_path, project, repo, event.target.sha1))
    end
    body = truncate(h(event.target.body), :length => 150)
    category = "comment"
    [action, body, category]
  end
  
  def render_event_request_merge(event)
    source_repository = event.target.source_repository
    project = source_repository.project
    target_repository = event.target.target_repository
    
    action = action_for_event(:event_requested_merge_of) do
      link_to(h(project.slug), project_path(project)) + "/" + 
      link_to(h(source_repository.name), project_repository_url(project, source_repository)) + 
      " with " + link_to(h(project.slug), project_path(project)) + "/" + 
      link_to(h(target_repository.name))
    end
    body = link_to truncate(h(event.target.proposal), :length => 100), [project, target_repository, event.target]
    category = "merge_request"
    [action, body, category]
  end
  
  def render_event_resolve_merge_request(event)
    source_repository = event.target.source_repository
    project = source_repository.project
    target_repository = event.target.target_repository
    
    action = action_for_event(:event_resolved_merge_request) do
      "as " + "[#{event.target.status_string}] from " + 
      link_to(h(project.slug), project_path(project)) + "/" + 
      link_to(h(source_repository.name), project_repository_url(project, source_repository))
    end
    body = link_to truncate(h(event.target.proposal), :length => 100), [project, target_repository, event.target]
    category = "merge_request"
    [action, body, category]
  end
  
  def render_event_update_merge_request(event)
    source_repository = event.target.source_repository
    project = source_repository.project
    target_repository = event.target.target_repository
    
    action = action_for_event(:event_updated_merge_request) do
      "from " + 
      link_to(h(project.title), project_path(project)) + "/" + 
      link_to(h(source_repository.name), project_repository_url(project, source_repository))
    end
    category = "merge_request"
    [action, "", category]
  end
  
  def render_event_delete_merge_request(event)
    project = event.target.project
    
    action = action_for_event(:event_deleted_merge_request) do
      "from " + link_to(h(project.slug), project_path(project)) + "/" + 
      link_to(h(target.name), project_repository_url(project, event.target))
    end
    category = "merge_request"
    [action, "", category]
  end
  
  def render_event_edit_wiki_page(event)
    project = event.target
    action = action_for_event(:event_updated_wiki_page) do
      link_to(h(project.slug), project_path(project)) + "/" + 
      link_to(h(event.data), project_page_path(project, event.data))
    end
    category = "wiki"
    [action, "", category]
  end
  
  def render_event_push(event)
    project = event.target.project
    commit_link = link_to_remote_if(event.has_commits?, pluralize(event.events.size, 'commit'), :url => commits_event_path(event.to_param), :method => :get, :update => "commits_in_event_#{event.to_param}", :before => "$('commits_in_event_#{event.to_param}').toggle()")
    action = action_for_event(:event_pushed_n, :commit_link => commit_link) do
      " to " + link_to(h(project.slug), project_path(project)) + "/" + 
      link_to(h(event.target.name+':'+event.data), repo_owner_path(event.target, :project_repository_commits_in_ref_path, project, event.target, ensplat_path(event.data)))
    end
    body = h(event.body)
    category = 'push'
    [action, body, category]
  end
  
  def render_event_add_project_repository(event)
    action = action_for_event(:event_status_add_project_repository) do
      link_to(h(event.target.name), project_repository_path(event.project, event.target)) + 
              " to " + link_to(h(event.project.title), project_path(event.project))
    end
    body = truncate(sanitize(event.target.description), :length => 100)
    category = "repository"
    [action, body, category]
  end
  
  protected
    def action_for_event(i18n_key, opts = {}, &block)
      header = "<strong>" + I18n.t("application_helper.#{i18n_key}", opts) + "</strong> "
      header + capture(&block)
    end
end
