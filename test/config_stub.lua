-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

module "config_stub"

local music_folders_stub
local log_file_stub
local db_stub

function music_folders()
	return music_folders_stub
end

function set_music_folders(stub)
	music_folders_stub = stub
end

function log_file()
	return log_file_stub
end

function set_log_file(stub)
	log_file_stub = stub
end

function log_level()
	return "debug"
end

function db()
	return db_stub
end

function set_db(stub)
	db_stub = stub
end

