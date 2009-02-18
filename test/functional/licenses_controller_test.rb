# encoding: utf-8
#--
#   Copyright (C) 2007-2009 Johan Sørensen <johan@johansorensen.com>
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

class LicensesControllerTest < ActionController::TestCase
  context 'Accepting (current) end user license agreement' do
    setup do
      license = stub("End user license agreement")
      license.stubs(:checksum).returns("ff0023902")
      license.stubs(:contents).returns("Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
      EndUserLicenseAgreement.stubs(:current_version).returns(license)          
      @user = users(:johan)
      login_as :johan
    end
    
    should 'render the current license version if this has been accepted' do
      @user.update_attributes(:accepted_license_agreement_version => EndUserLicenseAgreement.current_version.checksum)
      get :edit
      assert_redirected_to :action => :show
    end
    
    should 'ask the user to confirm a newer version if this has not been acccepted' do
      get :edit
      assert_response :success
    end
    
    should 'require the user to accept the terms' do
      put :update, :user => {}
      assert_redirected_to :action => :edit
    end
    
    should 'change the current version when selected' do
      put :update, :eula_version => EndUserLicenseAgreement.current_version.checksum
      assert_redirected_to :action => :show
      assert @user.reload.current_license_agreement_accepted?
    end
  end
end
