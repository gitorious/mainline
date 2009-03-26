# encoding: utf-8
#--
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

require File.dirname(__FILE__) + '/../test_helper'

class EndUserLicenseAgreementTest < ActiveSupport::TestCase
  context 'The end user license agreement' do
    setup do
#      File.open(EndUserLicenseAgreement.filename, "w"){|f| f.write("This is the license")}
    end
    
    teardown do
#      FileUtils.rm(EndUserLicenseAgreement.filename) if File.exist?(EndUserLicenseAgreement.filename)
      EndUserLicenseAgreement.reset
    end
    
    should 'calculate a checksum based on its contents' do
      license = EndUserLicenseAgreement.current_version
      assert_equal(Digest::SHA1.hexdigest(File.read(EndUserLicenseAgreement.filename)), license.checksum)
    end
    
  end
  
  context 'With an invalid filename' do
    setup do
      @filename = File.join("tmp", "gitorious.license")
      EndUserLicenseAgreement.stubs(:filename).returns(@filename)
    end
    
    should 'raise an error if the license file does not exist' do
      EndUserLicenseAgreement.stubs(:filename).returns(File.join("tmp", "gitorious.error"))
      assert_raises EndUserLicenseAgreementError do
        license = EndUserLicenseAgreement.current_version
      end
    end
  end
end