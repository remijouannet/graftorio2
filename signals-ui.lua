require("signals")

local function validate_prometheus_combinator_gui_inputs(frame)
    local metric_name = frame["content"]["metric-name-flow"]["metric-name"].text
    local metric_name_valid = false
    if metric_name == "" or not metric_name then
        frame["content"]["metric-name-error"].caption = "Metric name must not be empty"
    else
        local metric_name_regex_match = string.match(metric_name, "^[a-zA-Z0-9_]+$")
        if metric_name_regex_match then
            metric_name_valid = true
            frame["content"]["metric-name-error"].caption = ""
        else
            frame["content"]["metric-name-error"].caption = "Invalid input. Only alphanumeric characters and underscores are allowed."
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

    local stored_data = get_signal_combinator_data(entity.unit_number)
    local stored_metric_name = ""
    local stored_entity = entity
    local stored_signal_filter = nil
    local stored_group = ""
    if stored_data ~= nil then
        stored_metric_name = stored_data["metric-name"] or ""
        stored_signal_filter = stored_data["signal-filter"]
        game.print("Stored signal filter "..(stored_signal_filter and stored_signal_filter.name or "nil"))
        stored_group = stored_data["group"] or ""
        stored_entity = stored_data["entity"] or entity
    end

    if stored_entity.unit_number ~= entity.unit_number then
        error("Unexpected unit_number for entity " .. tostring(entity.unit_number) .. ": " .. stored_entity.unit_number)
    end

    local frame = player.gui.screen.add { type = "frame", name = "prometheus-combinator-gui", direction = "vertical", caption = "Prometheus Combinator" }

    frame.add {
        type = "label",
        name = "unit-number",
        caption = tostring(entity.unit_number),
        visible = false,
    }

    local content_frame = frame.add { type = "frame", name = "content", direction = "vertical" }

    content_frame.add { type = "label", caption = "Configure metric" }
    local metric_name_container = content_frame.add { type = "flow", name = "metric-name-flow" }

    metric_name_container.add { type = "label", caption = "Metric name", name = "metric-name-caption", tooltip = "Actual metric name will be \"factorio_custom_{name}\"" }
    metric_name_container.add { type = "textfield", name = "metric-name", text = stored_metric_name }
    local metric_name_error = content_frame.add { type = "label", name = "metric-name-error", caption = "", style = "invalid_label" }

    metric_name_error.visible = metric_name_error.caption ~= ""

    local specific_signal_container = content_frame.add { type = "flow", name = "specific-signal-container", direction = "horizontal" }
    specific_signal_container.add { type = "label", caption = "Specific signal", tooltip = "If no filter is specified, ALL signals will be exported" }
    game.print("Applied signal filter "..(stored_signal_filter and stored_signal_filter.name or "nil"))
    local filter_button = specific_signal_container.add { type = "choose-elem-button", name = "specific-signal", elem_type = "signal" }

    filter_button.elem_value = stored_signal_filter

    local signal_group_container = content_frame.add { type = "flow", name = "group-container", direction = "horizontal" }
    signal_group_container.add { type = "label", name = "group-name-label", caption = "Group name" }
    local signal_group_textfield = signal_group_container.add { type = "textfield", name = "group-name", text = stored_group }

    signal_group_container.enabled = enable_signal_groups
    signal_group_textfield.enabled = enable_signal_groups
    -- only disable to retain group-information even when disabled
    if not enable_signal_groups then
        signal_group_textfield.tooltip = "Disabled in mod settings"
    end

    local apply_button_flow = content_frame.add { type = "flow", name = "apply-button-flow", direction = "horizontal" }
    apply_button_flow.add { type = "button", name = "cancel-button", caption = "Cancel", style = "red_button" }
    apply_button_flow.add { type = "button", name = "apply-button", caption = "Apply", style = "confirm_button", enabled = false }
    validate_prometheus_combinator_gui_inputs(frame)
    player.opened = frame
end

local function apply_prometheus_combinator_gui_inputs(frame, entity)
    local unit_number

    if entity ~= nil then
        unit_number = entity.unit_number
    else
        unit_number = tonumber(frame["unit-number"].caption)
    end

    local new_metric_name = frame["content"]["metric-name-flow"]["metric-name"].text
    local new_signal_filter = frame["content"]["specific-signal-container"]["specific-signal"].elem_value
    local new_group = frame["content"]["group-container"]["group-name"].text

    local signal_string = new_signal_filter and (new_signal_filter.type .. ":" .. new_signal_filter.name) or ""
    game.print("Applying settings to " .. unit_number .. ": name=" .. new_metric_name .. ", signal=" .. signal_string .. ", group=" .. new_group)
    local existing_combinator_table = get_signal_combinator_data(unit_number)
    if existing_combinator_table ~= nil then
        existing_combinator_table["metric-name"] = new_metric_name
        existing_combinator_table["signal-filter"] = new_signal_filter
        existing_combinator_table.group = new_group
        set_signal_combinator_data(unit_number, existing_combinator_table)
    else
        set_signal_combinator_data(unit_number, {
            ["metric-name"] = new_metric_name,
            ["signal-filter"] = new_signal_filter,
            group = new_group
        })
    end
    new_custom_metric(new_metric_name)
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
    if element.name == "all-signals-toggle" then
        local parent = element.parent
        parent["specific-signal-container"].visible = not element.state
        validate_prometheus_combinator_gui_inputs(frame)
    elseif element.name == "apply-button" then
        apply_prometheus_combinator_gui_inputs(frame)
        frame.destroy()
    elseif element.name == "cancel-button" then
        frame.destroy()
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
    validate_prometheus_combinator_gui_inputs(frame)
end

function on_signals_gui_text_changed(event)
    local frame = find_own_frame(event.element)
    if frame == nil then
        return
    end
    validate_prometheus_combinator_gui_inputs(frame)
end

function on_signals_gui_opened(event)
    if event.entity ~= nil and event.entity.name == "prometheus-combinator" then
        new_prometheus_combinator(event.entity)
        open_prometheus_combinator_gui(game.players[event.player_index], event.entity)
    end
end
