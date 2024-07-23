local signals = require("signals")

local function sorted_pairs(data)
    local sorted_keys = {}
    for key in pairs(data) do
        table.insert(sorted_keys, key)
    end
    table.sort(sorted_keys)
    local index = 0
    local function iterator()
        index = index + 1
        local key = sorted_keys[index]
        if key == nil then
            return nil
        else
            return key, data[key]
        end
    end
    return iterator
end

local function fill_active_metrics_container(container, loaded_metrics_table)
    for metric_name, metric_table in sorted_pairs(loaded_metrics_table) do
        local metric_frame = container.add { type = "frame", name = "metric-" .. metric_name, direction = "vertical", caption = { "?", { "graftorio2-signals-debug-gui.debug-metric-caption", metric_name }, metric_name } }

        local metric_properties_group = metric_frame.add { type = "flow", name = "properties-group", direction = "horizontal" }
        metric_properties_group.add { type = "label", "properties-label", caption = { "graftorio2-signals-debug-gui.debug-metric-properties-caption" } }
        local metric_properties_text = metric_properties_group.add { type = "text-box", "properties-text", text = serpent.block(metric_table.properties) }
        metric_properties_text.read_only = true

        local metric_prometheus_present_group = metric_frame.add { type = "flow", name = "prometheus-present-group", direction = "horizontal" }
        metric_prometheus_present_group.add { type = "label", "prometheus-present-label", caption = { "graftorio2-signals-debug-gui.debug-metric-prometheus-present" } }
        local metric_prometheus_present_content = metric_prometheus_present_group.add { type = "label", "prometheus-present-content" }
        if metric_table["prometheus-metric"] ~= nil then
            metric_prometheus_present_content.caption = { "?", { "graftorio2-signals-debug-gui.debug-metric-prometheus-present-true" }, { "gui.yes" }, "true" }
        else
            metric_prometheus_present_content.caption = { "?", { "graftorio2-signals-debug-gui.debug-metric-prometheus-present-false" }, { "gui.no" }, "true" }
        end

        local metric_groups_container = metric_frame.add { type = "flow", name = "groups", direction = "vertical", caption = { "graftorio2-signals-debug-gui.debug-groups-general-caption" } }
        metric_groups_container.visible = false
        for group_name, group_table in sorted_pairs(metric_table.groups) do
            metric_groups_container.visible = true
            local group_container = metric_groups_container.add { type = "frame", name = "group-" .. group_name, caption = { "?", { "graftorio2-signals-debug-gui.debug-groups-specific-caption", group_name } }, direction = "vertical" }
            for unit_number, combinator_table in sorted_pairs(group_table) do
                local combinator_container = group_container.add { type = "frame", name = "combinator-" .. tostring(unit_number), direction = "horizontal" }

                local entity_container = combinator_container.add { type = "flow", name = "entity-container", direction = "horizontal" }
                entity_container.add { type = "label", caption = { "graftorio2-signals-debug-gui.debug-combinator-entity-caption" } }
                local entity_number_label = entity_container.add { type = "label", name = "entity-number" }
                local entity_match_label = entity_container.add { type = "label", name = "entity-match-label" }
                if combinator_table.entity == nil then
                    entity_number_label.caption = { "?", { "graftorio2-signals-debug-gui.debug-combinator-entity-nil" }, "nil" }
                    entity_number_label.style = "bold_red_label"
                    entity_match_label.visible = false
                elseif not combinator_table.entity.valid then
                    entity_number_label.caption = { "?", { "graftorio2-signals-debug-gui.debug-combinator-entity-invalid" }, "invalid" }
                    entity_number_label.style = "bold_red_label"
                    entity_match_label.visible = false
                else
                    entity_number_label.caption = { "?", { "graftorio2-signals-debug-gui.debug-combinator-entity-number", combinator_table.entity.unit_number }, tostring(combinator_table.entity.unit_number) }
                    entity_number_label.style = "bold_label"
                    if combinator_table.entity.unit_number ~= unit_number then
                        entity_match_label.caption = { "?", { "graftorio2-signals-debug-gui.debug-combinator-entity-mismatch", unit_number }, "~= " .. tostring(unit_number) }
                        entity_match_label.style = "bold_red_label"
                        entity_number_label.style = "bold_red_label"
                    else
                        entity_match_label.visible = false
                    end
                end

                local entry_path = { "?", { "graftorio2-signals-debug-gui.debug-combinator-path-text", combinator_table["metric-name"], combinator_table.group, entity_number_label.caption }, tostring(combinator_table["metric-name"]) .. "/" .. tostring(combinator_table.group) .. "/" .. tostring(entity_number_label.caption) }
                local entry_path_container = combinator_container.add { type = "flow", name = "entry-path-container", direction = "horizontal" }
                entry_path_container.add { type = "label", name = "entry-path-label", caption = { "graftorio2-signals-debug-gui.debug-combinator-path-caption" } }
                entry_path_container.add { type = "label", name = "entry-path-content", caption = entry_path }

                local filter_container = combinator_container.add { type = "flow", name = "filter-container", direction = "horizontal" }
                filter_container.add { type = "label", name = "filter-container-label", caption = { "graftorio2-signals-debug-gui.debug-combinator-filter-caption" } }
                local filter_elem_button = filter_container.add { type = "choose-elem-button", elem_type = "signal" }
                if combinator_table["signal-filter"] ~= nil then
                    filter_elem_button.elem_value = combinator_table["signal-filter"]
                end
                filter_elem_button.enabled = false
            end
        end
    end
