# PickemsStore
#
# AUTHOR::  Kyle Mullins

class PickemsStore
  def initialize(server_redis)
    @redis = server_redis
  end

  def enabled?
    @redis.exists(:spreadsheet_id)
  end

  def spreadsheet_id
    @redis.get(:spreadsheet_id)
  end

  def spreadsheet_id=(id)
    @redis.set(:spreadsheet_id, id)
  end

  def clear_spreadsheet_id
    @redis.del(:spreadsheet_id)
  end

  def has_current_sheet?
    @redis.exists(:current_sheet_id)
  end

  def current_sheet_id
    @redis.get(:current_sheet_id).to_i
  end

  def current_sheet_id=(id)
    @redis.set(:current_sheet_id, id)
  end

  def clear_current_sheet_id
    @redis.del(:current_sheet_id)
  end

  def user_aliases
    {}
  end

  def alias(user)
    nil
  end
end
