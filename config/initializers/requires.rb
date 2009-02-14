require "core_ext"
require "fileutils"
require "ruby-git/lib/git"
require "grit/lib/grit"
require "diff-display/lib/diff-display"

require 'rdiscount'
silence_warnings do
  BlueCloth = RDiscount
end