end

local function fill_global_metrics_container(container, global_metrics_table)
    for metric_name, metric_table in sorted_pairs(global_metrics_table) do
        local metric_frame = container.add { type = "frame", name = "metric-" .. metric_name, direction = "vertical", caption = { "?", { "graftorio2-signals-debug-gui.debug-metric-caption", metric_name }, metric_name } }

        local metric_properties_group = metric_frame.add { type = "flow", name = "properties-group", direction = "horizontal" }
        metric_properties_group.add { type = "label", "properties-label", caption = { "graftorio2-signals-debug-gui.debug-metric-properties-caption" } }
        local metric_properties_text = metric_properties_group.add { type = "text-box", "properties-text", text = serpent.block(metric_table) }
        metric_properties_text.read_only = true
    end
end

local function fill_global_combinators_container(container, global_combinators_table)
    for unit_number, combinator_table in sorted_pairs(global_combinators_table) do
        local combinator_container = container.add { type = "frame", name = "combinator-" .. tostring(unit_number), direction = "horizontal" }

        local entity_container = combinator_container.add { type = "flow", name = "entity-container", direction = "horizontal" }
        entity_container.add { type = "label", caption = { "graftorio2-signals-debug-gui.debug-combinator-entity-caption" } }
        local entity_number_label = entity_container.add { type = "label", name = "entity-number" }
        local entity_match_label = entity_container.add { type = "label", name = "entity-match-label" }
        if combinator_table.entity == nil then
            entity_number_label.caption = { "?", { "graftorio2-signals-debug-gui.debug-combinator-entity-nil" }, "nil" }
            entity_number_label.style = "bold_red_label"
            entity_match_label.visible = false
        elseif not combinator_table.entity.valid then
            entity_number_label.caption = { "?", { "graftorio2-signals-debug-gui.debug-combinator-entity-invalid" }, "invalid" }
            entity_number_label.style = "bold_red_label"
            entity_match_label.visible = false
        else
            entity_number_label.caption = { "?", { "graftorio2-signals-debug-gui.debug-combinator-entity-number", combinator_table.entity.unit_number }, tostring(combinator_table.entity.unit_number) }
            entity_number_label.style = "bold_label"
            if combinator_table.entity.unit_number ~= unit_number then
                entity_match_label.caption = { "?", { "graftorio2-signals-debug-gui.debug-combinator-entity-mismatch", unit_number }, "~= " .. tostring(unit_number) }
                entity_match_label.style = "bold_red_label"
                entity_number_label.style = "bold_red_label"
            else
                entity_match_label.visible = false
            end
        end

        local entry_path = { "?", { "graftorio2-signals-debug-gui.debug-combinator-path-text", combinator_table["metric-name"], combinator_table.group, entity_number_label.caption }, tostring(combinator_table["metric-name"]) .. "/" .. tostring(combinator_table.group) .. "/" .. tostring(entity_number_label.caption) }
        local entry_path_container = combinator_container.add { type = "flow", name = "entry-path-container", direction = "horizontal" }
        entry_path_container.add { type = "label", name = "entry-path-label", caption = { "graftorio2-signals-debug-gui.debug-combinator-path-caption" } }
        entry_path_container.add { type = "label", name = "entry-path-content", caption = entry_path }

        local filter_container = combinator_container.add { type = "flow", name = "filter-container", direction = "horizontal" }
        filter_container.add { type = "label", name = "filter-container-label", caption = { "graftorio2-signals-debug-gui.debug-combinator-filter-caption" } }
        local filter_elem_button = filter_container.add { type = "choose-elem-button", elem_type = "signal" }
        if combinator_table["signal-filter"] ~= nil then
            filter_elem_button.elem_value = combinator_table["signal-filter"]
        end
        filter_elem_button.enabled = false
    end
