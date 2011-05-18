# encoding: utf-8
#--
#   Copyright (C) 2009 Johan Sørensen <johan@johansorensen.com>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

require File.dirname(__FILE__) + '/../../test_helper'
require "fileutils"

class RepositoryArchivingProcessorTest < ActiveSupport::TestCase
  def setup
    @processor = RepositoryArchivingProcessor.new
    repo = repositories(:johans)
    @msg = {
      :full_repository_path => repo.full_repository_path,
      :output_path => "/tmp/output/foo.tar.gz",
      :work_path => "/tmp/work/foo.tar.gz",
      :commit_sha => "abc123",
      :name => "ze_project-reponame",
      :format => "tar.gz",
    }

    File.stubs(:exist?).with(@msg[:output_path]).returns(false)
  end

  should "aborts early if the cached file already exists" do
    File.stubs(:exist?).with(@msg[:output_path]).returns(true)
    Dir.expects(:chdir).never
    @processor.consume(@msg.to_json)
  end

  should "generates an archived tarball in the work dir and moves it to the cache path" do
    Dir.expects(:chdir).yields(Dir.new("/tmp"))
    @processor.expects(:run).with("git archive --format=tar " +
      "--prefix=ze_project-reponame/ abc123 | gzip > #{@msg[:work_path]}").returns(nil)

    @processor.expects(:run_successful?).returns(true)
    FileUtils.expects(:mv).with(@msg[:work_path], @msg[:output_path])

    @processor.consume(@msg.to_json)
  end
end
