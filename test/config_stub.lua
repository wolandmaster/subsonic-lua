-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

module "config_stub"

local conf = {
	["music_folders"] = {},
	["log_file"] = "/dev/tty",
	["log_level"] = "info",
	["db"] = ""
}

function music_folders()
	return conf.music_folders
end

function log_file()
	return conf.log_file
end

function log_level()
	return conf.log_level
end

function db()
	return conf.db
end

function set_music_folders(value)
	conf.music_folders = value
end

function set_log_file(value)
	conf.log_file = value
end

function set_log_level(value)
	conf.log_level = value
end

function set_db(value)
	conf.db = value
end

