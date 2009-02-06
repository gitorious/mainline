require "core_ext"
require "fileutils"
#require "ruby-git/lib/git"
require "grit/lib/grit"
require "diff-display/lib/diff-display"

gem "ruby-yadis", ">=0"
gem "rdiscount", ">=0"
require 'rdiscount'
silence_warnings do
  BlueCloth = RDiscount
end