prometheus = require("prometheus/prometheus")
require("train")
require("yarm")
require("events")

bucket_settings = train_buckets(settings.startup["graftorio2-train-histogram-buckets"].value)
nth_tick = settings.startup["graftorio2-nth-tick"].value
server_save = settings.startup["graftorio2-server-save"].value

gauge_tick = prometheus.gauge("factorio_tick", "game tick")
gauge_connected_player_count = prometheus.gauge("factorio_connected_player_count", "connected players")
gauge_total_player_count = prometheus.gauge("factorio_total_player_count", "total registered players")

gauge_item_production_input = prometheus.gauge("factorio_item_production_input", "items produced", {"force", "name"})
gauge_item_production_output = prometheus.gauge("factorio_item_production_output", "items consumed", {"force", "name"})

gauge_fluid_production_input = prometheus.gauge("factorio_fluid_production_input", "fluids produced", {"force", "name"})
gauge_fluid_production_output = prometheus.gauge("factorio_fluid_production_output", "fluids consumed", {"force", "name"})

gauge_kill_count_input = prometheus.gauge("factorio_kill_count_input", "kills", {"force", "name"})
gauge_kill_count_output = prometheus.gauge("factorio_kill_count_output", "losses", {"force", "name"})

gauge_entity_build_count_input = prometheus.gauge("factorio_entity_build_count_input", "entities placed", {"force", "name"})
gauge_entity_build_count_output = prometheus.gauge("factorio_entity_build_count_output", "entities removed", {"force", "name"})

gauge_items_launched = prometheus.gauge("factorio_items_launched_total", "items launched in rockets", {"force", "name"})

gauge_yarm_site_amount = prometheus.gauge("factorio_yarm_site_amount", "YARM - site amount remaining", {"force", "name", "type"})
gauge_yarm_site_ore_per_minute = prometheus.gauge("factorio_yarm_site_ore_per_minute", "YARM - site ore per minute", {"force", "name", "type"})
gauge_yarm_site_remaining_permille = prometheus.gauge("factorio_yarm_site_remaining_permille", "YARM - site permille remaining", {"force", "name", "type"})

gauge_train_trip_time = prometheus.gauge("factorio_train_trip_time", "train trip time", {"from", "to", "train_id"})
gauge_train_wait_time = prometheus.gauge("factorio_train_wait_time", "train wait time", {"from", "to", "train_id"})

histogram_train_trip_time = prometheus.histogram("factorio_train_trip_time_groups", "train trip time", {"from", "to", "train_id"}, bucket_settings)
histogram_train_wait_time = prometheus.histogram("factorio_train_wait_time_groups", "train wait time", {"from", "to", "train_id"}, bucket_settings)

gauge_train_direct_loop_time = prometheus.gauge("factorio_train_direct_loop_time", "train direct loop time", {"a", "b"})
histogram_train_direct_loop_time = prometheus.histogram("factorio_train_direct_loop_time_groups", "train direct loop time", {"a", "b"}, bucket_settings)

gauge_train_arrival_time = prometheus.gauge("factorio_train_arrival_time", "train arrival time", {"station"})
histogram_train_arrival_time = prometheus.histogram("factorio_train_arrival_time_groups", "train arrival time", {"station"}, bucket_settings)

gauge_logistic_network_all_construction_robots = prometheus.gauge("factorio_logistic_network_all_construction_robots", "the number of construction robots available for a job", {"force", "location", "network"})
gauge_logistic_network_available_construction_robots = prometheus.gauge("factorio_logistic_network_available_construction_robots", "the total number of construction robots in the network (idle and active + in roboports)", {"force", "location", "network"})
gauge_logistic_network_all_logistic_robots = prometheus.gauge("factorio_logistic_network_all_logistic_robots", "the total number of logistic robots in the network (idle and active + in roboports)", {"force", "location", "network"})
gauge_logistic_network_available_logistic_robots = prometheus.gauge("factorio_logistic_network_available_logistic_robots", "the number of logistic robots available for a job", {"force", "location", "network"})
gauge_logistic_network_robot_limit = prometheus.gauge("factorio_logistic_network_robot_limit", "the maximum number of robots the network can work with", {"force", "location", "network"})
gauge_logistic_network_items = prometheus.gauge("factorio_logistic_network_items", "the number of items in a logistic network", {"force", "location", "network", "name"})

script.on_init(function()
  if game.active_mods["YARM"] then
      script.on_event(remote.call("YARM", "get_on_site_updated_event_id"), handleYARM)
  end

  script.on_nth_tick(nth_tick, register_events)

  script.on_event(defines.events.on_player_joined_game, register_events_players)
  script.on_event(defines.events.on_player_left_game, register_events_players)
  script.on_event(defines.events.on_player_removed, register_events_players)
  script.on_event(defines.events.on_player_kicked, register_events_players)
  script.on_event(defines.events.on_player_banned, register_events_players)

  script.on_event(defines.events.on_train_changed_state, register_events_train)
end)

script.on_load(function()
  script.on_nth_tick(nth_tick, register_events)

  script.on_event(defines.events.on_player_joined_game, register_events_players)
  script.on_event(defines.events.on_player_left_game, register_events_players)
  script.on_event(defines.events.on_player_removed, register_events_players)
  script.on_event(defines.events.on_player_kicked, register_events_players)
  script.on_event(defines.events.on_player_banned, register_events_players)

  script.on_event(defines.events.on_train_changed_state, register_events_train)
end)

script.on_configuration_changed(function(event)
  if game.active_mods["YARM"] then
      script.on_event(remote.call("YARM", "get_on_site_updated_event_id"), handleYARM)
  end
end)
