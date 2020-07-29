# PicksPeriod
#
# AUTHOR::  Kyle Mullins

require 'gsheet-pickems/pickem_metadata'
require 'gsheet-pickems/picks_day'

module GSheetPickems
  class PicksPeriod
    attr_reader :title

    def initialize(title:, picks_days:)
      @title = title
      @picks_days = picks_days
    end

    def metadata
      PickemMetadata.new(num_days: @picks_days.count, match_days: @picks_days)
    end
  end
end
