#--
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David Chelimsky <dchelimsky@gmail.com>
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

describe UsersHelper do
  it "should encode email" do
    message = %{
      mail_to_encoded passes :replace_at and :replace_dot
      values to mail_to (a rails helper), which should
      obfuscate the email address, but it apparently does
      NOT do that if :encode => 'javascript'
      
      Need to investigate if this is a Rails bug and
      either fix it there or let go of obfuscation.
    }
    #pending(message) do
      email = "aAT@NOSPAM@bDOTcom"
      encoded = (0...email.length).inject("") do |result, index|
        result << sprintf("%%%x",email[index])
      end
      helper.encoded_mail_to("a@b.com").should match(/#{encoded}/)
    #end
  end
end
