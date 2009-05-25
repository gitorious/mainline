Factory.sequence :email do |n|
  "john#{n}@example.com"
end

Factory.sequence :login do |n|
  "user#{n}"
end

Factory.define(:user) do |u|
  u.login {Factory.next :login}
  u.email {Factory.next :email}
  u.terms_of_use '1'
  u.salt '7e3041ebc2fc05a40c60028e2c4901a81035d3cd'
  u.crypted_password '00742970dc9e6319f8019fd54864d3ea740f04b1'  # test
  u.created_at Time.now.to_s(:db)
  u.aasm_state 'terms_accepted'
  u.is_admin false
  u.activated_at Time.now.to_s(:db)
end

