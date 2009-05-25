Factory.define(:group) do |g|
  g.name 'b-team'
  g.creator {|u| u.association(:user)}
end