local data = {
	inited = false,
	combinators = {},
}

local function rescan()
	data.combinators = {}
	for _, player in pairs(game.players) do
		for _, surface in pairs(game.surfaces) do
			for _, combinator in
				pairs(surface.find_entities_filtered({
					force = player.force,
					type = "constant-combinator",
				}))
			do
				data.combinators[combinator.unit_number] = combinator
			end
		end
	end
	data.inited = true
end

function on_circuit_network_build(event)
	local entity = event.entity
	if entity and entity.name == "constant-combinator" then
		data.inited = false
	end
end

function on_circuit_network_destroy(event)
	local entity = event.entity
	if entity.name == "constant-combinator" then
		data.inited = false
	end
end

function on_circuit_network_init()
	data.inited = false
end

function on_circuit_network_load()
	data.inited = false
end

function on_circuit_network_tick(event)
	if event.tick then
		if not data.inited then
			rescan()
		end

		gauge_circuit_network_monitored:reset()
		gauge_circuit_network_signal:reset()
		local seen = {}
		for _, combinator in pairs(data.combinators) do
			for _, wire_type in pairs({ defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green }) do
				local network = combinator.get_circuit_network(wire_type)
				if network ~= nil and seen[network.network_id] == nil and network.signals ~= nil then
					seen[network.network_id] = true
					local network_id = tostring(network.network_id)
					gauge_circuit_network_monitored:set(
						1,
						{ combinator.force.name, combinator.surface.name, network_id }
					)
					for _, signal in ipairs(network.signals) do
						gauge_circuit_network_signal:set(signal.count, {
							combinator.force.name,
							combinator.surface.name,
							network_id,
							signal.signal.name,
							signal.signal.quality,
						})
					end
				end
			end
		end
	end
end
