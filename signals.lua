local prometheus = require("prometheus/prometheus")

function on_signals_init()
    -- global["signal-data"] is populated in migrations
end

local logs = {}

local function debug_print(text)
    if game then
        while #logs > 0 do
            game.print(table.remove(logs,1))
        end
        game.print(text)
    else
        table.insert(logs, text)
    end
end

local function dump_logs()
    while logs do
        game.print(table.remove(logs,1))
    end
end

local signal_metrics = {}
--[[ example
    signal_metrics = {
        [metric_name_1] = {
            properties = {}, -- reference to properties in global["signal-data"].metrics[metric_name_1], if present
            ["prometheus-metric"] = ..., -- Result of prometheus.gauge
            groups = {
                [group] = {
                    -- only combinators matching this metric and group, otherwise same as global["signal-data"].combinators
                    [unit_number_1] = {
                        entity = LuaEntity,
                        ["metric-name"] = "metric_name_1",
                        ["signal-filter"] = {
                            type = "virtual",
                            name = "signal-0",
                        },
                        group = "",
                    }
                }
            }
        }
    }
]]--


local shared_signal_metric_labels = { "group", "signal" }

local function load_metric(metric_name, metric_table)
    local previous_data = signal_metrics[metric_name]
    if previous_data ~= nil then
        if metric_table ~= nil then
            previous_data.properties = metric_table
        end
        debug_print("Loaded new metric \""..metric_name.."\"")
        return previous_data
    else
        if metric_table == nil then
            metric_table = {}
        end
        local new_data = {
            properties = metric_table,
            groups = {},
            ["prometheus-metric"] = prometheus.gauge("factorio_custom_" .. metric_name, "Custom signal metric", shared_signal_metric_labels)
        }
        signal_metrics[metric_name] = new_data
        debug_print("Loaded into existing metric \""..metric_name.."\"")
        return new_data
    end
end

local function load_combinator(combinator_unit_number, combinator_table)
    local combinator_metric_name = combinator_table["metric-name"]
    if combinator_metric_name then
        local loaded_metric = load_metric(combinator_metric_name)
        local group = enable_signal_groups and combinator_table.group or ""
        local matching_group = loaded_metric.groups[group]
        if matching_group == nil then
            debug_print("No matching group, creating new")
            matching_group = {}
            loaded_metric[group] = matching_group
        end
        matching_group[combinator_unit_number] = combinator_table
        debug_print("Added combinator "..tostring(combinator_unit_number).." to group \""..group.."\"")
    end
    debug_print("Loaded combinator "..tostring(combinator_unit_number).." from global")
end

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
                    type = "virtual",
                    name = "signal-0",
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
    for metric_name, metric_table in pairs(global["signal-data"].metrics) do
        load_metric(metric_name, metric_table)
    end
    for combinator_unit_number, combinator_table in pairs(global["signal-data"].combinators) do
        load_combinator(combinator_unit_number, combinator_table)
    end
end

function on_signals_tick(event)
    if not event.tick then
        return
    end
    debug_print("Starting signal processing")
    for metric_name, metric_table in pairs(signal_metrics) do
        local prometheus_metric = metric_table["prometheus-metric"]
        prometheus_metric:reset()
        debug_print("Starting metric processing: \""..metric_name.."\"")
        for group, group_table in pairs(metric_table.groups) do
            debug_print("Starting group processing: \""..metric.group.."\"")
            for combinator_unit_number, combinator_table in pairs(group_table) do
                debug_print("Starting combinator processing: "..tostring(combinator_unit_number))
                local combinator_entity = combinator_table.entity
                if combinator_entity then
                    debug_print("Entity present")
                    local signal_filter = combinator_table["signal-filter"]
                    if signal_filter ~= nil then
                        debug_print("Single filter")
                        local value = combinator_entity.get_merged_signal(signal_filter)
                        debug_print("Inc["..signal.type..":"..signal.name.."] by "..tostring(value))
                        prometheus_metric.inc(value, { group, signal_filter.type .. ":" .. signal_filter.name })
                    else
                        debug_print("No filter")
                        local values = combinator_entity.get_merged_signals()
                        if values ~= nil then
                            for _, entry in ipairs(values) do
                                local signal = entry.signal
                                local value = entry.count
                                debug_print("Inc["..signal.type..":"..signal.name.."] by "..tostring(value))
                                prometheus_metric.inc(value, { group, signal.type .. ":" .. signal.name })
                            end
                        end
                    end
                end
            end
        end
    end
    debug_print("Done")
end

function get_signal_combinator_data(unit_number)
    return global["signal-data"]["combinators"][unit_number]
end

function set_signal_combinator_entity(entity)
    local previous_global_data = global["signal-data"]["combinators"][entity.unit_number]
    if not previous_global_data then
        local new_data = {
            entity = entity,
            ["metric-name"] = nil,
            ["signal-filter"] = nil,
            group = "",
        }
        global["signal-data"]["combinators"][entity.unit_number] = new_data
        load_combinator(entity.unit_number, new_data)
    else
        previous_global_data.entity = entity
        load_combinator(entity.unit_number, previous_global_data)
    end
end

local function unload_metric_if_empty(metric_name)
    local loaded_metric = signal_metrics[metric_name]
    if loaded_metric and not loaded_metric.groups then
        local prometheus_metric = loaded_metric["prometheus-metric"]
        if prometheus_metric ~= nil then
            prometheus.unregister(prometheus_metric)
            loaded_metric["prometheus-metric"] = nil
        end
        table.remove(signal_metrics, metric_name)
    end
end

function set_signal_combinator_data(unit_number, data)
    local previous_global_data = global["signal-data"]["combinators"][unit_number]
    local copy = table.deepcopy(data)
    global["signal-data"]["combinators"][unit_number] = copy
    if previous_global_data then
        local previous_metric_name = previous_global_data.metric_name
        local previous_group = previous_global_data.group
        if previous_metric_name then
            if (previous_metric_name ~= data.metric_name) or (previous_group ~= data.group and previous_group ~= nil) then
                local old_signal_metric_data = signal_metrics[previous_metric_name]
                if old_signal_metric_data then
                    local old_signal_group_data = old_signal_metric_data.groups
                    if old_signal_group_data[previous_group] then
                        table.remove(old_signal_group_data, previous_group)
                        unload_metric_if_empty(previous_metric_name)
                    end
                end
            end
        end
    end
    load_combinator(unit_number, copy)
end

function get_metric_data(metric_name)
    local stored = global["signal-data"]["metrics"][metric_name]
    return stored and table.deepcopy(stored)
end

function set_metric_data(metric_name, data)
    local copy = table.deepcopy(data)
    global["signal-data"]["metrics"][metric_name] = copy
    load_metric(metric_name, copy)
end

function new_custom_metric(options)
    if type(options) == "string" then
        return new_custom_metric { name = options }
    end
    if options.name then
        local existing = get_metric_data(options.name)
        if existing == nil then
            set_metric_data(options.name, {})
        end
    end
end

function new_prometheus_combinator(entity)
    local stored_data = get_signal_combinator_data(entity.unit_number)
    if not stored_data then
        set_signal_combinator_data(entity.unit_number, {
            entity = entity,
            ["metric-name"] = nil,
            ["signal-filter"] = nil,
            group = "",
        })
    elseif stored_data.entity == nil then
        set_signal_combinator_entity(entity)
    end
end
