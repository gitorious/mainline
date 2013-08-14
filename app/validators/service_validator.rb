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

ServiceValidator = UseCase::Validator.define do
  validates_presence_of :user
  validates_presence_of :repository, :unless => Proc.new { |hook| hook.user && Gitorious::App.site_admin?(hook.user) }, :message => "is required for non admins"
  validate :adapter_valid

  def adapter_valid
    errors.add(:adapter, "must be valid") unless adapter.valid?
  end
end
