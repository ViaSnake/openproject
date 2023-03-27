#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

# Exporter for work package table.
#
# It can optionally export a work package details list with
# - title
# - attribute table
# - description with optional embedded images
#
# When exporting with embedded images then the memory consumption can quickly
# grow beyond limits. Therefore we create multiple smaller PDFs that we finally
# merge do one file.

require 'hexapdf'
require 'open3'

class WorkPackage::PDFExport::WorkPackageListToPdf < WorkPackage::Exports::QueryExporter
  include WorkPackage::PDFExport::Common
  include WorkPackage::PDFExport::Attachments
  include WorkPackage::PDFExport::OverviewTable
  include WorkPackage::PDFExport::WorkPackageDetail

  attr_accessor :pdf,
                :options

  def self.key
    :pdf
  end

  def initialize(object, options = {})
    super

    @page_count = 0
    @work_packages_per_batch = 100
    setup_page!
  end

  def export!
    file = render_work_packages query.results.work_packages
    success(file)
  rescue Prawn::Errors::CannotFit
    error(I18n.t(:error_pdf_export_too_many_columns))
  rescue StandardError => e
    Rails.logger.error { "Failed to generated PDF export: #{e} #{e.message}}." }
    error(I18n.t(:error_pdf_failed_to_export, error: e.message))
  end

  private

  def setup_page!
    self.pdf = get_pdf(current_language)

    configure_page_size!
  end

  def configure_page_size!
    pdf.options[:page_size] = 'EXECUTIVE' # TODO: 'A4'?
    pdf.options[:page_layout] = with_descriptions? ? :portrait : :landscape
    pdf.options[:top_margin] = page_top_margin
    pdf.options[:bottom_margin] = page_bottom_margin
  end

  def render_work_packages(work_packages, filename: "pdf_export")
    @id_wp_meta_map = build_meta_infos_map(work_packages)
    write_title!
    write_work_packages_overview! work_packages
    if should_be_batched?(work_packages)
      render_batched(work_packages, filename)
    else
      render_pdf(work_packages, filename)
    end
  end

  def render_batched(work_packages, filename)
    @batches_count = work_packages.length.fdiv(@work_packages_per_batch).ceil
    batch_files = []
    (1..@batches_count).each do |batch_index|
      batch_work_packages = work_packages.paginate(page: batch_index, per_page: @work_packages_per_batch)
      batch_files.push render_pdf(batch_work_packages, "pdf_batch_#{batch_index}.pdf")
      setup_page!
    end
    merge_batched_pdfs(batch_files, filename)
  end

  def merge_batched_pdfs(batch_files, filename)
    return batch_files[0] if batch_files.length == 1

    merged_pdf = Tempfile.new(filename)

    # TODO: Also possible, use the hexapdf cli that comes with the gem
    # Open3.capture2e("hexapdf", 'merge', '--force', *batch_files.map(&:path), merged_pdf.path)

    # TODO: All internal link annotions are not copied over on merging, is there a way to preserve them?
    target = HexaPDF::Document.new
    batch_files.each do |batch_file|
      pdf = HexaPDF::Document.open(batch_file.path)
      pdf.pages.each { |page| target.pages << target.import(page) }
    end
    target.write(merged_pdf.path, optimize: true)

    merged_pdf
  end

  def render_pdf(work_packages, filename)
    @resized_image_paths = []
    write_work_packages_details!(work_packages, @id_wp_meta_map) if with_descriptions?
    write_after_pages!
    file = Tempfile.new(filename)
    pdf.render_file(file.path)
    @page_count += pdf.page_count
    delete_all_resized_images
    file.close
    file
  end

  def write_after_pages!
    write_logo!
    write_headers!
    write_footers!
  end

  def build_meta_infos_map(work_packages)
    result = {}
    # TODO: Auto-numbering and hierarchy level informations
    work_packages.each_with_index do |work_package, index|
      result[work_package.id] = { level_path: [index + 1], level: 0 }
    end
    result
  end

  def should_be_batched?(work_packages)
    with_descriptions? && with_attachments? && (work_packages.length > @work_packages_per_batch)
  end

  def project
    query.project
  end

  def write_title!
    pdf.title = heading
    pdf.formatted_text([page_heading_style.merge({ text: heading })])
  end

  def title
    "#{heading}.pdf"
  end

  def heading
    title = query.new_record? ? I18n.t(:label_work_package_plural) : query.name

    if project
      "#{project} - #{title}"
    else
      title
    end
  end

  def write_logo!
    image_file = Rails.root.join("app/assets/images/logo_openproject.png")
    image_obj, image_info = pdf.build_image_object(image_file)
    scale = [logo_height / image_info.height.to_f, 1].min
    pdf.repeat :all do
      top = pdf.bounds.top + page_header_top + (logo_height / 2)
      pdf.embed_image image_obj, image_info, { at: [0, top], scale: }
    end
  end

  def write_headers!
    user = User.current
    return if user.nil?

    user_string = "#{user.firstname} #{user.lastname}"
    user_string_width = pdf.width_of(user_string, page_header_style)
    pdf.repeat :all do
      top = pdf.bounds.top + logo_height
      left = pdf.bounds.right - user_string_width
      opts = page_footer_style.merge({ at: [left, top] })
      pdf.draw_text user_string, opts
    end
  end

  def write_footers!
    date_string = format_date(Time.zone.today)
    title_string = heading
    title_string_width = pdf.width_of(title_string, page_footer_style)

    pdf.repeat :all, dynamic: true do
      page_string = (pdf.page_number + @page_count).to_s
      page_string_width = pdf.width_of(page_string, page_footer_style)

      pdf.draw_text date_string, page_footer_style.merge({ at: [pdf.bounds.left, -page_footer_top] })
      pdf.draw_text page_string, page_footer_style.merge({ at: [(pdf.bounds.width - page_string_width) / 2, -page_footer_top] })
      pdf.draw_text title_string, page_footer_style.merge({ at: [pdf.bounds.right - title_string_width, -page_footer_top] })
    end
  end

  def page_header_top
    20
  end

  def page_bottom_margin
    60
  end

  def page_footer_top
    30
  end

  def logo_height
    20
  end

  def page_top_margin
    60
  end

  def page_heading_style
    { size: 14, styles: [:bold] }
  end

  def page_header_style
    { size: 8, style: :normal }
  end

  def page_footer_style
    { size: 8, style: :normal }
  end
end
