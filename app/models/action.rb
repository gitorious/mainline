class Action
  CREATE_PROJECT = 0
  DELETE_PROJECT = 1
  UPDATE_PROJECT = 2
  CLONE_REPOSITORY = 3
  DELETE_REPOSITORY = 4
  COMMIT = 5
  CREATE_BRANCH = 6
  DELETE_BRANCH = 7
  CREATE_TAG = 8
  DELETE_TAG = 9
  ADD_COMMITTER = 10
  REMOVE_COMMITTER = 11
  COMMENT = 12
  REQUEST_MERGE = 13
  RESOLVE_MERGE_REQUEST = 14
  UPDATE_MERGE_REQUEST = 15
  DELETE_MERGE_REQUEST = 16
  
  def self.name(action_id)
    case action_id
      when CREATE_PROJECT
        "create project"
      when DELETE_PROJECT
        "delete project"
      when UPDATE_PROJECT
        "update project"
      when CLONE_REPOSITORY
        "clone repository"
      when DELETE_REPOSITORY
        "delete repository"
      when COMMIT
        "commit"
      when CREATE_BRANCH
        "create branch"
      when DELETE_BRANCH
        "delete branch"
      when CREATE_TAG
        "create tag"
      when DELETE_TAG
        "delete tag"
      when ADD_COMMITTER
        "add committer"
      when REMOVE_COMMITTER
        "remove committer"
      when COMMENT
        "comment"
      when REQUEST_MERGE
        "request merge"
      when RESOLVE_MERGE_REQUEST
        "resolve merge request"
      when UPDATE_MERGE_REQUEST
        "update merge request"
      when DELETE_MERGE_REQUEST
        "delete merge request"
    end
  end
end
