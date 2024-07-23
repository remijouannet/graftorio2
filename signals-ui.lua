local logging = require("logging")
local signals = require("signals")

local function get_textfield_dropdown_content(element)
    if element.type == "textfield" then
        return element.text
    elseif element.type == "drop-down" then
        local items = element.items
        local selected_index = element.selected_index
        if selected_index < 1 or selected_index > #items then
            return nil
        else
            return items[selected_index]
        end
    else
        return nil
    end
end

local function deduplicate_values(data)
    local seen = {}
    local result = {}
    for _, v in ipairs(data) do
        if not seen[v] then
            seen[v] = true
            table.insert(results, v)
        end
    end
    return results
end

local function prioritize_text_match(options, text, filter)
    if filter == nil then
        filter = false
    end
    local default_group = {} -- flat table for all options without any match
    local match_groups = { {} } -- nested table where each sub table represents matches at its own index
    for _, v in pairs(options) do
        local index = tostring(v):find(text, 1, true)
        if index == nil then
            table.insert(default_group, v)
        else
            for i = 1 + #match_groups, index do
                match_groups[i] = {}
            end
            table.insert(match_groups[index], v)
        end
    end
    local results = {}
    for i, match_group in ipairs(match_groups) do
        for _, v in ipairs(match_group) do
            table.insert(results, v)
        end
    end
    if filter then
        return results, default_group
    else
        for _, v in ipairs(default_group) do
            table.insert(results, v)
        end
        return results
    end
end

local function find_index_of(data, value)
    for k, v in pairs(data) do
        if v == value then
            return k
        end
    end
    return nil
end

local function toggle_textfield_dropdown(element, options, autocomplete)
    if not element.valid then
        return
    end
    local content
    local enabled = element.enabled
    local index = element.get_index_in_parent()
    local name = element.name
    local parent = element.parent
    local tooltip = element.tooltip
    if element.type == "textfield" then
        content = element.text
        element.destroy()

        local dropdown_options, selected_index

        if autocomplete then

            dropdown_options = prioritize_text_match(options, content)
            if dropdown_options[1] ~= content then
                -- if content exists in options, prioritize_text_match will put it in front
                table.insert(dropdown_options, 1, content)
            end
            selected_index = 1
        else
            dropdown_options = options
            selected_index = find_index_of(options, content)
        end

        parent.add {
            type = "drop-down",
            enabled = enabled,
            index = index,
            name = name,
            tooltip = tooltip,
            items = dropdown_options,
            selected_index = selected_index
        }
    elseif element.type == "drop-down" then
        content = ""
        local items = element.items
        local selected_index = element.selected_index
        if selected_index > 0 and selected_index <= #items then
            content = items[selected_index]
        end
        element.destroy()
        parent.add {
            type = "textfield",
            enabled = enabled,
            index = index,
            name = name,
            tooltip = tooltip,
            text = content,
        }
    else
        return
    end
end

local function update_prometheus_combinator_gui(frame)
    local metric_name_element = frame["content"]["metric-name-flow"]["metric-name"]
    local metric_name = get_textfield_dropdown_content(metric_name_element)
    if metric_name == nil then
        metric_name = ""
    end
    local metric_name_valid = false

    if metric_name == "" or not metric_name then
        frame["content"]["metric-name-error"].caption = { "graftorio2-signals-gui.error-configuration-metric-name-empty" }
    else
        local metric_name_regex_match = string.match(metric_name, "^[a-zA-Z0-9_]+$")
        if metric_name_regex_match then
            metric_name_valid = true
            frame["content"]["metric-name-error"].caption = ""
        else
            frame["content"]["metric-name-error"].caption = { "graftorio2-signals-gui.error-configuration-metric-name-invalid" }
        end
    end
    frame["content"]["metric-name-error"].visible = not metric_name_valid

    frame["content"]["apply-button-flow"]["apply-button"].enabled = metric_name_valid
    return metric_name_valid
end

