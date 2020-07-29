# PickemMetadata
#
# AUTHOR::  Kyle Mullins

require 'json'

module GSheetPickems
  class PickemMetadata
    METADATA_KEY = 'Metadata'

    attr_accessor :num_days, :match_days, :score_column, :next_blank_row

    def initialize(num_days:, match_days:)
      @num_days = num_days
      @match_days = match_days

      @score_column = match_count + 1
      @next_blank_row = 5
    end

    def match_count
      @match_days.map(&:match_count).sum
    end

    def to_json
      {
          num_days: @num_days,
          match_days: @match_days.map(&:match_count),
          score_column: @score_column,
          next_blank_row: @next_blank_row
      }.to_json
    end

    def self.from_json(json_str)
      from_hash(JSON.parse(json_str, symbolize_names: true))
    end

    def self.from_hash(hash)
      days = hash[:match_days].map.with_index do |count, i|
        PicksDay.new(name: "Day #{i + 1}", match_count: count)
      end
      PickemMetadata.new(num_days: hash[:num_days],
                         match_days: days).tap do |metadata|
        metadata.score_column = hash[:score_column]
        metadata.next_blank_row = hash[:next_blank_row]
      end
    end
  end
end
