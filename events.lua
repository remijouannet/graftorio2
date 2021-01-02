function register_events(event)
    gauge_tick:set(game.tick)
    gauge_connected_player_count:set(#game.connected_players)
    gauge_total_player_count:set(#game.players)

    for _, player in pairs(game.players) do
      stats = {
        {player.force.item_production_statistics, gauge_item_production_input, gauge_item_production_output},
        {player.force.fluid_production_statistics, gauge_fluid_production_input, gauge_fluid_production_output},
        {player.force.kill_count_statistics, gauge_kill_count_input, gauge_kill_count_output},
        {player.force.entity_build_count_statistics, gauge_entity_build_count_input, gauge_entity_build_count_output},
      }

      for _, stat in pairs(stats) do
        for name, n in pairs(stat[1].input_counts) do
          stat[2]:set(n, {player.force.name, name})
        end

        for name, n in pairs(stat[1].output_counts) do
          stat[3]:set(n, {player.force.name, name})
        end
      end

      for name, n in pairs(player.force.items_launched) do
        gauge_items_launched:set(n, {player.force.name, name})
      end
    end

    game.write_file("graftorio2/game.prom", prometheus.collect(), false)
end
