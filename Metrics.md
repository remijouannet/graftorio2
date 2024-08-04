# Exported metrics

Many metrics are only added to the export list when their respective value first changes - you will not see train stats
before you have placed your first train. This resets after each server restart, so if no trains have moved since the
restart, no statistics for them will show up either.

Please read the warning regarding the cardinality of train metrics!

### General

| Name            | Labels           | Description                                                  |
|-----------------|------------------|--------------------------------------------------------------|
| `factorio_tick` |                  | Most recent game tick, divide by 60 for game time in seconds |
| `factorio_seed` | surface          | The seed for the given surface                               |
| `factorio_mods` | name<br/>version | 1 for each mod at its currently installed version            |

### Players

| Name                              | Labels | Description                                  |
|-----------------------------------|--------|----------------------------------------------|
| `factorio_connected_player_count` |        | Count of currently connected players         |
| `factorio_total_player_count`     |        | Count of all players who were ever connected |

### Production

#### Items

| Name                              | Labels         | Description                                                          |
|-----------------------------------|----------------|----------------------------------------------------------------------|
| `factorio_item_production_input`  | force<br/>name | How many of each item have been produced in total by each force      |
| `factorio_item_production_output` | force<br/>name | How many of each item have been used/consumed in total by each force |

#### Fluids

| Name                               | Labels         | Description                                                          |
|------------------------------------|----------------|----------------------------------------------------------------------|
| `factorio_fluid_production_input`  | force<br/>name | How much of each fluid has been produced in total by each force      |
| `factorio_fluid_production_output` | force<br/>name | How much of each fluid has been used/consumed in total by each force |

#### Energy

| Name                               | Labels                                 | Description                                                                 |
|------------------------------------|----------------------------------------|-----------------------------------------------------------------------------|
| `factorio_power_production_input`  | force<br/>name<br/>network<br/>surface | How much total power has been produced by each machine type in each network |
| `factorio_power_production_output` | force<br/>name<br/>network<br/>surface | How much total power has been consumed by each machine type in each network |

### Pollution

| Name                                   | Labels         | Description                                                                 |
|----------------------------------------|----------------|-----------------------------------------------------------------------------|
| `factorio_pollution_production_input`  | force<br/>name | How much pollution has been produced by which source in total by each force |
| `factorio_pollution_production_output` | force<br/>name | How much pollution has been consumed by which sink in total by each force   |

### Evolution

| Name                 | Labels         | Description                                                                                                                                                                                                                                                     |
|----------------------|----------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `factorio_evolution` | force<br/>type | The current evolution factor (`type == "total"`) for each force and its components (`type != "total"`).<br/>The current evolution factor is not the sum of its components! See [the wiki](https://wiki.factorio.com/Enemies#Methods_of_increasing) for details. |

### Science

| Name                            | Labels                             | Description                                                                                       |
|---------------------------------|------------------------------------|---------------------------------------------------------------------------------------------------|
| `factorio_research_queue`       | force<br/>name<br/>level<br/>index | The progress of each research in the queue, with its associated level if infinite, for each force |
| `factorio_items_launched_total` | force<br/>name                     | How many of each item have been sent to space by each force                                       |

### Trains

Important! Several train metrics have a very high cardinality. This means that you will very likely get many metrics,
which can slow down your server during metric collection (see `Settings>Scheduler timer` to collect less often) and if
you do not host your own metric backend (prometheus in our default case), can cost you a lot of money if unchecked! All
train stats can be disabled in the settings to prevent this.

Histogram bucket sizes can also be adjusted in the settings.

| Name                                                                                                                                                | Labels                   | Description                                                                                    |
|-----------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------|------------------------------------------------------------------------------------------------|
| `factorio_train_trip_time`                                                                                                                          | from<br/>to<br/>train_id | How long `train_id` took to go from `from` to `to` in seconds                                  |
| `factorio_train_wait_time`                                                                                                                          | from<br/>to<br/>train_id | How long `train_id` had to wait while going from `from` to `to` in seconds                     |
| `factorio_train_trip_time_groups_bucket`<br/>`factorio_train_trip_time_groups_sum`<br/>`factorio_train_trip_time_groups_count`                      | from<br/>to<br/>train_id | Histogram for how long `train_id` took to go from `from` to `to` in seconds                    |
| `factorio_train_wait_time_groups_bucket`<br/>`factorio_train_wait_time_groups_sum`<br/>`factorio_train_wait_time_groups_count`                      | from<br/>to<br/>train_id | Histogram for how long `train_id` had to wait while going from `from` to `to` in seconds       |
| `factorio_train_direct_loop_time`                                                                                                                   | a<br/>b                  | ???TODO???                                                                                     |
| `factorio_train_direct_loop_time_groups_bucket`<br/>`factorio_train_direct_loop_time_groups_sum`<br/>`factorio_train_direct_loop_time_groups_count` | a<br/>b                  | ???TODO???                                                                                     |
| `factorio_train_arrival_time`                                                                                                                       | station                  | How many seconds passed at `station` between the arrival of the last train the train before it |
| `factorio_train_arrival_time_groups_bucket`<br/>`factorio_train_arrival_time_groups_sum`<br/>`factorio_train_arrival_time_groups_count`             | station                  | Histogram for how many seconds passed at `station` between the arrival of the two trains       |

### Logistic Networks

| Name                                                      | Labels                                             | Description                                                          |
|-----------------------------------------------------------|----------------------------------------------------|----------------------------------------------------------------------|
| `factorio_logistic_network_all_construction_robots`       | force<br/>location (=surface)<br/>network          | Total number of construction robots in the network                   |
| `factorio_logistic_network_available_construction_robots` | force<br/>location (=surface)<br/>network          | Number of construction robots in the network available for a new job |
| `factorio_logistic_network_all_logistic_robots`           | force<br/>location (=surface)<br/>network          | Total number of construction robots in the network                   |
| `factorio_logistic_network_available_logistic_robots`     | force<br/>location (=surface)<br/>network          | Number of construction robots in the network available for a new job |
| `factorio_logistic_network_robot_limit`                   | force<br/>location (=surface)<br/>network          | Maximum number of robot the network can work with                    |
| `factorio_logistic_network_items`                         | force<br/>location (=surface)<br/>network<br/>name | Number of item `name` in the network                                 |


### Other

| Name                          | Labels         | Description                                                      |
|-------------------------------|----------------|------------------------------------------------------------------|
| `factorio_kill_count_input`   | force<br/>name | How many of each entity have been killed in total by each force  |
| `factorio_kill_count_output`  | force<br/>name | How many of each entity have been lost in total by each force    |
| `factorio_build_count_input`  | force<br/>name | How many of each entity have been placed in total by each force  |
| `factorio_build_count_output` | force<br/>name | How many of each entity have been removed in total by each force |

### Mods

The following metrics are only available if their respective mod is installed.

#### YARM

| Name                                    | Labels                  | Description                                                                               |
|-----------------------------------------|-------------------------|-------------------------------------------------------------------------------------------|
| `factorio_yarm_site_amount`             | force<br/>name<br/>type | How much `type` remains in the site with name `name`                                      |
| `factorio_yarm_site_ore_per_minute`     | force<br/>name<br/>type | How much `type` is mined at the site with name `name`                                     |
| `factorio_yarm_site_remaining_permille` | force<br/>name<br/>type | How much `type` is remaining (in permille) compared to the starting amount of site `name` |
