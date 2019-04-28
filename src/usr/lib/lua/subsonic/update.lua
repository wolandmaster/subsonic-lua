#!/usr/bin/lua

local config = require "subsonic.config"
local metadata = require "subsonic.metadata"
local database = require "subsonic.db"
local log = require "subsonic.log"
local fs = require "subsonic.fs"

-- local script = fs.basename(debug.getinfo(1, 'S').source)

-----------------
-- T A B L E S --
-----------------
local function create_table_music_directory(db)
	db:execute([[
		create table music_directory(
			id integer primary key not null unique,
			parent_id integer not null,
			music_folder_id integer not null,
			name text not null,
			mtime integer not null
		)
	]])
end

local function create_table_artist(db)
	db:execute([[
		create table artist(
			id integer primary key not null unique,
			name text not null,
			cover_id integer
		)
	]])
end

local function create_table_album(db)
	db:execute([[
		create table album(
			id integer primary key not null unique,
			artist_id integer not null,
			name text not null,
			song_count integer not null,
			cover_art_id integer,
			duration integer,
			created text
		)
	]])
end

local function create_table_song(db)
	db:execute([[
		create table song(
			id integer primary key not null unique,
			music_folder_id integer not null,
			music_directory_id integer not null,
			path text not null,
			title text not null,
			mtime integer not null,
			size integer not null,
			track integer not null,
			album_id integer,
			year integer,
			genre text,
			bitrate integer,
			duration integer,
			cover_id integer
		)
	]])
end

local function create_table_cover(db)
	db:execute([[
		create table cover(
			id integer primary key not null unique,
			image blob not null,
			mtime integer not null
		)
	]])
end

local function create_tables(db)
	log.info("create tables...")
	db:execute("begin transaction")
	create_table_music_directory(db)
	create_table_artist(db)
	create_table_album(db)
	create_table_song(db)
	create_table_cover(db)
	db:execute("commit")
end

-------------------------
-- O P E R A T I O N S --
-------------------------
local function open_db(file)
	local db = database(file)
	if fs.file_size(file) == 0 then
		create_tables(db)
	end
	return db
end

local function add_music_directory(music_folder, path, parent_id, db)
	return db:insert("music_directory", {
		parent_id = parent_id,
		music_folder_id = music_folder[".index"],
		name = fs.basename(path):gsub("[_-]", " "),
		mtime = fs.last_modification(music_folder.path, path)
	})
end

local function add_artist()
--	local artist_id = db:query("select * from artist", {
--		name = ""
--	})
end

local function add_album()
end

local function add_song(music_folder, path, track, music_directory_id, db)
	db:execute("begin transaction")
	local song = db:query_first("select * from song",
		{ path = path, music_folder_id = music_folder[".index"] })
	if not song then
		song = db:insert("song", {
			music_folder_id = music_folder[".index"],
			music_directory_id = music_directory_id,
			path = path,
			title = fs.no_extension(fs.basename(path))
				:gsub("[_-]", " "):gsub("^%d+%s*", ""),
			mtime = 0,
			size = fs.file_size(music_folder.path, path),
			track = track
		})
	end
	if fs.last_modification(music_folder.path, path) > song.mtime then
		local updates = {
			mtime = fs.last_modification(music_folder.path, path)
		}
		-- local meta = metadata.read(music_folder.path, path)
		db:update("song", updates, { id = song.id })
		-- TODO: update the mtime of all above music directory?
	end
	db:execute("commit")
end

local function process(music_folder, path, parent_id, db)
	local track = 1
	for _, subpath in ipairs(fs.dir(music_folder.path, path)) do
		if fs.is_dir(music_folder.path, subpath) then
			local id = add_music_directory(music_folder,
				subpath, parent_id, db).id
			-- TODO: skip processing folder when no mtime change?
			process(music_folder, subpath, id, db)
		elseif metadata.is_media(music_folder.path, subpath) then
			log.info("process song:", subpath)
			add_song(music_folder, subpath, track, parent_id, db)
			track = track + 1
		end
	end
end

-------------
-- M A I N --
-------------
log.open("/dev/tty", "debug")
local nixio = require "nixio"
nixio.fs.remove(config.db())
		
local db = open_db(config.db())
for _, music_folder in ipairs(config.music_folders()) do
	if music_folder.enabled == '1' then
		process(music_folder, "", 0, db)
	end
end
db:close()

