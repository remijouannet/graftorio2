function on_signals_load()
    --[[ global signal data example:
    global["signal-data"] = {
        metrics = {
            [metric_name_1] = {
                -- future metric data
            },
        },
        combinators = {
            [unit_number_1] = {
                entity = LuaEntity,
                ["metric-name"] = "metric_name_1"
                ["signal-filter"] = {
                    "type" = "virtual",
                    "name" = "signal-0",
                },
                group = "",
            },
            [unit_number_2] = {
                entity = LuaEntity,
                ["metric-name"] = "metric_name_1",
                ["signal-filter"] = nil, -- may be nil, may be missing
                group = "main base",
            }
            [unit_number_3] = {
                entity = LuaEntity,
                ["metric-name"] = nil, -- not configured yet, may be nil, may be missing
                ["signal-filter"] = nil, -- may be nil, may be missing
                group = "main base",
            }
        }
    }
    --]]
    if global["signal-data"] == nil then
        error("Could not find signal-data in global")
    end
end

function on_signals_init()
    -- global["signal-data"] is populated in migrations
end

function on_signals_tick(event)
    if not event.tick then
        return
    end
end

function get_signal_combinator_data(unit_number)
    return global["signal-data"]["combinators"][unit_number]
end

function set_signal_combinator_data(unit_number, table)
    global["signal-data"]["combinators"][unit_number] = table
    return table
end

function get_metric_data(metric_name)
    return global["signal-data"]["metrics"][metric_name]
end

function set_metric_data(metric_name, table)
    global["signal-data"]["metrics"][metric_name] = table
    return table
end

function new_custom_metric(options)
    if type(options) == "string" then
        return new_custom_metric{name = options}
    end
    if options.name then
        local existing = get_metric_data(options.name)
        if existing == nil then
            return set_metric_data(options.name, {})
        end
    end
end

function new_prometheus_combinator(entity)
    local stored_data = get_signal_combinator_data(entity.unit_number)
    if not stored_data then
        return set_signal_combinator_data(entity.unit_number, {
            entity = entity,
            ["metric-name"] = nil,
            ["signal-filter"] = nil,
            group = "",
        })
    elseif stored_data.entity == nil then
        stored_data.entity = entity
        return set_signal_combinator_data(entity.unit_number, stored_data)
    end
end
