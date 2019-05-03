-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

local uci = require "luci.model.uci".cursor()

module "subsonic.config"

local function get_type(type)
	local sections = {}
	uci:foreach("subsonic", type, function(s)
		sections[s[".index"]] = s
	end)
	return sections
end

-------------------------
-- P U B L I C   A P I --
-------------------------
function music_folders()
	return get_type("music-folder")
end

function db()
	return uci:get("subsonic", "config", "db")
end

function log_file()
	return uci:get("subsonic", "config", "log_file")
end

function log_level()
	return uci:get("subsonic", "config", "log_level")
end

function cover_file()
	return uci:get("subsonic", "config", "cover_file")
end

function cover_size()
	return uci:get("subsonic", "config", "cover_size") or {}
end