local function open_prometheus_combinator_gui(player, entity)
    if player.gui.screen["prometheus-combinator-gui"] then
        player.gui.screen["prometheus-combinator-gui"].destroy()
    end

    local stored_data = signals.get_signal_combinator_data(entity.unit_number)
    local stored_metric_name = ""
    local stored_entity = entity
    local stored_signal_filter = nil
    local stored_group = ""
    if stored_data ~= nil then
        stored_metric_name = stored_data["metric-name"] or ""
        stored_signal_filter = stored_data["signal-filter"]
        stored_group = stored_data["group"] or ""
        stored_entity = stored_data["entity"] or entity
    end

    if stored_entity.unit_number ~= entity.unit_number then
        error("Unexpected unit_number for entity " .. tostring(entity.unit_number) .. ": " .. stored_entity.unit_number)
    end

    local frame = player.gui.screen.add { type = "frame", name = "prometheus-combinator-gui", direction = "vertical", caption = { "graftorio2-signals-gui.configuration-title" } }

    frame.add {
        type = "label",
        name = "unit-number",
        caption = tostring(entity.unit_number),
        visible = false,
    }

    local content_frame = frame.add { type = "frame", name = "content", direction = "vertical" }

    content_frame.add { type = "label", caption = { "graftorio2-signals-gui.configuration-content-caption" } }
    local metric_name_container = content_frame.add { type = "flow", name = "metric-name-flow" }

    metric_name_container.add { type = "label", caption = { "graftorio2-signals-gui.configuration-metric-name-caption" }, name = "metric-name-caption", tooltip = { "graftorio2-signals-gui.configuration-metric-name-prefix-note" } }
    metric_name_container.add { type = "textfield", name = "metric-name", text = stored_metric_name, tooltip = { "graftorio2-signals-gui.configuration-metric-name-toggle-type" } }
    local metric_name_error = content_frame.add { type = "label", name = "metric-name-error", caption = "", style = "invalid_label" }

    metric_name_error.visible = metric_name_error.caption ~= ""

    local specific_signal_container = content_frame.add { type = "flow", name = "specific-signal-container", direction = "horizontal" }
    specific_signal_container.add { type = "label", caption = "Specific signal", tooltip = { "graftorio2-signals-gui.configuration-signal-empty-all-exported" } }
    local filter_button = specific_signal_container.add { type = "choose-elem-button", name = "specific-signal", elem_type = "signal" }

    filter_button.elem_value = stored_signal_filter

    local signal_group_container = content_frame.add { type = "flow", name = "group-container", direction = "horizontal" }
    signal_group_container.add { type = "label", name = "group-name-label", caption = { "graftorio2-signals-gui.configuration-group-name-caption" } }
    local signal_group_textfield = signal_group_container.add { type = "textfield", name = "group-name", text = stored_group, tooltip = "Right-click to toggle between free input and drop-down" }

    signal_group_container.enabled = enable_signal_groups
    signal_group_textfield.enabled = enable_signal_groups
    -- only disable to retain group-information even when disabled
    if not enable_signal_groups then
        signal_group_textfield.tooltip = { "graftorio2-signals-gui.configuration-group-setting-disabled" }
    end

    local apply_button_flow = content_frame.add { type = "flow", name = "apply-button-flow", direction = "horizontal" }
    apply_button_flow.add { type = "button", name = "cancel-button", caption = { "?", { "graftorio2-signals-gui.configuration-cancel" }, { "gui.close" }, "Cancel" }, style = "red_button" }
    apply_button_flow.add { type = "button", name = "apply-button", caption = { "?", { "graftorio2-signals-gui.configuration-apply" }, { "gui.save" }, "Apply" }, style = "confirm_button", enabled = false }
    update_prometheus_combinator_gui(frame)
    frame.force_auto_center()
    player.opened = frame
end

