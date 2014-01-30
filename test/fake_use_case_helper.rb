# encoding: utf-8
#--
#   Copyright (C) 2014 Gitorious AS
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

module FakeUseCaseHelper
  class FakeUseCase < Struct.new(:result)
    def execute(*)
      self
    end

    def success
      if result[:success]
        yield(result[:success])
      end
    end

    def failure
      if result[:failure]
        yield(result[:failure])
      end
    end
  end

  def fake_use_case(opts)
    FakeUseCase.new(opts)
  end
end
