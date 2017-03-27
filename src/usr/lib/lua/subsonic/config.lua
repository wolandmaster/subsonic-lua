-- Copyright 2015-2017 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

local uci = require "luci.model.uci".cursor()

module "subsonic.config"

function get_type(type)
	local sections = {}
	uci:foreach("subsonic", type, function(s)
		sections[s[".index"]] = s
	end)
	return sections
end

function get_music_folders()
	return get_type("music_folder")
end

function get_cache_file()
	return uci:get("subsonic", "config", "cache_file")
end

function get_log_file()
	return uci:get("subsonic", "config", "log_file")
end

function get_log_level()
	return uci:get("subsonic", "config", "log_level")
end

