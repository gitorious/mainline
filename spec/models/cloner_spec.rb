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
