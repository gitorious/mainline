# encoding: utf-8
#--
#   Copyright (C) 2010 Marius Mårnes Mathiesen <marius@shortcut.no>
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


require File.dirname(__FILE__) + '/../../test_helper'

class SubdomainValidationTest < ActiveSupport::TestCase
  context "Validate configuration" do
    setup do
      @config = {}
      @config.extend(SubdomainValidation)
    end

    should "Gitorious.org should work with subdomains" do
      @config["gitorious_host"] = "gitorious.org"
      assert @config.valid_subdomain?
    end
  
    should "Host names without dots are not considered valid" do
      @config["gitorious_host"] = "gitorious"
      assert !@config.valid_subdomain?
    end

    should "Localhost is not an acceptable host name" do
      @config["gitorious_host"] = "localhost"
      assert !@config.valid_subdomain?
    end
  end

  context "Request validation" do
    setup do
      @config = {"gitorious_host" => "gitorious.org"}
      @config.extend(SubdomainValidation)
    end

    should "consider direct matches successful" do
      assert @config.valid_request_host?("gitorious.org")
    end

    should "consider subdomain matches successful" do
      assert @config.valid_request_host?("qt.gitorious.org")
    end

    should "consider unknown domain requests unsuccessful" do
      assert !@config.valid_request_host?("gitorious.com")
    end

    should "not consider invalid domain names successful" do
      @config["gitorious_host"] = "gitorious"
      assert !@config.valid_request_host?("gitorious")
    end

    should "consider sub domain hosts valid" do
      @config = {"gitorious_host" => "git.gitorious.org"}
      @config.extend(SubdomainValidation)

      assert @config.valid_request_host?("git.gitorious.org")
    end
  end

  context "Reserved host names" do
    setup do
      @config = {}
      @config.extend(SubdomainValidation)
    end

    should "not consider the HTTP_CLONING_SUBDOMAIN a valid host name" do
      @config["gitorious_host"] = "#{Site::HTTP_CLONING_SUBDOMAIN}"
      assert @config.using_reserved_hostname?
    end

    should "not consider a subdomain starting with HTTP_CLONING_SUBDOMAIN a valid host name" do
      @config["gitorious_host"] = "#{Site::HTTP_CLONING_SUBDOMAIN}.example"
      assert @config.using_reserved_hostname?
    end

    should "allow HTTP_CLONING_SUBDOMAIN as part of name" do
      @config["gitorious_host"] = "#{Site::HTTP_CLONING_SUBDOMAIN}orious"
      assert !@config.using_reserved_hostname?
    end

    should "consider other domains valid" do
      @config["gitorious_host"] = "gitorious.org"
      assert !@config.using_reserved_hostname?
    end
  end
end
