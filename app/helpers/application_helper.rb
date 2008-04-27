# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include TagsHelper
  
  def default_css_tag_sizes
    %w(tag_size_1 tag_size_2 tag_size_3 tag_size_4)
  end
  
  def linked_tag_list_as_sentence(tags)
    tags.map do |tag|
      link_to(h(tag.name), search_path(:q => "category:#{h(tag.name)}"))
    end.to_sentence
  end
  
  def build_notice_for(object)
    out =  %Q{<div class="being_constructed">}
    out << %Q{  <p>This #{object.class.name.humanize.downcase} is being created,<br />}
    out << %Q{  it will be ready pretty soon&hellip;</p>}
    out << %Q{</div>}
    out
  end
  
  def render_if_ready(object, &blk)
    if object.respond_to?(:ready?) && object.ready?
      yield
    else
      concat(build_notice_for(object), blk.binding)
    end
  end  
  
  def selected_if_current_page(url_options, slack = false)
    if slack
      if controller.request.request_uri.index(CGI.escapeHTML(url_for(url_options))) == 0
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
    out.join("\n")
  end
  
  def base_url(full_url)
    URI.parse(full_url).host
  end
  
  def gravatar_url_for(email, options = {})
    "http://www.gravatar.com/avatar.php?gravatar_id=" << 
    Digest::MD5.hexdigest(email) << 
    "&amp;default=" <<
    u("http://#{request.host}:#{request.port}/images/default_face.gif") <<
    options.map { |k,v| "&amp;#{k}=#{v}" }.join
  end
  
  def gravatar(email, options = {})
    size = options[:size]
    image_options = { :alt => "avatar" }
    if size
      image_options.merge!(:width => size, :height => size)
    end
    image_tag(gravatar_url_for(email, options), image_options)
  end
  
  def gravatar_frame(email, options = {})
    extra_css_class = options[:style] ? " gravatar_#{options[:style]}" : ""
    %{<div class="gravatar#{extra_css_class}">#{gravatar(email, options)}</div>}
  end
  
  def flashes
    flash.map { |type, content| content_tag(:div, content_tag(:p, content), :class => "flash_message #{type}")}
  end
  
  def commit_graph_tag(repository, ref = "master")
    filename = Gitorious::Graphs::CommitsBuilder.filename(repository, ref)
    if File.exist?(File.join(Gitorious::Graphs::Builder.graph_dir, filename))
      image_tag("graphs/#{filename}")
    end
  end
  
  def commit_graph_by_author_tag(repository, ref = "master")    
    filename = Gitorious::Graphs::CommitsByAuthorBuilder.filename(repository, ref)
    if File.exist?(File.join(Gitorious::Graphs::Builder.graph_dir, filename))
      image_tag("graphs/#{filename}")
    end
  end
  
  def action_and_body_for_event(event)
    target = event.target
    action = ""
    body = ""
    category = ""
    case event.action
      when Action::CREATE_PROJECT
        action = "<strong>created project</strong> #{link_to h(target.title), project_path(target)}"
        body = truncate(target.stripped_description, 100)
        category = "project"
      when Action::DELETE_PROJECT
        action = "<strong>deleted project</strong> #{h(event.data)}"
        category = "project"
      when Action::UPDATE_PROJECT
        action = "<strong>updated project</strong> #{link_to h(target.title), project_path(target)}"
        category = "project"
      when Action::CLONE_REPOSITORY
        original_repo = Repository.find_by_id(event.data.to_i)
        next if original_repo.nil?
        
        project = target.project
        
        action = "<strong>forked</strong> #{link_to h(project.title), project_path(project)}/#{link_to h(original_repo.name), project_repository_url(project, original_repo)} in #{link_to h(target.name), project_repository_url(project, target)}"
        category = "repository"
      when Action::DELETE_REPOSITORY
        action = "<strong>deleted repository</strong> #{link_to h(target.title), project_path(target)}/#{event.data}"
        category = "project"
      when Action::COMMIT
        project = target.project
        action = "<strong>committed</strong> #{link_to event.data[0,8], project_repository_commit_path(project, target, event.data)} to #{link_to h(project.slug), project_path(project)}/#{link_to h(target.name), project_repository_url(project, target)}"
        body = "<code>#{truncate(event.body, 150)}</code>"
        category = "commit"
      when Action::CREATE_BRANCH
        project = target.project
        if event.data == "master"
          action = "<strong>started development</strong> of #{link_to h(project.title), project_path(project)}/#{link_to h(target.name), project_repository_url(project, target)}"
          body = event.body
        else
          action = "<strong>created branch</strong> #{link_to h(event.data), project_repository_tree_path(project, target, event.data)} on #{link_to h(project.title), project_path(project)}/#{link_to h(target.name), project_repository_url(project, target)}"
        end
        category = "commit"
      when Action::DELETE_BRANCH
        project = target.project
        action = "<strong>deleted branch</strong> #{event.data} on #{link_to h(project.title), project_path(project)}/#{link_to h(target.name), project_repository_url(project, target)}"
        category = "commit"
      when Action::CREATE_TAG
        project = target.project
        action = "<strong>tagged</strong> #{link_to h(project.title), project_path(project)}/#{link_to h(target.name), project_repository_url(project, target)}"
        body = "#{link_to event.data, project_repository_commit_path(project, target, event.data)}<br/>#{event.body}"
        category = "commit"
      when Action::DELETE_TAG
        project = target.project
        action = "<strong>deleted tag</strong> #{event.data} on #{link_to h(project.title), project_path(project)}/#{link_to h(target.name), project_repository_url(project, target)}"
        category = "commit"
      when Action::ADD_COMMITTER
        user = target.user
        repo = target.repository
        action = "<strong>added committer</strong> #{link_to user.login, user_path(user)} to #{link_to h(repo.project.title), project_path(repo.project)}/#{link_to h(repo.name), project_repository_url(repo.project, repo)}"
        category = "repository"
      when Action::REMOVE_COMMITTER
        user = User.find_by_id(event.data.to_i)
        next unless user
        
        project = target.project
        action = "<strong>removed committer</strong> #{link_to user.login, user_path(user)} from #{link_to h(project.title), project_path(project)}/#{link_to h(target.name), project_repository_url(project, target)}"
        category = "repository"
      when Action::COMMENT
        project = target.project
        repo = target.repository
        
        action = "<strong>commented</strong> on #{link_to h(project.title), project_path(project)}/#{link_to h(repo.name), project_repository_url(project, repo)}"
        body = truncate(h(target.body), 150)
        category = "comment"
      when Action::REQUEST_MERGE
        source_repository = target.source_repository
        project = source_repository.project
        target_repository = target.target_repository
        
        action = "<strong>requested merge</strong> #{link_to h(project.title), project_path(project)}/#{link_to h(source_repository.name), project_repository_url(project, source_repository)} to #{link_to h(project.title), project_path(project)}/#{link_to h(target_repository.name)}"
        body = "#{link_to "review", [project, target_repository, target]}<br/>#{truncate(h(target.proposal), 100)}"
        category = "merge request"
      when Action::RESOLVE_MERGE_REQUEST
        source_repository = target.source_repository
        project = source_repository.project
        target_repository = target.target_repository
        
        action = "<strong>resolved merge request </strong>to [#{target.status_string}] from #{link_to h(project.title), project_path(project)}/#{link_to h(source_repository.name), project_repository_url(project, source_repository)}"
        category = "merge_request"
      when Action::UPDATE_MERGE_REQUEST
        source_repository = target.source_repository
        project = source_repository.project
        target_repository = target.target_repository
        
        action = "<strong>updated merge request</strong> from #{link_to h(project.title), project_path(project)}/#{link_to h(source_repository.name), project_repository_url(project, source_repository)}"
        category = "merge_request"
      when Action::DELETE_MERGE_REQUEST
        project = target.project
        
        action = "<strong>deleted merge request</strong> from #{link_to h(project.title), project_path(project)}/#{link_to h(target.name), project_repository_url(project, target)}"
        category = "merge_request"
    end
      
    [action, body, category]
  end
  
  def sidebar_content?
    !@content_for_sidebar.blank?
  end
end
