function register_events(event)
	gauge_tick:set(game.tick)

	for _, player in pairs(game.players) do
		stats = {
			{ player.force.item_production_statistics, gauge_item_production_input, gauge_item_production_output },
			{ player.force.fluid_production_statistics, gauge_fluid_production_input, gauge_fluid_production_output },
			{ player.force.kill_count_statistics, gauge_kill_count_input, gauge_kill_count_output },
			{
				player.force.entity_build_count_statistics,
				gauge_entity_build_count_input,
				gauge_entity_build_count_output,
			},
                        {
                                game.pollution_statistics,
                                gauge_pollution_production_input,
                                gauge_pollution_production_output,
                        },
		}

		for _, stat in pairs(stats) do
			for name, n in pairs(stat[1].input_counts) do
				stat[2]:set(n, { player.force.name, name })
			end

			for name, n in pairs(stat[1].output_counts) do
				stat[3]:set(n, { player.force.name, name })
			end
		end

                evolution = {
                        {player.force.evolution_factor, "total"},
                        {player.force.evolution_factor_by_pollution, "by_pollution"},
                        {player.force.evolution_factor_by_time, "by_time"},
                        {player.force.evolution_factor_by_killing_spawners, "by_killing_spawners"}
                }

                for _, stat in pairs(evolution) do
                        gauge_evolution:set(stat[1], {player.force.name, stat[2]})
                end

		for name, n in pairs(player.force.items_launched) do
			gauge_items_launched:set(n, { player.force.name, name })
		end

		gauge_logistic_network_all_logistic_robots:reset()
		gauge_logistic_network_available_logistic_robots:reset()
		gauge_logistic_network_all_construction_robots:reset()
		gauge_logistic_network_available_construction_robots:reset()
		gauge_logistic_network_robot_limit:reset()
		gauge_logistic_network_items:reset()
		for name, n in pairs(player.force.logistic_networks) do
			for i in ipairs(n) do
				gauge_logistic_network_all_logistic_robots:set(
					n[i].all_logistic_robots,
					{ player.force.name, name, tostring(i) }
				)
				gauge_logistic_network_available_logistic_robots:set(
					n[i].available_logistic_robots,
					{ player.force.name, name, tostring(i) }
				)
				gauge_logistic_network_all_construction_robots:set(
					n[i].all_construction_robots,
					{ player.force.name, name, tostring(i) }
				)
				gauge_logistic_network_available_construction_robots:set(
					n[i].available_construction_robots,
					{ player.force.name, name, tostring(i) }
				)
				gauge_logistic_network_robot_limit:set(n[i].robot_limit, { player.force.name, name, tostring(i) })
				if n[i].get_contents() ~= nil then
					for item, l in pairs(n[i].get_contents()) do
						gauge_logistic_network_items:set(l, { player.force.name, name, tostring(i), item })
					end
				end
			end
		end

                gauge_research_queue:reset()
                local researched_queue = global.last_research and global.last_research["player.force.name"] or false
                if researched_queue then
                        gauge_research_queue:set(researched_queue.researched and 1 or 0, {player.force.name, researched_queue.name, researched_queue.level, -1})
                end
                
                -- Levels dont get matched properly so store and save
                local levels = {}
                for idx, tech in pairs(player.force.research_queue or {player.force.current_research}) do
                        levels[tech.name] = levels[tech.name] and levels[tech.name] + 1 or tech.level
                        gauge_research_queue:set(idx == 1 and player.force.research_progress or 0, {player.force.name, tech.name, levels[tech.name], idx})
                end
	end

	-- power tick handler
	on_power_tick(event)

	if server_save then
		game.write_file("graftorio2/game.prom", prometheus.collect(), false, 0)
	else
		game.write_file("graftorio2/game.prom", prometheus.collect(), false)
	end
end

function register_events_players(event)
	gauge_connected_player_count:set(#game.connected_players)
	gauge_total_player_count:set(#game.players)
end
