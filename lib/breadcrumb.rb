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
      @paths.last || "/"
    end
  end  
end
