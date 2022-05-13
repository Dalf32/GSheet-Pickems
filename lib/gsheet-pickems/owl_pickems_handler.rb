# OwlPickemsHandler
#
# AUTHOR::  Kyle Mullins

require 'gsheet-pickems'
require 'gsheet-pickems/owl_pickems_store'

class OwlPickemsHandler < CommandHandler
  feature :pickems, default_enabled: false,
          description: 'Allows users to enter pickems for Overwatch League.'

  command(:managepickems, :manage_pickems)
    .feature(:pickems).args_range(0, 3).pm_enabled(false)
    .permissions(:manage_server).usage('managepickems [option] [argument]')
    .description('Used to set up pickems')

  command(:pickems, :link_pickems)
    .feature(:pickems).no_args.pm_enabled(false)
    .usage('pickems').description('')

  command(:newsheet, :add_new_sheet)
    .feature(:pickems).min_args(1).pm_enabled(false)
    .usage('newsheet <sheet name>').description('')

  command(:enterpicks, :enter_picks)
    .feature(:pickems).max_args(1).pm_enabled(false)
    .usage('enterpicks [user]').description('')

  def redis_name
    :pickems
  end

  def config_name
    :pickems
  end

  def manage_pickems(event, *args)
    event.channel.start_typing
    return manage_pickems_summary if args.empty?

    case args.first
    when 'help'
      manage_pickems_help
    when 'spreadsheet'
      return 'Spreadsheet ID or URL is required' if args.size == 1

      set_spreadsheet_id(args[1])
    when 'opensheet'
      return 'Sheet ID is required' if args.size == 1

      set_current_sheet_id(args[1])
    when 'closesheet'
      pickems_store.clear_current_sheet_id
      'The active sheet has been closed'
    when 'alias'
      return 'User and alias are required' unless args.size == 3

      manage_user_alias(args[1], :add, args[2])
    when 'delalias'
      return 'User is required' if args.size == 1

      manage_user_alias(args[1], :delete)
    when 'disable'
      disable_pickems
    else
      'Invalid option.'
    end
  end

  def link_pickems(_event)
    return 'Pickems are disabled, set a pickems spreadsheet to enable.' unless pickems_store.enabled?

    url = "https://docs.google.com/spreadsheets/d/#{pickems_store.spreadsheet_id}"
    url += "/edit#gid=#{pickems_store.current_sheet_id}" if pickems_store.has_current_sheet?
    url
  end

  def add_new_sheet(event, *sheet_name)
    return 'Pickems are disabled, set a pickems spreadsheet to enable.' unless pickems_store.enabled?

    num_days = prompt(event, 'How many days of games are there?')&.to_i
    return 'Invalid or no response, operation cancelled.' if num_days.nil? || num_days.zero?

    match_days = num_days.times.map do |day_num|
      matches = prompt(event, "How many games are played on Day #{day_num + 1}?")&.to_i
      return 'Invalid or no response, operation cancelled.' if matches.nil? || matches.zero?

      GSheetPickems::PicksDay.new(name: "Day #{day_num + 1}", match_count: matches)
    end

    event.channel.start_typing
    sheet_id = pickems_service.add_week(GSheetPickems::PicksPeriod.new(
        title: sheet_name.join(' '), picks_days: match_days))
    pickems_store.current_sheet_id = sheet_id
    "Sheet #{sheet_name.join(' ')} has been added and set as the active sheet."
  rescue GSheetPickems::Error => err
    log.error(err)
    'An error occurred, the sheet was not created.'
  end

  def enter_picks(event, *user_input)
    return 'Pickems are disabled, set a pickems spreadsheet to enable.' unless pickems_store.enabled?
    return 'There is no active sheet.' unless pickems_store.has_current_sheet?
    return 'You do not have permission to enter picks for other users.' unless user_input.empty? or user.permission?(:manage_server)

    event.channel.start_typing
    current_sheet_id = pickems_store.current_sheet_id
    metadata = pickems_service.sheet_metadata(current_sheet_id)

    picks = metadata.num_days.times.map do |day_num|
      day = metadata.match_days[day_num]
      matches_str = "#{day.match_count} match#{day.match_count > 1 ? 'es' : ''}"
      input = prompt(event, "Input picks for #{day.name} (#{matches_str}):", timeout: 60)
      return 'Invalid or no response, operation cancelled.' if input.nil?

      input.split(',').map(&:strip)
    end

    player_name = resolve_user(user_input.first)
    match_picks = GSheetPickems::MatchPicks.new(player: player_name, picks: picks)

    event.channel.start_typing
    pickems_service.add_picks(current_sheet_id, match_picks, metadata: metadata)
    "Picks added for #{player_name}"
  rescue GSheetPickems::Error => err
    log.error(err)
    'An error occurred, your picks were not added.'
  end

  private

  def pickems_store
    @pickems_store ||= OwlPickemsStore.new(server_redis)
  end

  def pickems_service
    @pickems_service ||= create_spreadsheet_service(pickems_store.spreadsheet_id)
  end

  def create_spreadsheet_service(spreadsheet_id)
    GSheetPickems::SpreadsheetService.new(
        app_name: config.app_name, credentials_file: config.credentials_file,
        spreadsheet_id: spreadsheet_id)
  end

  def manage_pickems_summary
    return 'Pickems are disabled, set a pickems spreadsheet to enable.' unless pickems_store.enabled?

    sheet_name = pickems_service.sheet_name(pickems_store.current_sheet_id)
    users = pickems_store.aliased_users.map { |id| @server.member(id)&.display_name }

    <<~SUMMARY
      Pickems spreadsheet: #{pickems_service.spreadsheet_name}
      Active sheet: #{sheet_name || '*no active sheet*'}
      Aliased users: #{users.empty? ? '*none*' : users.compact.join(', ')}
    SUMMARY
  end

  def manage_pickems_help
    <<~HELP
      help - Displays this help text
      spreadsheet - Sets the spreadsheet to be used for these pickems
      opensheet - Sets the active sheet so picks can be entered for it
      closesheet - Clears the active sheet so no more picks can be entered for it
      alias - Creates an alias for a user to be used when they enter pickems
      delalias - Removes an alias for the given user
      disable - Disables pickems
    HELP
  end

  def set_spreadsheet_id(input)
    id_regex = /docs.google.com\/spreadsheets\/d\/([0-9a-z_]+)/i
    spreadsheet_id = if input.include?('docs.google.com')
                       id_regex.match(input)[1]
                     else
                       input
                     end

    spreadsheet_name = create_spreadsheet_service(spreadsheet_id).spreadsheet_name
    return 'Invalid spreadsheet ID or URL.' if spreadsheet_name.nil?

    pickems_store.spreadsheet_id = spreadsheet_id
    "Pickems spreadsheet has been set to #{spreadsheet_name}"
  end

  def set_current_sheet_id(input)
    sheet_name = pickems_service.sheet_name(input.to_i)
    return 'Invalid sheet ID.' if sheet_name.nil?

    pickems_store.current_sheet_id = input
    "Active sheet has been set to #{sheet_name}"
  end

  def disable_pickems
    pickems_store.clear_spreadsheet_id
    pickems_store.clear_current_sheet_id
    'Pickems have been disabled.'
  end

  def manage_user_alias(user, action, user_alias = nil)
    found_user = find_user(user)

    return found_user.error if found_user.failure?

    if action == :add
      pickems_store.add_alias(found_user.value.id, user_alias)
      "Alias #{user_alias} added for #{found_user.value.display_name}"
    elsif action == :delete
      pickems_store.delete_alias(found_user.value.id)
      "Alias deleted for #{found_user.value.display_name}"
    end
  end

  def delete_user_alias(user)
    found_user = find_user(user)

    return found_user.error if found_user.failure?


  end

  def resolve_user(user_input)
    user_input || pickems_store.alias(user.id) || user.display_name
  end

  def prompt(event, question, timeout: 30, **opts)
    event.message.reply(question)
    @user.await!(timeout: timeout, **opts)&.text
  end
end
