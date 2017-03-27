-- Copyright 2015-2017 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

local fs = require "subsonic.fs"
local log = require "subsonic.log"
local config = require "subsonic.config"
local sqlite = require "subsonic.db"

local ipairs, pairs, next, table = ipairs, pairs, next, table

module "subsonic.cache"

function create_tables(db)
	db:execute("begin transaction")
	db:execute([[
		create table entry(
			id integer primary key not null unique,
			name text not null,
			mtime integer not null,
			kind text not null,
			path text not null,
			music_folder integer not null,
			size integer,
			parent integer,
			album text,
			artist text,
			track integer,
			disc_number integer,
			year integer,
			genre text,
			cover_art blob,
			bitrate integer
		)
	]])
	db:execute("commit")
end

function open_db()
	local cache_file = config.get_cache_file()
	local db = sqlite(cache_file)
	if fs.file_size(cache_file) == 0 then
		create_tables(db)
	end
	return db
end

function get_entry(filters)
	local entries = get_entries(filters)
	return (#entries == 1) and entries[1] or entries
end

function get_entries(filters)
	local db = open_db()
	local entries = db:query("select * from entry", filters)
	db:close()
	return entries
end

function get_random_entry(limit, filters)
	local db = open_db()
	local entry = db:query("select * from entry"
		.. db:build_filters(filters or {})
		.. " order by random() limit " .. limit)
	db:close()
	return entry
end

function set_entry(values)
	if next(values) ~= nil then
		local db = open_db()
		db:execute("begin transaction")
		db:execute("delete from entry", {
			parent = distinct(values, "parent"),
			music_folder = distinct(values, "music_folder")
		})
		for _, entry in ipairs(values) do
			db:insert("entry", entry)
		end
		db:execute("commit")
		db:close()
	end
end

function update_entry(values, filters)
	local db = open_db()
	db:update("entry", values, filters)
	db:close()
end

function distinct(values, subvalue)
	local values_set = {}
	for _, entry in ipairs(values) do
		values_set[subvalue and entry[subvalue] or entry] = true
	end
	local distinct_values = {}
	for value, _ in pairs(values_set) do
		table.insert(distinct_values, value)
	end
	return #distinct_values == 1 and distinct_values[1] or distinct_values
end

