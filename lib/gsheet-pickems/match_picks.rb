# MatchPicks
#
# AUTHOR::  Kyle Mullins

module GSheetPickems
  class MatchPicks
    attr_reader :player, :picks

    def initialize(player:, picks:)
      @player = player
      @picks = picks
    end
  end
end
