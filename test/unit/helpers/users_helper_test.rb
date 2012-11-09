# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
#   Copyright (C) 2010 Peter Kjellerstedt <pkj@axis.com>
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
#   Copyright (C) 2008-2009 Johan Sørensen <johan@johansorensen.com>
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

class UsersHelperTest < ActionView::TestCase
  include ERB::Util

  should "encode email" do
    email = "aAT@NOSPAM@bDOTcom"
    encoded = (0...email.length).inject("") do |result, index|
      i = RUBY_VERSION > '1.9' ? email[index].ord : email[index]
      result << sprintf("%%%x", i)
    end
    assert_match(/#{encoded}/, encoded_mail_to("a@b.com"))
  end

  should "mangle email" do
    assert mangled_mail("johan@example.com").include?("&hellip;")
  end

  should "not mangle emails that do not look like emails" do
    assert_equal "johan", mangled_mail("johan")
    assert_equal "johan", mangled_mail("johan@")
  end
end
