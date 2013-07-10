# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious AS
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
require "fast_test_helper"
require "validators/open_id_user_validator"

class OpenIdUserValidatorTest < MiniTest::Spec
  it "accepts new open id user" do
    result = OpenIdUserValidator.call(User.new({
          :login => "schmoe",
          :email => "moe@schmoe.example",
          :fullname => "Moe Schmoe",
          :identity_url => "http://moe.example/",
          :terms_of_use => true
        }))

    assert result.valid?
  end
end
