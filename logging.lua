local logging_groups = {
    global = 30,
    signals = 30,
}

local levels = {
    info = 30,
    debug = 20,
    verbose = 10,
    trace = 0
}

local function debug_log(text, logging_level, logging_group)
    if type(logging_level) == "string" then
        logging_level = levels[logging_level]
    elseif logging_level == nil then
        logging_level = levels.debug
    end
    if logging_group == nil then
        logging_group = "global"
    end
    local stored_level = logging_groups[logging_group]
    if stored_level == nil then
        stored_level = logging_groups.global
    end
    if logging_level >= stored_level then
        log(text)
    end
end

local function reload_settings()
    local settings_level = levels[settings.global["graftorio2-log-level"].value]
    if type(settings_level) ~= "number" then
        error("Unexpected settings_level: " .. tostring(settings_level) .. " (from " .. tostring(settings.global["graftorio2-log-level"].value) .. ")")
    end
    for k, v in pairs(logging_groups) do
        logging_groups[k] = settings_level
    end
end

return {
    debug_log = debug_log,
    logging_groups = logging_groups,
    levels = levels,
    reload_settings = reload_settings,
}
