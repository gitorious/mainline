#--
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
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

require File.dirname(__FILE__) + '/../spec_helper'
require 'geoip'

describe Cloner do
  before(:all) do
    @geoip = GeoIP.new(File.join(RAILS_ROOT, "data", "GeoIP.dat"))
  end
  
  before(:each) do
    @cloner = Cloner.new
  end

  it "should has a valid country" do
    localization = @geoip.country(cloners(:argentina).ip)
    localization[3].should == cloners(:argentina).country_code
    localization[5].should == cloners(:argentina).country
  end
end
