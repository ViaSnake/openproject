#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module Storages
  module Admin
    module ProjectStorages
      class ProjectFolderModeForm < ApplicationForm
        form do |radio_form|
          radio_form.radio_button_group(
            name: :project_folder_mode,
            label: I18n.t(:"storages.label_project_folder"),
            caption: I18n.t(:"storages.help_texts.project_folder")
          ) do |radio_group|
            radio_group.radio_button(value: "inactive", label: I18n.t(:"storages.label_no_specific_folder"),
                                     caption: I18n.t(:"storages.instructions.no_specific_folder"))

            if @project_storage.automatic_management_possible?
              radio_group.radio_button(value: "automatic", label: I18n.t(:"storages.label_automatic_folder"),
                                       caption: I18n.t(:"storages.instructions.automatic_folder"))
            end

            radio_group.radio_button(value: "manual", label: I18n.t(:"storages.label_existing_manual_folder"),
                                     caption: I18n.t(:"storages.instructions.existing_manual_folder"))
          end
        end

        def initialize(project_storage:)
          super()
          @project_storage = project_storage
        end
      end
    end
  end
end
