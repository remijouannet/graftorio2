prometheus = require("prometheus/prometheus")
require("train")
require("yarm")
require("events")
require("power")
require("research")
require("circuit-network")

bucket_settings = train_buckets(settings.startup["graftorio2-train-histogram-buckets"].value)
nth_tick = settings.startup["graftorio2-nth-tick"].value
server_save = settings.startup["graftorio2-server-save"].value
disable_train_stats = settings.startup["graftorio2-disable-train-stats"].value

gauge_tick = prometheus.gauge("factorio_tick", "game tick")
gauge_connected_player_count = prometheus.gauge("factorio_connected_player_count", "connected players")
gauge_total_player_count = prometheus.gauge("factorio_total_player_count", "total registered players")

gauge_seed = prometheus.gauge("factorio_seed", "seed", { "surface" })
gauge_mods = prometheus.gauge("factorio_mods", "mods", { "name", "version" })

gauge_item_production_input = prometheus.gauge("factorio_item_production_input", "items produced", { "force", "name", "surface" })
gauge_item_production_output =
	prometheus.gauge("factorio_item_production_output", "items consumed", { "force", "name", "surface" })

gauge_fluid_production_input =
	prometheus.gauge("factorio_fluid_production_input", "fluids produced", { "force", "name", "surface" })
gauge_fluid_production_output =
	prometheus.gauge("factorio_fluid_production_output", "fluids consumed", { "force", "name", "surface" })

gauge_kill_count_input = prometheus.gauge("factorio_kill_count_input", "kills", { "force", "name", "surface" })
gauge_kill_count_output = prometheus.gauge("factorio_kill_count_output", "losses", { "force", "name", "surface" })

gauge_entity_build_count_input =
	prometheus.gauge("factorio_entity_build_count_input", "entities placed", { "force", "name", "surface" })
gauge_entity_build_count_output =
	prometheus.gauge("factorio_entity_build_count_output", "entities removed", { "force", "name", "surface" })

gauge_pollution_production_input =
	prometheus.gauge("factorio_pollution_production_input", "pollutions produced", { "name", "surface" })
gauge_pollution_production_output =
	prometheus.gauge("factorio_pollution_production_output", "pollutions consumed", { "name", "surface" })

gauge_evolution = prometheus.gauge("factorio_evolution", "evolution", { "force", "type", "surface" })

gauge_research_queue = prometheus.gauge("factorio_research_queue", "research", { "force", "name", "level", "index" })

gauge_items_launched =
	prometheus.gauge("factorio_items_launched_total", "items launched in rockets", { "force", "name", "quality" })

gauge_yarm_site_amount =
	prometheus.gauge("factorio_yarm_site_amount", "YARM - site amount remaining", { "force", "name", "type" })
gauge_yarm_site_ore_per_minute =
	prometheus.gauge("factorio_yarm_site_ore_per_minute", "YARM - site ore per minute", { "force", "name", "type" })
gauge_yarm_site_remaining_permille = prometheus.gauge(
	"factorio_yarm_site_remaining_permille",
	"YARM - site permille remaining",
	{ "force", "name", "type" }
)

gauge_train_trip_time = prometheus.gauge("factorio_train_trip_time", "train trip time", { "from", "to", "train_id" })
gauge_train_wait_time = prometheus.gauge("factorio_train_wait_time", "train wait time", { "from", "to", "train_id" })

histogram_train_trip_time = prometheus.histogram(
	"factorio_train_trip_time_groups",
	"train trip time",
	{ "from", "to", "train_id" },
	bucket_settings
)
histogram_train_wait_time = prometheus.histogram(
	"factorio_train_wait_time_groups",
	"train wait time",
	{ "from", "to", "train_id" },
	bucket_settings
)

gauge_train_direct_loop_time =
	prometheus.gauge("factorio_train_direct_loop_time", "train direct loop time", { "a", "b" })
histogram_train_direct_loop_time = prometheus.histogram(
	"factorio_train_direct_loop_time_groups",
	"train direct loop time",
	{ "a", "b" },
	bucket_settings
)

gauge_train_arrival_time = prometheus.gauge("factorio_train_arrival_time", "train arrival time", { "station" })
histogram_train_arrival_time =
	prometheus.histogram("factorio_train_arrival_time_groups", "train arrival time", { "station" }, bucket_settings)

gauge_logistic_network_all_construction_robots = prometheus.gauge(
	"factorio_logistic_network_all_construction_robots",
	"the total number of construction robots in the network (idle and active + in roboports)",
	{ "force", "surface", "network" }
)
gauge_logistic_network_available_construction_robots = prometheus.gauge(
	"factorio_logistic_network_available_construction_robots",
	"the number of construction robots available for a job",
	{ "force", "surface", "network" }
)

gauge_logistic_network_all_logistic_robots = prometheus.gauge(
	"factorio_logistic_network_all_logistic_robots",
	"the total number of logistic robots in the network (idle and active + in roboports)",
	{ "force", "surface", "network" }
)
gauge_logistic_network_available_logistic_robots = prometheus.gauge(
	"factorio_logistic_network_available_logistic_robots",
	"the number of logistic robots available for a job",
	{ "force", "surface", "network" }
)

gauge_logistic_network_robot_limit = prometheus.gauge(
	"factorio_logistic_network_robot_limit",
	"the maximum number of robots the network can work with",
	{ "force", "surface", "network" }
)

