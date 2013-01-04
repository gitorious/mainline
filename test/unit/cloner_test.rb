# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

require "test_helper"

class ClonerTest < ActiveSupport::TestCase

  def setup
    @geoip = GeoIP.new(Rails.root + "data/GeoIP.dat")
    @cloner = Cloner.new
  end

  should "has a valid country" do
    localization = @geoip.country(cloners(:argentina).ip)
    assert_equal cloners(:argentina).country_code, localization[3]
    assert_equal cloners(:argentina).country, localization[5]
  end
end
