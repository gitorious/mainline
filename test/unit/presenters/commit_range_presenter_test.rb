# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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

require "test_helper"
require 'minitest/spec'

describe CommitRangePresenter do
  include SampleRepoHelpers

  describe '.build' do
    let(:object) { CommitRangePresenter.build(left.id, right.id, repository) }

    let(:repository) { repository_with_working_git('test_repo') }
    let(:commits)    { repository.git.commits.reverse }
    let(:left)       { commits.first }
    let(:right)      { commits.last }

    it 'fetches commits within the range' do
      assert_equal object.map(&:message), [commits[1].message, commits[2].message]
    end

    it 'sets correct left-side commit sha' do
      assert_equal object.left.id, left.id
    end

    it 'sets correct right-side commit sha' do
      assert_equal object.right.id, right.id
    end
  end
end
