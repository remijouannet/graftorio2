data:extend({
	{
		type = "string-setting",
		name = "graftorio2-train-histogram-buckets",
		setting_type = "startup",
		default_value = "10,30,60,90,120,180,240,300,600",
		allow_blank = false,
	},
	{
		type = "int-setting",
		name = "graftorio2-nth-tick",
		setting_type = "startup",
		default_value = "300",
		allow_blank = false,
	},
	{
		type = "bool-setting",
		name = "graftorio2-server-save",
		setting_type = "startup",
		default_value = false,
		allow_blank = false,
	},
	{
		type = "bool-setting",
		name = "graftorio2-disable-train-stats",
		setting_type = "startup",
		default_value = false,
		allow_blank = false,
	},
	{
		type = "bool-setting",
		name = "graftorio2-enable-signal-groups",
		setting_type = "startup",
		default_value = false,
		allow_blank = false,
	},
	{
		type = "string-setting",
		name = "graftorio2-log-level",
		setting_type = "runtime-global",
		default_value = "info",
		allow_blank = false,
		allowed_values = { "info", "debug", "verbose", "trace" }
	},
})
