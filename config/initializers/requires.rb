require "core_ext"
require "fileutils"
require "diff-display/lib/diff-display"
require 'oauth/oauth'
require 'factory_girl/lib/factory_girl'
gem "ruby-yadis", ">=0"
gem "rdiscount", ">=0"
require 'rdiscount'
silence_warnings do
  BlueCloth = RDiscount
end