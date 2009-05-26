Factory.define(:project) do |p|
  p.slug 'project'
  p.title 'Test project'
  p.description 'Random project'
end

Factory.define(:user_project, :parent => :project) do |p|
  p.association :user, :factory => :user
  p.owner {|_p| _p.user}
end