Factory.sequence :key do |n|
  "ssh-rsa #{["asdsad#{n}"].pack("m")} foo#{n}@bar"
end

Factory.define(:ssh_key) do |k|
  k.user {|u| u.association(:user) }
  k.key { Factory.next :key }
  k.ready true
end