local function apply_prometheus_combinator_gui_inputs(frame, entity)
    local unit_number

    if entity ~= nil then
        unit_number = entity.unit_number
    else
        unit_number = tonumber(frame["unit-number"].caption)
    end

    local metric_name_element = frame["content"]["metric-name-flow"]["metric-name"]
    local new_metric_name = get_textfield_dropdown_content(metric_name_element)
    if new_metric_name == nil then
        logging.debug_log("Could not read metric name of type (\"" .. metric_name_element.type .. "\"), aborting combinator saving", logging.levels.info, "signals")
        return
    elseif new_metric_name == "" then
        logging.debug_log("Read metric name of type (\"" .. metric_name_element.type .. "\"), aborting combinator saving", logging.levels.info, "signals")
        return
    end
    local new_signal_filter = frame["content"]["specific-signal-container"]["specific-signal"].elem_value
    local group_name_element = frame["content"]["group-container"]["group-name"]
    local new_group = get_textfield_dropdown_content(group_name_element)
    if new_group == nil then
        logging.debug_log("Could not read group name of type (\"" .. group_name_element.type .. "\"), aborting combinator saving", logging.levels.info, "signals")
        return
    end

    local signal_string = new_signal_filter and (new_signal_filter.type .. ":" .. new_signal_filter.name) or ""
    logging.debug_log("Applying settings to " .. unit_number .. ": name=" .. new_metric_name .. ", signal=" .. signal_string .. ", group=" .. new_group, logging.levels.debug, "signals")
    local existing_combinator_table = signals.get_signal_combinator_data(unit_number)
    if existing_combinator_table ~= nil then
        existing_combinator_table["metric-name"] = new_metric_name
        existing_combinator_table["signal-filter"] = new_signal_filter
        existing_combinator_table.group = new_group
        signals.set_signal_combinator_data(unit_number, existing_combinator_table)
    else
        signals.set_signal_combinator_data(unit_number, {
            ["metric-name"] = new_metric_name,
            ["signal-filter"] = new_signal_filter,
            group = new_group
        })
    end
    signals.new_custom_metric(new_metric_name)
end

local function find_own_frame(element)
    if element.name == "prometheus-combinator-gui" then
        return element
    elseif element.parent ~= nil then
        if element.parent.name == "prometheus-combinator-gui" then
            return element.parent
        elseif element.parent.parent ~= nil then
            if element.parent.parent.name == "prometheus-combinator-gui" then
                return element.parent.parent
            elseif element.parent.parent.parent ~= nil then
                if element.parent.parent.parent.name == "prometheus-combinator-gui" then
                    return element.parent.parent.parent
                else
                    return
                end
            end
        end
    end
end

function on_signals_gui_click(event)
    local element = event.element
    local frame = find_own_frame(element)
    if frame == nil then
        return
    end
    if element.name == "apply-button" then
        apply_prometheus_combinator_gui_inputs(frame)
        frame.destroy()
    elseif element.name == "cancel-button" then
        frame.destroy()
    elseif element.name == "metric-name" then
        if event.button == defines.mouse_button_type.right then
            local metric_names = signals.get_metric_names()
            table.sort(metric_names)
            toggle_textfield_dropdown(element, metric_names, true)
            update_prometheus_combinator_gui(frame)
        end
    elseif element.name == "group-name" then
        if event.button == defines.mouse_button_type.right then
            local group_names = signals.get_group_names()
            table.sort(group_names)
            if group_names[1] ~= "" then
                table.insert(group_names, 1, "")
            end
            toggle_textfield_dropdown(element, group_names, true)
            update_prometheus_combinator_gui(frame)
        end
    end
end

function on_signals_gui_selection_state_changed(event)
    local frame = find_own_frame(event.element)
    if frame ~= nil then
        update_prometheus_combinator_gui(frame)
    end
end

function on_signals_gui_closed(event)
    local element = event.element
    if element ~= nil and element.valid and element.name == "prometheus-combinator-gui" then
        element.destroy()
    end
end

function on_signals_gui_confirmed(event)
    local frame = find_own_frame(event.element)
    if frame == nil then
        return
    end
    update_prometheus_combinator_gui(frame)
end

function on_signals_gui_text_changed(event)
    local frame = find_own_frame(event.element)
    if frame == nil then
        return
    end
    update_prometheus_combinator_gui(frame)
end

function on_signals_gui_opened(event)
    if event.entity ~= nil and event.entity.name == "prometheus-combinator" then
        signals.new_prometheus_combinator(event.entity)
        open_prometheus_combinator_gui(game.players[event.player_index], event.entity)
    end
end
