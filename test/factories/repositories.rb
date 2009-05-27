Factory.sequence :repository_name do |n|
  "repo_#{n}"
end

Factory.define(:repository) do |r|
  r.name {Factory.next :repository_name}
  r.kind Repository::KIND_PROJECT_REPO
end

Factory.define(:merge_request_repository, :parent => :repository) do |r|
  r.kind Repository::KIND_TRACKING_REPO
end