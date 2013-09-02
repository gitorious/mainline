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

class AvatarsController < ApplicationController
  renders_in_global_context
  before_filter :login_required

  def destroy
    user = User.find_by_login!(params[:id])
    return current_user_only_redirect if user != current_user
    # Use Case waiting to happen
    user.avatar.destroy
    user.save
    user.expire_avatar_email_caches
    flash[:success] = "You avatar was deleted"
    redirect_to(edit_user_path(user))
  end
end
