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
require "use_case"

ProjectValidator = UseCase::Validator.define do
  NAME_FORMAT = /[a-z0-9_\-]+/.freeze
  URL_FORMAT  = %r{\Ahttps?:\/\/([^\s:@]+:[^\s:@]*@)?[A-Za-z\d\-]+(\.[A-Za-z\d\-]+)+\.?(:\d{1,5})?([\/?]\S*)?\Z}i

  validates_presence_of(:title, :user_id, :slug, :owner_id)
  validates_format_of(:slug, :with => /^#{NAME_FORMAT}$/i,
    :message => I18n.t( "project.format_slug_validation"))
  validates_exclusion_of(:slug, :in => lambda { |p| Project.reserved_slugs })

  validates_format_of(:home_url, :with => URL_FORMAT, :allow_nil => true, :message => I18n.t("project.ssl_required"))
  validates_format_of(:mailinglist_url, :with => URL_FORMAT, :allow_nil => true, :message => I18n.t("project.ssl_required"))
  validates_format_of(:bugtracker_url, :with => URL_FORMAT, :allow_nil => true, :message => I18n.t("project.ssl_required"))

  validate :unique_slug

  def self.model_name
    Project.model_name
  end

  def to_param
    @target.slug
  end

  private

  def unique_slug
    unless uniq?
      errors.add(:slug, I18n.t("project.unique_slug_validation_message"))
    end
  end
end
