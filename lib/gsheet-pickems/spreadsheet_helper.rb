# SpreadsheetHelper
#
# AUTHOR::  Kyle Mullins

module GSheetPickems
  module SpreadsheetHelper
    def standard_border
      @standard_border ||= Border.new(
          style: 'SOLID', color: Color.new(red: 0, green: 0, blue: 0, alpha: 1))
    end

    def right_border
      @right_border ||= Borders.new(right: standard_border)
    end

    def full_borders
      @full_borders ||= Borders.new(top: standard_border, bottom: standard_border,
                                    left: standard_border, right: standard_border)
    end

    def light_gray
      @light_gray ||= Color.new(red: 0.851, green: 0.851, blue: 0.851, alpha: 1)
    end

    def light_green
      @light_green ||= Color.new(red: 0.72, green: 0.88, blue: 0.8, alpha: 1)
    end

    def white
      @white ||= Color.new(red: 1, green: 1, blue: 1, alpha: 1)
    end

    def green
      @green ||= Color.new(red: 0.71, green: 0.84, blue: 0.66, alpha: 1)
    end

    def light_red
      @light_red ||= Color.new(red: 0.92, green: 0.6, blue: 0.6, alpha: 1)
    end

    def cell_value(val)
      return ExtendedValue.new(formula_value: val) if val.start_with?('=')

      ExtendedValue.new(string_value: val)
    end

    def cell_data(val, bg_color: nil, h_align: 'LEFT', borders: nil, num_format: nil)
      CellData.new(user_entered_value: cell_value(val)).tap do |cell|
        cell.user_entered_format = CellFormat.new(horizontal_alignment: h_align)
        cell.user_entered_format.background_color = bg_color unless bg_color.nil?
        cell.user_entered_format.borders = borders unless borders.nil?
        cell.user_entered_format.number_format = NumberFormat.new(type: num_format) unless num_format.nil?
      end
    end

    def grid_range(sheet_id, row_range, col_range)
      GridRange.new(
          sheet_id: sheet_id, start_row_index: row_range.first,
          end_row_index: row_range.last, start_column_index: col_range.first,
          end_column_index: col_range.last
      )
    end

    def merge_cells(sheet_id, row_range, col_range)
      MergeCellsRequest.new(
          range: grid_range(sheet_id, row_range, col_range),
          merge_type: 'MERGE_ALL'
      )
    end

    def dev_metadata(sheet_id, key, value)
      DeveloperMetadata.new(
          metadata_key: key,
          metadata_value: value,
          location: DeveloperMetadataLocation.new(sheet_id: sheet_id),
          visibility: 'DOCUMENT'
      )
    end

    def bool_condition(type, *values)
      BooleanCondition.new(
          type: type,
          values: values.map { |val| ConditionValue.new(user_entered_value: val) }
      )
    end

    def batch_update(sheets_service, *requests)
      batch_request = BatchUpdateSpreadsheetRequest.new(requests: requests)
      batch_response = sheets_service.batch_update_spreadsheet(@spreadsheet_id,
                                                               batch_request)
      puts batch_response.to_json
      batch_response
    end
  end
end
