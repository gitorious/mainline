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
      "Wiki pages"
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
  
  class Participations
    def initialize(repository)
      @repository = repository
    end
    
    def breadcrumb_parent
      @repository
    end
    
    def title
      "Commit teams"
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
end
