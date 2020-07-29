# SpreadsheetService
#
# AUTHOR::  Kyle Mullins

require 'googleauth'
require 'gsheet-pickems/pickem_template_builder'
require 'gsheet-pickems/pickem_row_builder'
require 'gsheet-pickems/pickem_metadata'

module GSheetPickems
  class SpreadsheetService
    def initialize(app_name:, credentials_file:, spreadsheet_id:)
      @spreadsheet_id = spreadsheet_id
      @sheets_service = SheetsService.new.tap do |service|
        service.client_options.application_name = app_name
        service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
            json_key_io: File.open(credentials_file),
            scope: AUTH_SPREADSHEETS
        )
      end
    end

    def add_week(picks_week)
      PickemTemplateBuilder.new(@spreadsheet_id, picks_week.title,
                                picks_week.metadata).build(@sheets_service)
    rescue Google::Apis::Error => err
      raise GSheetPickems::Error.new(source_error: err)
    end

    def add_picks(sheet_id, picks, metadata: nil)
      metadata ||= sheet_metadata(sheet_id)
      PickemRowBuilder.new(@spreadsheet_id, sheet_id, picks.player, picks.picks,
                           metadata).build(@sheets_service)
    rescue Google::Apis::Error => err
      raise GSheetPickems::Error.new(source_error: err)
    end

    def sheet_metadata(sheet_id)
      found_metadata = @sheets_service.search_developer_metadatum_developer_metadata(
          @spreadsheet_id, SearchDeveloperMetadataRequest.new(data_filters: [
          DataFilter.new(
              developer_metadata_lookup: DeveloperMetadataLookup.new(
                  location_type: 'SHEET',
                  metadata_location: DeveloperMetadataLocation.new(sheet_id: sheet_id),
                  metadata_key: PickemMetadata::METADATA_KEY
              )
          )
      ])
      ).matched_developer_metadata.first.developer_metadata
      PickemMetadata.from_json(found_metadata.metadata_value)
    rescue Google::Apis::Error => err
      raise GSheetPickems::Error.new(source_error: err)
    end

    def spreadsheet_name
      return nil if @spreadsheet_id.nil?

      @sheets_service.get_spreadsheet(@spreadsheet_id)&.properties&.title
    rescue Google::Apis::ClientError
      nil
    rescue Google::Apis::Error => err
      raise GSheetPickems::Error.new(source_error: err)
    end

    def sheet_name(sheet_id)
      return nil if @spreadsheet_id.nil? || sheet_id.nil?

      @sheets_service.get_spreadsheet(@spreadsheet_id)
                     .sheets.map(&:properties)
                     .find { |sheet| sheet.sheet_id == sheet_id }&.title
    rescue Google::Apis::ClientError
      nil
    rescue Google::Apis::Error => err
      raise GSheetPickems::Error.new(source_error: err)
    end
  end
end