gauge_logistic_network_items = prometheus.gauge(
	"factorio_logistic_network_items",
	"the number of items in a logistic network",
	{ "force", "surface", "network", "name", "quality" }
)

gauge_circuit_network_signal = prometheus.gauge(
	"factorio_circuit_network_signal",
	"the value of a signal in a circuit network",
	{ "force", "surface", "network", "name", "quality" }
)

gauge_circuit_network_monitored = prometheus.gauge(
	"factorio_circuit_network_monitored",
	"whether a circuit network with given ID is being monitored",
	{ "force", "surface", "network" }
)

gauge_power_production_input =
	prometheus.gauge("factorio_power_production_input", "power produced", { "force", "name", "network", "surface" })
gauge_power_production_output =
	prometheus.gauge("factorio_power_production_output", "power consumed", { "force", "name", "network", "surface" })

script.on_init(function()
	if script.active_mods["YARM"] then
		storage.yarm_on_site_update_event_id = remote.call("YARM", "get_on_site_updated_event_id")
		script.on_event(storage.yarm_on_site_update_event_id, handleYARM)
	end

	on_power_init()
	on_circuit_network_init()

	script.on_nth_tick(nth_tick, register_events)

	script.on_event(defines.events.on_player_joined_game, register_events_players)
	script.on_event(defines.events.on_player_left_game, register_events_players)
	script.on_event(defines.events.on_player_removed, register_events_players)
	script.on_event(defines.events.on_player_kicked, register_events_players)
	script.on_event(defines.events.on_player_banned, register_events_players)

	-- train envents
	if not disable_train_stats then
		script.on_event(defines.events.on_train_changed_state, register_events_train)
	end

	-- power events
	script.on_event(defines.events.on_built_entity, on_power_build)
	script.on_event(defines.events.on_robot_built_entity, on_power_build)
	script.on_event(defines.events.script_raised_built, on_power_build)
	script.on_event(defines.events.on_player_mined_entity, on_power_destroy)
	script.on_event(defines.events.on_robot_mined_entity, on_power_destroy)
	script.on_event(defines.events.on_entity_died, on_power_destroy)
	script.on_event(defines.events.script_raised_destroy, on_power_destroy)

	-- research events
	script.on_event(defines.events.on_research_finished, on_research_finished)

	-- circuit-network
	script.on_event(defines.events.on_built_entity, on_circuit_network_build)
	script.on_event(defines.events.on_robot_built_entity, on_circuit_network_build)
	script.on_event(defines.events.on_space_platform_built_entity, on_circuit_network_build)
	script.on_event(defines.events.script_raised_built, on_circuit_network_build)
	script.on_event(defines.events.on_player_mined_entity, on_circuit_network_destroy)
	script.on_event(defines.events.on_robot_mined_entity, on_circuit_network_destroy)
	script.on_event(defines.events.on_space_platform_mined_entity, on_circuit_network_destroy)
	script.on_event(defines.events.on_entity_died, on_circuit_network_destroy)
	script.on_event(defines.events.script_raised_destroy, on_circuit_network_destroy)
end)

script.on_load(function()
	if storage.yarm_on_site_update_event_id then
		if script.get_event_handler(storage.yarm_on_site_update_event_id) then
			script.on_event(storage.yarm_on_site_update_event_id, handleYARM)
		end
	end

	on_power_load()
	on_circuit_network_load()

	script.on_nth_tick(nth_tick, register_events)

	script.on_event(defines.events.on_player_joined_game, register_events_players)
	script.on_event(defines.events.on_player_left_game, register_events_players)
	script.on_event(defines.events.on_player_removed, register_events_players)
	script.on_event(defines.events.on_player_kicked, register_events_players)
	script.on_event(defines.events.on_player_banned, register_events_players)

	-- train events
	if not disable_train_stats then
		script.on_event(defines.events.on_train_changed_state, register_events_train)
	end

	-- power events
	script.on_event(defines.events.on_built_entity, on_power_build)
	script.on_event(defines.events.on_robot_built_entity, on_power_build)
	script.on_event(defines.events.script_raised_built, on_power_build)
	script.on_event(defines.events.on_player_mined_entity, on_power_destroy)
	script.on_event(defines.events.on_robot_mined_entity, on_power_destroy)
	script.on_event(defines.events.on_entity_died, on_power_destroy)
	script.on_event(defines.events.script_raised_destroy, on_power_destroy)

	-- research events
	script.on_event(defines.events.on_research_finished, on_research_finished)

	-- circuit-network
	script.on_event(defines.events.on_built_entity, on_circuit_network_build)
	script.on_event(defines.events.on_robot_built_entity, on_circuit_network_build)
	script.on_event(defines.events.script_raised_built, on_circuit_network_build)
	script.on_event(defines.events.on_player_mined_entity, on_circuit_network_destroy)
	script.on_event(defines.events.on_robot_mined_entity, on_circuit_network_destroy)
	script.on_event(defines.events.on_entity_died, on_circuit_network_destroy)
	script.on_event(defines.events.script_raised_destroy, on_circuit_network_destroy)
end)

script.on_configuration_changed(function(event)
	if script.active_mods["YARM"] then
		storage.yarm_on_site_update_event_id = remote.call("YARM", "get_on_site_updated_event_id")
		script.on_event(storage.yarm_on_site_update_event_id, handleYARM)
	end
end)
