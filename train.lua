require("utils")

function train_buckets(bucket_settings)
	local train_buckets = {}
	for _, bucket in pairs(split(bucket_settings, ",")) do
		table.insert(train_buckets, tonumber(bucket))
	end
end

local train_trips = {}
local arrivals = {}
local watched_train = 0
local watched_station = ""
local function watch_train(event, msg)
	if event.train.id == watched_train then
		game.print(msg)
	end
end

local function watch_station(event, msg)
	if event.train.path_end_stop.backer_name == watched_station then
		game.print(msg)
	end
end

local function create_train(event)
	if event.train.path_end_stop == nil then
		return
	end

	-- {source station, tick it departed there, tick last begun waiting, total ticks spent waiting}
	train_trips[event.train.id] = { event.train.path_end_stop.backer_name, game.tick, 0, 0 }
	-- watch_train(event, "begin tracking " .. event.train.id)
end

local function create_station(event)
	if event.train.path_end_stop == nil then
		return
	end

	-- {last arrival tick}
	arrivals[event.train.path_end_stop.backer_name] = { 0 }
	-- watch_station(event, "created station " .. event.train.path_end_stop.backer_name)
end

local function reset_train(event)
	if event.train.path_end_stop == nil then
		return
	end

	train_trips[event.train.id] = { event.train.path_end_stop.backer_name, game.tick, 0, 0 }
end

local seen = {}
local function direct_loop(event, duration, labels)
	from = labels[1]
	to = labels[2]
	train_id = labels[3]

	if seen[train_id] == nil then
		seen[train_id] = {}
	end

	if seen[train_id][from] == nil then
		seen[train_id][from] = {}
	end

	if seen[train_id][from][to] then
		total = (game.tick - seen[train_id][from][to]) / 60

		sorted = { from, to }
		table.sort(sorted)

		-- watch_train(event, sorted[1] .. ":" .. sorted[2] .. " total " .. total)

		gauge_train_direct_loop_time:set(total, sorted)
		histogram_train_direct_loop_time:observe(total, sorted)
	end

	if seen[train_id][to] and seen[train_id][to][from] then
		-- watch_train(event, from .. ":" .. to .. " lap " .. (game.tick - seen[train_id][to][from]) / 60)
	end

	seen[train_id][from][to] = game.tick
end

local function track_arrival(event)
	if event.train.path_end_stop == nil then
		return
	end

	if arrivals[event.train.path_end_stop.backer_name] == nil then
		create_station(event)
	end

	-- watch_station(event, "arrived at " .. event.train.path_end_stop.backer_name)
	if arrivals[event.train.path_end_stop.backer_name][1] ~= 0 then
		lag = (game.tick - arrivals[event.train.path_end_stop.backer_name][1]) / 60
		labels = { event.train.path_end_stop.backer_name }

		gauge_train_arrival_time:set(lag, labels)
		histogram_train_arrival_time:observe(lag, labels)

		-- watch_station(event, "lag was " .. lag)
	end

	arrivals[event.train.path_end_stop.backer_name][1] = game.tick
end

function register_events_train(event)
	if event == nil or event.train == nil then
		return
	end

	if event.train.state == defines.train_state.arrive_station then
		track_arrival(event)
	end

	if train_trips[event.train.id] ~= nil then
		if event.train.state == defines.train_state.arrive_station then
			if event.train.path_end_stop == nil then
				return
			end

			if train_trips[event.train.id][1] == event.train.path_end_stop.backer_name then
				return
			end

			duration = (game.tick - train_trips[event.train.id][2]) / 60
			wait = train_trips[event.train.id][4] / 60

			-- watch_train(event, event.train.id .. ": " .. train_trips[event.train.id][1] .. "->" .. event.train.path_end_stop.backer_name .. " took " .. duration .. "s waited " .. wait .. "s")

			labels = { train_trips[event.train.id][1], event.train.path_end_stop.backer_name, event.train.id }

			gauge_train_trip_time:set(duration, labels)
			gauge_train_wait_time:set(wait, labels)
			histogram_train_trip_time:observe(duration, labels)
			histogram_train_wait_time:observe(wait, labels)
			direct_loop(event, duration, labels)

			reset_train(event)
		elseif
			event.train.state == defines.train_state.on_the_path
			and event.old_state == defines.train_state.wait_station
		then
			-- begin moving after waiting at a station
			train_trips[event.train.id][2] = game.tick
		-- watch_train(event, event.train.id .. " leaving for " .. event.train.path_end_stop.backer_name)
		elseif event.train.state == defines.train_state.wait_signal then
			-- waiting at a signal
			train_trips[event.train.id][3] = game.tick
		-- watch_train(event, event.train.id .. " waiting")
		elseif event.old_state == defines.train_state.wait_signal then
			-- begin moving after waiting at a signal
			train_trips[event.train.id][4] = train_trips[event.train.id][4]
				+ (game.tick - train_trips[event.train.id][3])
			-- watch_train(event, event.train.id .. " waited for " .. (game.tick - train_trips[event.train.id][3]) / 60)
			train_trips[event.train.id][3] = 0
		end
	end

	if train_trips[event.train.id] == nil and event.train.state == defines.train_state.arrive_station then
		create_train(event)
	end
end