end

local function open_prometheus_combinator_debug_gui(player)
    if player.gui.screen["prometheus-combinator-debug-gui"] then
        player.gui.screen["prometheus-combinator-debug-gui"].destroy()
    end

    local super_frame = player.gui.screen.add { type = "frame", name = "prometheus-combinator-debug-gui", caption = { "graftorio2-signals-debug-gui.debug-caption" } }

    local main = super_frame.add { type = "tabbed-pane" }

    local active_metrics_tab = main.add { type = "tab", name = "active-metrics-tab", caption = {"graftorio2-signals-debug-gui.debug-tab-active-metrics"} }
    local active_metrics_frame = main.add { type = "frame", name = "active-metrics-frame", direction = "vertical" }
    main.add_tab(active_metrics_tab, active_metrics_frame)
    local active_metrics_content_list_frame = active_metrics_frame.add { type = "frame", name = "active-metrics-content-list-frame", direction = "vertical" }
    local active_metrics_scroll = active_metrics_content_list_frame.add { type = "scroll-pane", name = "active-metrics-scroll", horizontal_scroll_policy = "auto", vertical_scroll_policy = "always" }
    fill_active_metrics_container(active_metrics_scroll, signals.signal_metrics)

    local global_metrics_tab = main.add { type = "tab", name = "global-metrics-tab", caption = {"graftorio2-signals-debug-gui.debug-tab-global-metrics"} }
    local global_metrics_frame = main.add { type = "frame", name = "global-metrics-frame", direction = "vertical" }
    main.add_tab(global_metrics_tab, global_metrics_frame)
    local global_metrics_content_list_frame = global_metrics_frame.add { type = "frame", name = "global-metrics-content-list-frame", direction = "vertical" }
    local global_metrics_scroll = global_metrics_content_list_frame.add { type = "scroll-pane", name = "global-metrics-scroll", horizontal_scroll_policy = "auto", vertical_scroll_policy = "always" }
    fill_global_metrics_container(global_metrics_scroll, global["signal-data"].metrics)

    local global_combinators_tab = main.add { type = "tab", name = "global-combinators-tab", caption = {"graftorio2-signals-debug-gui.debug-tab-global-combinators"} }
    local global_combinators_frame = main.add { type = "frame", name = "global-combinators-frame", direction = "vertical" }
    main.add_tab(global_combinators_tab, global_combinators_frame)
    local global_combinators_content_list_frame = global_combinators_frame.add { type = "frame", name = "global-combinators-content-list-frame", direction = "vertical" }
    local global_combinators_scroll = global_combinators_content_list_frame.add { type = "scroll-pane", name = "global-combinators-scroll", horizontal_scroll_policy = "auto", vertical_scroll_policy = "always" }
    fill_global_combinators_container(global_combinators_scroll, global["signal-data"].combinators)

    super_frame.force_auto_center()
    player.opened = super_frame
end

function on_signals_debug_gui_closed(event)
    local element = event.element
    if element ~= nil and element.valid and element.name == "prometheus-combinator-debug-gui" then
        element.destroy()
    end
end

function on_signals_debug_ui_command(command)
    local print_target = print
    if command.player_index ~= nil and (command.parameter == "" or command.parameter == nil or command.parameter == "gui") then
        open_prometheus_combinator_debug_gui(game.players[command.player_index])
    else
        if command.player_index ~= nil then
            print_target = game.players[command.player_index].print
        end
        if command.parameter == nil or command.parameter == "" or command.parameter == "loaded-metrics" or command.parameter == "loaded" then
            print_target("----Loaded Metrics----")
            print_target(serpent.block(signals.signal_metrics))
        end
        if command.parameter == nil or command.parameter == "" or command.parameter == "global-metrics" or command.parameter == "global" then
            print_target("----Global Metrics----")
            print_target(serpent.block(global["signal-data"].metrics))
        end
        if command.parameter == nil or command.parameter == "" or command.parameter == "global-combinators" or command.parameter == "global" then
            print_target("----Global Combinators----")
            print_target(serpent.block(global["signal-data"].combinators))
        end
    end
end

function add_signals_debug_ui_command()
    commands.add_command("graftorio2_signal_debug", "graftorio2_signal_debug [gui|loaded|global|loaded-metrics|global-metrics|global-combinators]", on_signals_debug_ui_command)
end
