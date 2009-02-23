module Gitorious
  class Reservations
    class << self
      def unaccounted_root_names
        [ "teams", "dashboard", "about", "login", "logout", "commit", 
          "commits", "tree", "archive-tarball", "archive-zip" ]
      end
      
      def reserved_root_names
        @reserved_root_names ||= unaccounted_root_names + Dir[File.join(RAILS_ROOT, "public", "*")].map{|f| File.basename(f) }
      end
      
      def controller_names_plural
        return @controller_names_plural unless @controller_names_plural.blank?
        @controller_names_plural = ActionController::Routing.possible_controllers.map{|s| s.split("/").first }
      end
      
      def controller_names
        return @controller_names unless @controller_names.blank?
        @controller_names = controller_names_plural + controller_names_plural.map{|s| s.singularize }
      end
      
      def projects_member_actions 
        %w[edit update destroy confirm_delete]
      end
    
      def project_names
        @project_names ||= reserved_root_names + controller_names
      end
      
      def repository_names
        @repository_names ||= projects_member_actions + controller_names
      end
    end
  end
end
