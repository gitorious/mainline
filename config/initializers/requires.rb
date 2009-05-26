require "core_ext"
require "fileutils"
require "diff-display/lib/diff-display"
require 'oauth/oauth'
gem "ruby-yadis", ">=0"
gem "rdiscount", ">=0"
require 'rdiscount'
silence_warnings do
  BlueCloth = RDiscount
end