Factory.define(:message) do |m|
  m.sender {|u| u.association(:user)}
  m.recipient {|u| u.association(:user)}
  m.subject 'Hello'
  m.body 'Just called to say hi'
end