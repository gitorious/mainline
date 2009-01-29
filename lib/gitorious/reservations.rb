module Gitorious
  module Reservations
    RESERVED_ROOT_NAMES = ["teams"] + Dir[File.join(RAILS_ROOT, "public", "*")].map{|f| File.basename(f) }
    CONTROLLER_NAMES = ActionController::Routing.possible_controllers.map{|s| s.split("/").first }
    PROJECTS_MEMBER_ACTIONS = %w[edit update destroy confirm_delete]
    
    PROJECT_NAMES = RESERVED_ROOT_NAMES + CONTROLLER_NAMES
    REPOSITORY_NAMES = PROJECTS_MEMBER_ACTIONS + CONTROLLER_NAMES
  end
end
