require 'gsheet-pickems/match_picks'
require 'gsheet-pickems/picks_period'
require 'gsheet-pickems/spreadsheet_service'
require 'gsheet-pickems/version'

module GSheetPickems
  class Error < StandardError
    def initialize(source_error: nil, message: nil)
      @message = source_error.message unless source_error.nil?
      set_backtrace(source_error.backtrace) unless source_error.nil?
      @message ||= message
    end
  end
end
