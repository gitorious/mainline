require File.dirname(__FILE__) + '/abstract_unit'

class DisplayUnifiedTest < Test::Unit::TestCase

  def setup
    @diffs = load_all_diffs
    @diffs_with_inline_changes = load_diffs :inline_changes
  end

  def test_parity_of_diffs_and_data_objects
    @diffs.keys.each do |d|
      assert_equal(@diffs[d][:data].normalize_diff_object, 
                   @diffs[d][:diff].normalize_diff, 
                   "Data object and diff file for #{d} don't match")
   end
  end

  def test_parity_of_inline_changes
    @diffs_with_inline_changes.keys.each do |d|
      assert_equal(@diffs[d][:data].data_inline_line_numbers,
                   @diffs[d][:diff].diff_inline_line_numbers,
                   "Inline change line numbers don't match up for #{d}")
    end
  end
  
  # def test_edgecase
  #   diff = load_diff(:edgecase1_diff)[:edgecase1_diff]
  #   assert_equal(diff[:data].normalize_diff_object, 
  #                diff[:diff].normalize_diff, 
  #                "Data object and diff file for #{diff} don't match")
  # end

end
