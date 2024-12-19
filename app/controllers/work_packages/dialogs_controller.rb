# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
# ++

class WorkPackages::DialogsController < ApplicationController
  include OpTurbo::ComponentStream
  include OpTurbo::DialogStreamHelper
  layout false

  before_action :find_project_by_project_id
  before_action :build_work_package, only: %i[new]
  before_action do
    do_authorize :add_work_packages
  end
  authorization_checked! :new

  def new
    respond_with_dialog WorkPackages::Dialogs::CreateDialogComponent.new(work_package: @work_package)
  end

  private

  def build_work_package
    initial = WorkPackage.new(project: @project)

    call = WorkPackages::SetAttributesService
      .new(model: initial, user: current_user, contract_class: WorkPackages::CreateContract)
      .call(create_params)

    # Ignore call errors here, as we only want to build the work package
    @work_package = call.result
  end

  def create_params
    params.permit(*PermittedParams.permitted_attributes[:new_work_package])
  end
end
