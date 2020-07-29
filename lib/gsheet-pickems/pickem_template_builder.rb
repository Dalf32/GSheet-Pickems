# PickemTemplateBuilder
#
# AUTHOR::  Kyle Mullins

require 'google/apis/sheets_v4'
require 'gsheet-pickems/spreadsheet_helper'

include Google::Apis::SheetsV4

module GSheetPickems
  class PickemTemplateBuilder
    include SpreadsheetHelper

    def initialize(spreadsheet_id, week_name, metadata)
      @spreadsheet_id = spreadsheet_id
      @week_name = week_name
      @metadata = metadata
    end

    def build(sheets_service)
      new_sheet_id = add_sheet(sheets_service, build_add_sheet_request)
      update_headers(sheets_service, build_update_cells_request(new_sheet_id),
                     build_merge_cells_requests(new_sheet_id),
                     build_update_borders_request(new_sheet_id))
      create_dev_metadata(sheets_service, build_metadata_request(new_sheet_id))
      new_sheet_id
    end

    private

    def add_sheet(sheets_service, add_sheet_request)
      batch_response = batch_update(sheets_service,
                                    Request.new(add_sheet: add_sheet_request))
      batch_response.replies.first.add_sheet.properties.sheet_id
    end

    def update_headers(sheets_service, update_cells_request, merge_cells_requests,
                       update_borders_request)
      batch_update(sheets_service, Request.new(update_cells: update_cells_request),
                   *merge_cells_requests.map { |m| Request.new(merge_cells: m) },
                   Request.new(update_borders: update_borders_request))
    end

    def create_dev_metadata(sheets_service, dev_metadata)
      batch_update(sheets_service,
                   Request.new(create_developer_metadata: dev_metadata))
    end

    def build_add_sheet_request
      AddSheetRequest.new(properties: SheetProperties.new(
          title: @week_name, index: 1,
          grid_properties: GridProperties.new(frozen_column_count: 1))
      )
    end

    def build_update_cells_request(sheet_id)
      UpdateCellsRequest.new(
          start: GridCoordinate.new(sheet_id: sheet_id, row_index: 0, column_index: 0),
          rows: [
              RowData.new(values: [CellData.new,
                                   cell_data(@week_name, h_align: 'CENTER')]),
              RowData.new(values: [CellData.new] + match_day_cells),
              RowData.new(values: [CellData.new] + match_num_cells + score_header_cells),
              RowData.new(values: [cell_data('Actual', bg_color: light_gray)] +
                  actual_match_cells + actual_score_cells)
          ],
          fields: '*'
      )
    end

    def build_merge_cells_requests(sheet_id)
      merge_requests = [merge_cells(sheet_id, 0..1, 1..(@metadata.match_count + 1))]
      last_cell = 1
      merge_requests + @metadata.match_days.map do |day|
        col_range = last_cell..(last_cell + day.match_count)
        last_cell += day.match_count
        merge_cells(sheet_id, 1..2, col_range)
      end
    end

    def build_update_borders_request(sheet_id)
      UpdateBordersRequest.new(
          range: grid_range(sheet_id, 0..3, 0..(@metadata.match_count + 1)),
          left: standard_border, right: standard_border,
          top: standard_border, bottom: standard_border,
          inner_horizontal: standard_border,
          inner_vertical: standard_border
      )
    end

    def build_metadata_request(sheet_id)
      CreateDeveloperMetadataRequest.new(developer_metadata: dev_metadata(
          sheet_id, PickemMetadata::METADATA_KEY, @metadata.to_json)
      )
    end

    def match_day_cells
      @metadata.match_days.map do |day|
        [cell_data(day.name, h_align: 'CENTER')] +
            ([CellData.new] * (day.match_count - 1))
      end.collect.to_a.flatten
    end

    def match_num_cells
      @metadata.match_days.map do |day|
        day.match_count.times.map { |match_num| cell_data("Match #{match_num + 1}") }.tap do |cells|
          cells.last.user_entered_format.borders = right_border
        end
      end.collect.to_a.flatten
    end

    def score_header_cells
      [cell_data('Score', borders: full_borders),
       cell_data('Total Possible', bg_color: light_gray, borders: full_borders),
       cell_data('Prediction %', borders: full_borders)]
    end

    def actual_match_cells
      @metadata.match_days.flat_map do |day|
        ([cell_data('-', bg_color: light_gray)] * (day.match_count - 1)) +
            [cell_data('-', bg_color: light_gray, borders: right_border)]
      end
    end

    def actual_score_cells
      end_col = ('A'..'Z').to_a[@metadata.match_count]
      [cell_data('-', bg_color: light_gray),
       cell_data("=COUNTIF(B4:#{end_col}4, \"<>-\")", bg_color: light_gray, h_align: 'RIGHT'),
       cell_data('-', bg_color: light_gray)]
    end
  end
end
