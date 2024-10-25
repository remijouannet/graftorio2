function register_events(event)
	gauge_tick:set(game.tick)

	for _, surface in pairs(game.surfaces) do
		gauge_seed:set(surface.map_gen_settings.seed, { surface.name })
	end

	for name, version in pairs(script.active_mods) do
		gauge_mods:set(1, { name, version })
	end

	for _, surface in pairs(game.surfaces) do
		local stats = game.get_pollution_statistics(surface)
		for name, n in pairs(stats.input_counts) do
			gauge_pollution_production_input:set(n, { name, surface.name })
		end
		for name, n in pairs(stats.output_counts) do
			gauge_pollution_production_output:set(n, { name, surface.name })
		end
	end

	for _, player in pairs(game.players) do
		for _, surface in pairs(game.surfaces) do
			local stats = {
				{ player.force.get_item_production_statistics(surface), gauge_item_production_input, gauge_item_production_output },
				{ player.force.get_fluid_production_statistics(surface), gauge_fluid_production_input, gauge_fluid_production_output },
				{ player.force.get_kill_count_statistics(surface), gauge_kill_count_input, gauge_kill_count_output },
				{
					player.force.get_entity_build_count_statistics(surface),
					gauge_entity_build_count_input,
					gauge_entity_build_count_output,
				},
			}

			for _, stat in pairs(stats) do
				for name, n in pairs(stat[1].input_counts) do
					stat[2]:set(n, { player.force.name, name, surface.name })
				end

				for name, n in pairs(stat[1].output_counts) do
					stat[3]:set(n, { player.force.name, name, surface.name })
				end
			end

			local evolution = {
				{ player.force.get_evolution_factor(surface), "total" },
				{ player.force.get_evolution_factor_by_pollution(surface), "by_pollution" },
				{ player.force.get_evolution_factor_by_time(surface), "by_time" },
				{ player.force.get_evolution_factor_by_killing_spawners(surface), "by_killing_spawners" },
			}

			for _, stat in pairs(evolution) do
				gauge_evolution:set(stat[1], { player.force.name, stat[2], surface.name })
			end

			for _, entry in ipairs(player.force.items_launched) do
				gauge_items_launched:set(entry.count, { player.force.name, entry.name, entry.quality }) -- this one seems broken :(
			end
		end

		gauge_logistic_network_all_logistic_robots:reset()
		gauge_logistic_network_available_logistic_robots:reset()
		gauge_logistic_network_all_construction_robots:reset()
		gauge_logistic_network_available_construction_robots:reset()
		gauge_logistic_network_robot_limit:reset()
		gauge_logistic_network_items:reset()
		for surface, networks in pairs(player.force.logistic_networks) do
			for _, network in ipairs(networks) do
				local network_id = tostring(network.network_id)
				gauge_logistic_network_all_logistic_robots:set(
					network.all_logistic_robots,
					{ player.force.name, surface, network_id }
				)
				gauge_logistic_network_available_logistic_robots:set(
					network.available_logistic_robots,
					{ player.force.name, surface, network_id }
				)
				gauge_logistic_network_all_construction_robots:set(
					network.all_construction_robots,
					{ player.force.name, surface, network_id }
				)
				gauge_logistic_network_available_construction_robots:set(
					network.available_construction_robots,
					{ player.force.name, surface, network_id }
				)
				gauge_logistic_network_robot_limit:set(network.robot_limit, { player.force.name, surface, network_id })
				if network.get_contents() ~= nil then
					for _, entry in ipairs(network.get_contents()) do
						gauge_logistic_network_items:set(entry.count, { player.force.name, surface, network_id, entry.name, entry.quality })
					end
				end
			end
		end

		-- research tick handler
		on_research_tick(player, event)
	end

	-- power tick handler
	on_power_tick(event)

	-- circuit network tick handler
	on_circuit_network_tick(event)

	if server_save then
		helpers.write_file("graftorio2/game.prom", prometheus.collect(), false, 0)
	else
		helpers.write_file("graftorio2/game.prom", prometheus.collect(), false)
	end
end

function register_events_players(event)
	gauge_connected_player_count:set(#game.connected_players)
	gauge_total_player_count:set(#game.players)
end
