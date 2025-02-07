#-- copyright
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
#++

require "spec_helper"
require File.expand_path("../support/permission_specs", __dir__)

RSpec.describe Overviews::OverviewsController, "edit_project_life_cycles permission", # rubocop:disable RSpec/EmptyExampleGroup,RSpec/SpecFilePathFormat
               type: :controller do
  include PermissionSpecs

  # render dialog with inputs for editing project attributes with edit_project permission
  check_permission_required_for("overviews/overviews#project_life_cycles_dialog", :edit_project_stages_and_gates)

  # render form with inputs for editing project attributes with edit_project permission
  check_permission_required_for("overviews/overviews#project_life_cycles_form", :edit_project_stages_and_gates)

  # update project attributes with edit_project permission, deeper permission check via contract in place
  check_permission_required_for("overviews/overviews#update_project_life_cycles", :edit_project_stages_and_gates)
end
