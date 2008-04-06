require File.dirname(__FILE__) + '/helper'

class TestGit < Test::Unit::TestCase
  def setup
    base = File.join(File.dirname(__FILE__), "..")
    @git = Git.new(base)
    @git_bin_base = "#{Git.git_binary} --git-dir='#{base}'"
  end
  
  def test_method_missing_calls_execute
    @git.expects(:execute).with("#{@git_bin_base} version ").returns("")
    @git.version
  end
  
  def test_execute
    assert_match(/^git version [\d\.]*$/, @git.execute("#{Git.git_binary} version"))
  end
  
  def test_it_escapes_single_quotes_with_shell_escape
    assert_equal "\\'foo", @git.shell_escape("'foo")
    assert_equal "\\'foo\\'", @git.e("'foo'")
  end
  
  def test_method_missing
    assert_match(/^git version [\w\.]*$/, @git.version)
  end
  
  def test_transform_options
    assert_equal ["-s"], @git.transform_options({:s => true})
    assert_equal ["-s '5'"], @git.transform_options({:s => 5})
    
    assert_equal ["--max-count"], @git.transform_options({:max_count => true})
    assert_equal ["--max-count='5'"], @git.transform_options({:max_count => 5})
    
    assert_equal ["-s", "-t"], @git.transform_options({:s => true, :t => true}).sort
  end
  
  def test_transform_options_shell_escapes_arguments
    assert_equal ["--foo='bazz\\'er'"], @git.transform_options({:foo => "bazz'er"})
    assert_equal ["-x 'bazz\\'er'"], @git.transform_options({:x => "bazz'er"})
  end
  
  def test_it_really_shell_escapes_arguments_to_the_git_shell
    @git.expects(:execute).with("#{@git_bin_base} foo --bar='bazz\\'er'")
    @git.foo(:bar => "bazz'er")
    @git.expects(:execute).with("#{@git_bin_base} bar -x 'quu\\'x'")
    @git.bar(:x => "quu'x")
  end
  
  def test_it_shell_escapes_the_standalone_argument
    @git.expects(:execute).with("#{@git_bin_base} foo 'bar\\'s'")
    @git.foo({}, "bar's")
  end
end

