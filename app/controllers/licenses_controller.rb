# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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

class LicensesController < ApplicationController
  before_filter :login_required
  skip_before_filter :require_current_eula

  def show
    if !current_user.terms_accepted?
      flash[:notice] = t("views.license.terms_not_accepted")
      redirect_to(:action => "edit") and return
    end
  end

  def edit
    if current_user.terms_accepted?
      flash[:notice] = t("views.license.terms_already_accepted")
      redirect_to(:action => :show) and return
    end

    respond_to do |format|
      format.html do
        render 'edit', :locals => { :user => current_user }
      end
    end
  end

  def update
    current_user.terms_of_use = params[:user][:terms_of_use]
    if !current_user.terms_of_use.blank?
      current_user.save!
      flash[:success] = t("views.license.terms_accepted")
      if !current_user.terms_of_use.blank?
        current_user.accept_terms
      end
      redirect_back_or_default :action => :show
    else
      flash[:error] = t("views.license.terms_not_accepted")
      redirect_to :action => :edit
    end
  end
end
