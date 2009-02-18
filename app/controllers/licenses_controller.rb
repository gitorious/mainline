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

class LicensesController < ApplicationController
  before_filter :login_required
  def show
    if !current_user.current_license_agreement_accepted?
      flash[:errors] = t("views.license.terms_not_accepted")
      redirect_to :action => 'edit' and return
    end
  end
  
  def edit
    if current_user.current_license_agreement_accepted?
      flash[:errors] = t("views.license.terms_already_accepted")
      redirect_to :action => :show and return
    end
  end
  
  def update
    current_user.eula_version = params[:eula_version]
    if current_user.current_license_agreement_accepted?
      flash[:notice] = t("views.license.terms_accepted")
      current_user.save!
      redirect_to :action => :show
    else
      flash[:errors] = "You need to accept the latest agreement"
      redirect_to :action => :edit
    end
  end
  
end
