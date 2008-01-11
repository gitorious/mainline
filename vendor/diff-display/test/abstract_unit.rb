$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'diff/display/unified'

module Kernel
  def load_diffs(*diffs)
    loaded_diffs = Hash.new({})
    diff_path    = 'diffs/'
    diffs.each do |diff_name|
      diff = IO.readlines(diff_path + diff_name.id2name + '.diff')
      data = Diff::Display::Unified::Generator.run(diff)
      loaded_diffs[diff_name] = {:diff => diff, :data => data}
    end
    loaded_diffs
  end
  alias_method :load_diff, :load_diffs

  def load_all_diffs(path = 'diffs')
    load_diffs *Dir.glob(path + '/*.diff').map {|d| File.basename(d, '.*').intern}
  end

end

class Array
  def normalize_diff
    diff = delete_if {|elem| %w{++ -- @@}.include?(elem[0,2])}
    diff.map {|elem| elem.gsub(/^./, '').chomp}
  end

  def normalize_diff_object
    delete_if {|elem| elem.is_a? Diff::Display::Unified::SepBlock}.flatten
  end

  def diff_inline_line_numbers
    numbers = []
    diff = delete_if {|elem| %w{++ -- @@}.include?(elem[0,2])}
    diff.each_with_index do |elem, idx| 
      numbers.concat([idx - 1, idx]) if self[idx][0,1].eql?('+') and self[idx - 1][0,1].eql?('-')
    end
    numbers
  end

  def data_inline_line_numbers
    numbers = []
    normalize_diff_object.each_with_index do |elem, idx|
      numbers.push idx if elem.contains_inline_change?
    end
    numbers
  end
end
