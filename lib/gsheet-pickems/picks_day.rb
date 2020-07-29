# PicksDay
#
# AUTHOR::  Kyle Mullins

module GSheetPickems
  class PicksDay
    attr_reader :name, :match_count

    def initialize(name:, match_count:)
      @name = name
      @match_count = match_count
    end
  end
end
