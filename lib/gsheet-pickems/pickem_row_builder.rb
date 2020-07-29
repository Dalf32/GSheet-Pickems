# PickemRowBuilder
#
# AUTHOR::  Kyle Mullins

require 'google/apis/sheets_v4'
require 'gsheet-pickems/spreadsheet_helper'

include Google::Apis::SheetsV4

module GSheetPickems
  class PickemRowBuilder
    include SpreadsheetHelper

    def initialize(spreadsheet_id, sheet_id, player_name, picks, metadata)
      @spreadsheet_id = spreadsheet_id
      @sheet_id = sheet_id
      @player_name = player_name
      @picks = picks
      @metadata = metadata
    end

    def build(sheets_service)
      update_row(sheets_service, build_cond_format_request,
                 build_update_cells_request)
      update_score_formatting(sheets_service, *build_score_cond_format_requests)
      @metadata.next_blank_row += 1
      update_dev_metadata(sheets_service, build_metadata_request)
    end

    private

    def update_row(sheets_service, update_format_request, update_cells_request)
      batch_update(sheets_service,
                   Request.new(add_conditional_format_rule: update_format_request),
                   Request.new(update_cells: update_cells_request))
    end

    def update_dev_metadata(sheets_service, dev_metadata)
      batch_update(sheets_service,
                   Request.new(update_developer_metadata: dev_metadata))
    end

    def update_score_formatting(sheets_service, *format_requests)
      batch_update(sheets_service, *format_requests.map do |request|
        Request.new(add_conditional_format_rule: request)
      end
      )
    end

    def build_cond_format_request
      cur_row = @metadata.next_blank_row

      AddConditionalFormatRuleRequest.new(
          index: 0, rule: ConditionalFormatRule.new(
          boolean_rule: BooleanRule.new(
              condition: bool_condition('CUSTOM_FORMULA', "=MATCH(B#{cur_row},B$4,0)"),
              format: CellFormat.new(background_color: light_green)
          ),
          ranges: [grid_range(@sheet_id, (cur_row - 1)..cur_row,
                              1..(@metadata.match_count + 1))]
      ))
    end

    def build_update_cells_request
      UpdateCellsRequest.new(
          start: GridCoordinate.new(sheet_id: @sheet_id,
                                    row_index: @metadata.next_blank_row - 1,
                                    column_index: 0),
          rows: [RowData.new(values: [cell_data(@player_name)] +
              picks_cells + score_cells)],
          fields: '*'
      )
    end

    def build_metadata_request
      UpdateDeveloperMetadataRequest.new(
          data_filters: [DataFilter.new(
              developer_metadata_lookup: DeveloperMetadataLookup.new(
                  location_type: 'SHEET',
                  metadata_location: DeveloperMetadataLocation.new(sheet_id: @sheet_id),
                  metadata_key: PickemMetadata::METADATA_KEY
              )
          )],
          developer_metadata: dev_metadata(@sheet_id, PickemMetadata::METADATA_KEY,
                                           @metadata.to_json),
          fields: 'metadataValue'
      )
    end

    def build_score_cond_format_requests
      cur_row = @metadata.next_blank_row
      score_col = ('A'..'Z').to_a[@metadata.match_count + 1]
      score_col_range = grid_range(@sheet_id, (cur_row - 1)..cur_row,
                                   (@metadata.match_count + 1)..(@metadata.match_count + 2))

      rules = []
      rules << BooleanRule.new(
          condition: bool_condition('NUMBER_EQ', '0'),
          format: CellFormat.new(background_color: white)
      )
      rules << BooleanRule.new(
          condition: bool_condition('BLANK'),
          format: CellFormat.new(background_color: white)
      )
      rules << BooleanRule.new(
          condition: bool_condition(
              'CUSTOM_FORMULA', "=$#{score_col}:$#{score_col}=max(#{score_col}:#{score_col})"),
          format: CellFormat.new(background_color: green)
      )
      rules << BooleanRule.new(
          condition: bool_condition(
              'CUSTOM_FORMULA', "=$#{score_col}:$#{score_col}=min(#{score_col}:#{score_col})"),
          format: CellFormat.new(background_color: light_red)
      )

      rules.map.with_index do |rule, index|
        AddConditionalFormatRuleRequest.new(
            index: index, rule: ConditionalFormatRule.new(
                boolean_rule: rule,
                ranges: [score_col_range]
            )
        )
      end
    end

    def picks_cells
      @picks.flat_map.with_index do |day_picks, day|
        cells = day_picks.map { |pick| cell_data(pick) }
        cells += (@metadata.match_days[day].match_count - cells.count).times.map { cell_data('') }
        cells.last.user_entered_format.borders = right_border
        cells
      end
    end

    def score_cells
      end_col = ('A'..'Z').to_a[@metadata.match_count]
      cur_row = @metadata.next_blank_row

      [cell_data("=SUMPRODUCT(--(B#{cur_row}:#{end_col}#{cur_row}=$B$4:$#{end_col}$4))",
                 h_align: 'RIGHT'),
       cell_data("=MIN(COUNTIF($B$4:$#{end_col}$4, \"<>-\"), SUMPRODUCT(LEN(B#{cur_row}:#{end_col}#{cur_row})>0))",
                 h_align: 'RIGHT'),
       cell_data("=IFERROR(#{end_col.succ}#{cur_row}/#{end_col.succ.succ}#{cur_row}, 0)",
                 h_align: 'RIGHT', num_format: 'PERCENT')]
    end
  end
end
