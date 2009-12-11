require File.dirname(__FILE__) + '/../test_helper'
require "fileutils"

class LogReaderTest < ActiveSupport::TestCase
  context "reading files inside log dir" do
    setup do
      silence_warnings do
        Object.const_set("RAILS_ENV", "dummy")
      end
      @reader = LogReader.new
    end

    should " use log file from current RAILS_ENV" do
      File.open("#{RAILS_ROOT}/log/dummy.log", "w") do |log|
        log.puts "First line"
        log.puts "Second line"
      end

      assert_equal "First line\nSecond line\n", @reader.read
      FileUtils.rm("#{RAILS_ROOT}/log/dummy.log")
    end

    should " only read the last 100 lines" do
      big_log_file = "#{RAILS_ROOT}/test/fixtures/big.log"
      FileUtils.cp(big_log_file, "#{RAILS_ROOT}/log/dummy.log")
      expected = File.read("#{RAILS_ROOT}/test/fixtures/expected.log")
      assert_equal expected, @reader.read
    end
  end
end
