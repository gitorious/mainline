require "core_ext"
require "fileutils"
require "ruby-git/lib/git"
require "grit/lib/grit"
require "diff-display/lib/diff-display"
$: << File.join(RAILS_ROOT, "vendor/ultraviolet/lib/")
require "uv"
