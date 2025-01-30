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

require_relative "../meetings/base"

module Pages::RecurringMeeting
  class Show < ::Pages::Meetings::Base
    attr_accessor :meeting

    def initialize(meeting, project: nil)
      super(project)

      self.meeting = meeting
    end

    def path
      if project
        project_recurring_meeting_path(project, meeting)
      else
        recurring_meeting_path(meeting)
      end
    end

    def expect_scheduled_meeting(date:)
      within("li", text: date) do
        expect(page).to have_css(".status", text: "Scheduled")
      end
    end

    def expect_no_scheduled_meeting(date:)
      within("li", text: date) do
        expect(page).to have_no_css(".status", text: "Scheduled")
      end
    end

    def expect_open_meeting(date:)
      within("li", text: date) do
        expect(page).to have_css(".status", text: "Open")
      end
    end

    def expect_no_open_meeting(date:)
      within("li", text: date) do
        expect(page).to have_no_css(".status", text: "Open")
      end
    end

    def expect_cancelled_meeting(date:)
      within("li", text: date) do
        expect(page).to have_css(".status", text: "Cancelled")
      end
    end

    def expect_no_cancelled_meeting(date:)
      within("li", text: date) do
        expect(page).to have_no_css(".status", text: "Cancelled")
      end
    end

    def expect_rescheduled_meeting(old_date:, new_date:)
      within("li", text: old_date) do
        expect(page).to have_css("s", text: old_date)
        expect(page).to have_text("#{old_date}\n#{new_date}")
      end
    end

    def create_from_template(date:)
      within("li", text: date) do
        click_on "Create from template"
      end
    end

    def cancel_occurrence(date:)
      within("li", text: date) do
        click_on "more-button"
        click_on "Cancel this occurrence"
      end
    end

    def expect_subtitle(text:)
      expect(page).to have_css(".PageHeader-description", text: text)
    end

    def edit_meeting_series
      page.find_test_selector("recurring-meeting-action-menu").click
      click_on "Edit meeting series"

      expect(page).to have_css("#new-meeting-dialog")
    end

    def delete_meeting_series
      page.find_test_selector("recurring-meeting-action-menu").click
      click_on "Delete meeting series"

      expect(page).to have_css("#delete-recurring-meeting-dialog")
    end

    def in_edit_dialog(&)
      page.within("#new-meeting-dialog", &)
    end

    def in_delete_dialog(&)
      page.within("#delete-meeting-dialog", &)
    end

    def in_delete_recurring_dialog(&)
      page.within("#delete-recurring-meeting-dialog", &)
    end

    def in_delete_scheduled_dialog(&)
      page.within("#delete-scheduled-recurring-meeting-dialog", &)
    end

    def expect_no_meeting(date:)
      expect(page).to have_no_css("li", text: date)
    end

    def expect_no_actions(date:)
      within("li", text: date) do
        expect(page).not_to have_test_selector("more-button")
      end
    end

    def expect_open_actions(date:)
      within("li", text: date) do
        click_on "more-button"

        expect(page).to have_css(".ActionListItem-label", count: 2)
        expect(page).to have_css(".ActionListItem-label", text: "Download iCalendar event")
        expect(page).to have_css(".ActionListItem-label", text: "Cancel this occurrence")

        # Close it again
        click_on "more-button"
      end
    end

    def expect_scheduled_actions(date:)
      within("li", text: date) do
        click_on "more-button"

        expect(page).to have_css(".ActionListItem-label", count: 1)
        expect(page).to have_css(".ActionListItem-label", text: "Cancel this occurrence")

        # Close it again
        click_on "more-button"
      end
    end

    def expect_cancelled_actions(date:)
      within("li", text: date) do
        click_on "more-button"

        expect(page).to have_css(".ActionListItem-label", count: 1)
        expect(page).to have_css(".ActionListItem-label", text: "Restore this occurrence")

        # Close it again
        click_on "more-button"
      end
    end

    # def for_meeting(date:, &)
    #   within("li", text: date, &)
    # end
  end
end
