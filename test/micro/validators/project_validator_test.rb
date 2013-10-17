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
require "validators/project_validator"

class ProjectValidatorTest < MiniTest::Spec
  it "requires a title to be valid" do
    project = create_project(:title => nil)
    refute ProjectValidator.call(project).valid?

    project.title = "foo"
    assert ProjectValidator.call(project).valid?
  end

  it "requires a slug to be valid" do
    project = create_project(:slug => nil)
    refute ProjectValidator.call(project).valid?
  end

  it "has a unique slug to be valid" do
    project = create_project
    def project.uniq?; false; end

    refute ProjectValidator.call(project).valid?
    refute_nil ProjectValidator.call(project).errors[:slug]
  end

  it "requires an alphanumeric slug" do
    project = create_project(:slug => "asd asd")
    refute ProjectValidator.call(project).valid?
  end

  it "does not allow a reserved name as slug" do
    Project.stubs(:reserved_slugs).returns(["batman", "robin"])
    project = create_project(:slug => "Batman")
    result = ProjectValidator.call(project)

    refute result.valid?
    refute_nil result.errors[:slug]
  end

  it "requires valid home url" do
    project = create_project
    validator = ProjectValidator.new(project)

    [:home_url, :mailinglist_url, :bugtracker_url].each do |attr|
      project.send("#{attr}=", "ftp://blah.com")
      refute validator.valid?

      project.send("#{attr}=", "something@wrong.com")
      refute validator.valid?

      project.send("#{attr}=", "http://blah.com")
      assert validator.valid?

      project.send("#{attr}=", nil)
      assert validator.valid?
    end
  end

  def create_project(options={})
    Project.new({
        :title => "foo project",
        :slug => "foo",
        :user_id => 1,
        :owner_id => 1
      }.merge(options))
  end
end
