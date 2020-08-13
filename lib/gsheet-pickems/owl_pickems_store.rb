# OwlPickemsStore
#
# AUTHOR::  Kyle Mullins

require 'redis-objects'

class OwlPickemsStore
  def initialize(server_redis)
    @redis = server_redis
    @alias_hash = Redis::HashKey.new([@redis.namespace, :user_aliases])
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

  def aliased?(user_id)
    @alias_hash.key?(user_id)
  end

  def add_alias(user_id, user_alias)
    @alias_hash[user_id] = user_alias
  end

  def delete_alias(user_id)
    @alias_hash.delete(user_id)
  end

  def alias(user_id)
    @alias_hash[user_id]
  end

  def aliased_users
    @alias_hash.keys
  end
end
