function handleYARM(site)
	gauge_yarm_site_amount:set(site.amount, { site.force_name, site.site_name, site.ore_type })
	gauge_yarm_site_ore_per_minute:set(site.ore_per_minute, { site.force_name, site.site_name, site.ore_type })
	gauge_yarm_site_remaining_permille:set(site.remaining_permille, { site.force_name, site.site_name, site.ore_type })
end
