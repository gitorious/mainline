#--
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2009 Marius Mårnes Mathiesen <marius.mathiesen@gmail.com>
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
      EndUserLicenseAgreement.stubs(:filename).returns(File.join("tmp", "gitorious.license"))
      @license_agreement = EndUserLicenseAgreement.current_version
      assert_not_nil(@license_agreement.checksum)
    end
    
    teardown do
      FileUtils.rm(EndUserLicenseAgreement.filename) if File.exist?(EndUserLicenseAgreement.filename)
      @license_agreement.contents = ""
    end
    
    should 'calculate a checksum based on its contents' do
      @license_agreement.expects(:recalculate_checksum).once
      @license_agreement.contents = "We have some changes here"
      @license_agreement.save
    end
    
    should 'persist its contents' do
      assert_equal('', @license_agreement.contents)
      contents = "This is a foo"
      @license_agreement.contents = contents
      @license_agreement.save
      assert_equal(contents, EndUserLicenseAgreement.current_version.contents)
    end
    
    should 'not change the SHA unless the contents have actually changed' do
      boilerplate = "This is legal stuff"
      @license_agreement.contents = boilerplate
      @license_agreement.save
      checksum_before = @license_agreement.checksum
      @license_agreement.contents = boilerplate
      @license_agreement.save
      assert_equal(checksum_before, @license_agreement.checksum)
    end
  end
end