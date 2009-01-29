module Gitorious
  module Reservations
    silence_warnings do
      UNACCOUNTED_ROOT_NAMES = ["teams", "dashboard", "about", "login", "logout"]
      RESERVED_ROOT_NAMES = UNACCOUNTED_ROOT_NAMES + Dir[File.join(RAILS_ROOT, "public", "*")].map{|f| File.basename(f) }
      CONTROLLER_NAMES_PLURAL = ActionController::Routing.possible_controllers.map{|s| s.split("/").first }
      CONTROLLER_NAMES = CONTROLLER_NAMES_PLURAL + CONTROLLER_NAMES_PLURAL.map{|s| s.singularize }
      PROJECTS_MEMBER_ACTIONS = %w[edit update destroy confirm_delete]
    
      PROJECT_NAMES = RESERVED_ROOT_NAMES + CONTROLLER_NAMES
      REPOSITORY_NAMES = PROJECTS_MEMBER_ACTIONS + CONTROLLER_NAMES
    end
  end
end
