#!/usr/bin/lua

require "subsonic.table"

local config = require "subsonic.config"
local metadata = require "subsonic.metadata"
local database = require "subsonic.db"
local image = require "subsonic.image"
local log = require "subsonic.log"
local fs = require "subsonic.fs"

-- local script = fs.basename(debug.getinfo(1, 'S').source)

-----------------
-- T A B L E S --
-----------------
local function create_table_music_directory(db)
	db:execute([[
		create table music_directory(
			id integer primary key autoincrement,
			music_folder_id integer not null,
			parent_id integer not null,
			path text not null,
			name text not null,
			mtime integer not null
		)
	]])
end

local function create_table_song(db)
	db:execute([[
		create table song(
			id integer primary key autoincrement,
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
			duration integer
		)
	]])
end

local function create_table_cover(db)
	db:execute([[
		create table cover(
			id integer primary key autoincrement,
			music_folder_id integer not null,
			music_directory_id integer not null,
			mtime integer not null,
			image blob not null,
			dimension integer not null
		)
	]])
end

local function create_table_artist(db)
	db:execute([[
		create table artist(
			id integer primary key autoincrement,
			music_folder_id integer not null,
			music_directory_id integer not null,
			name text not null
		)
	]])
end

local function create_table_album(db)
	db:execute([[
		create table album(
			id integer primary key autoincrement,
			music_folder_id integer not null,
			music_directory_id integer not null,
			artist_id integer not null,
			name text not null,
			song_count integer,
			duration integer,
			created text
		)
	]])
end

local function create_table_paylist(db)
	db:execute([[
		create table paylist(
			id integer primary key autoincrement,
			playlist_id integer not null,
			name text not null,
			comment text,
			owner text,
			public int
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
	create_table_paylist(db)
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

local function add_music_directory(db, music_folder, path, parent_id)
	local music_directory = db:query_first("select * from music_directory",
		{ music_folder_id = music_folder[".index"], path = path })
	if not music_directory then
		music_directory = db:insert("music_directory", {
			music_folder_id = music_folder[".index"],
			parent_id = parent_id,
			path = path,
			name = fs.basename(path):gsub("[_-]", " "),
			mtime = fs.last_modification(music_folder.path, path)
		})
	elseif fs.last_modification(music_folder.path, path)
			> music_directory.mtime then
		db:update("music_directory", {
			mtime = fs.last_modification(music_folder.path, path)
		}, { id = music_directory.id })
		music_directory.mtime = fs.last_modification(music_folder.path, path)
	else
		log.debug("music_directory already exists")
	end
	return music_directory
end

local function add_artist(db, music_folder, music_directory_id, artist_name)
	local artist = db:query_first("select * from artist",
		{ music_folder_id = music_folder[".index"], name = artist_name })
	if not artist then
		artist = db:insert("artist", {
			music_folder_id = music_folder[".index"],
			music_directory_id = music_directory_id,
			name = artist_name
		})
	else
		log.debug("artist already exists")
	end
	return artist
end

local function add_album(db, music_folder,
		music_directory_id, artist_name, album_name)
	local artist = add_artist(db, music_folder,
		music_directory_id, artist_name)
	local album = db:query_first("select * from album", {
		music_folder_id = music_folder[".index"],
		artist_id = artist.id,
		name = album_name
	})
	if not album then
		album = db:insert("album", {
			music_folder_id = music_folder[".index"],
			music_directory_id = music_directory_id,
			artist_id = artist.id,
			name = album_name
		})
	else
		log.debug("album already exists")
	end
	return album
end

local function get_metadata(db, music_folder, music_directory_id, ...)
	local metadata = metadata.read(...)
	local album = add_album(db, music_folder,
		music_directory_id, metadata.artist, metadata.album)
	return {
		title = metadata.title,
		track = metadata.track,
		album_id = album.id,
		year = metadata.year,
		genre = metadata.genre,
		bitrate = metadata.bitrate,
		duration = nil
	}
end

local function add_song(db, music_folder, path, music_directory_id, track)
	local song = db:query_first("select * from song",
		{ music_folder_id = music_folder[".index"], path = path })
	if not song then
		db:insert("song", table.merge({
			music_folder_id = music_folder[".index"],
			music_directory_id = music_directory_id,
			path = path,
			title = fs.no_extension(fs.basename(path))
				:gsub("[_-]", " "):gsub("^%d+%s*", ""),
			mtime = fs.last_modification(music_folder.path, path),
			size = fs.file_size(music_folder.path, path),
			track = track
		}, get_metadata(db, music_folder, music_directory_id,
			music_folder.path, path)))
	elseif fs.last_modification(music_folder.path, path) > song.mtime then
		db:update("song", table.merge({
			mtime = fs.last_modification(music_folder.path, path),
			size = fs.file_size(music_folder.path, path),
			track = track
		}, get_metadata(db, music_folder, music_directory_id,
			music_folder.path, path)),
		{ id = song.id })
	else
		log.debug("song already exists")
	end
end

local function get_cover(file, size)
	if size == 0 then
		return assert(fs.readfile(file))
	else
		return assert(image.resize(file, size))
	end
end

local function add_cover(db, music_folder, path, music_directory_id, size)
	local cover = db:query_first("select * from cover", {
		music_folder_id = music_folder[".index"],
		music_directory_id = music_directory_id,
		dimension = size
	})
	if not cover then
		db:insert("cover", {
			music_folder_id = music_folder[".index"],
			music_directory_id = music_directory_id,
			mtime = fs.last_modification(music_folder.path, path),
			image = get_cover(fs.join_path(music_folder.path, path), size),
			dimension = size
		})
	elseif fs.last_modification(music_folder.path, path) > cover.mtime then
		db:update("cover", {
			mtime = fs.last_modification(music_folder.path, path),
			image = get_cover(fs.join_path(music_folder.path, path), size)
		}, { id = cover.id })
	else
		log.debug("cover already exists")
	end
end

local function process(db, music_folder, path, parent_id)
	local track = 1
	for _, subpath in ipairs(fs.dir(music_folder.path, path)) do
		if fs.is_dir(music_folder.path, subpath) then
			local id = add_music_directory(
				db, music_folder, subpath, parent_id).id
			-- TODO: skip processing folder when no mtime change?
			process(db, music_folder, subpath, id)
		elseif metadata.is_media(music_folder.path, subpath) then
			log.info("process song:", subpath)
			add_song(db, music_folder, subpath, parent_id, track)
			track = track + 1
		elseif fs.basename(subpath) == config.cover_file() then
			log.info("process cover:", subpath, "!lf")
			local cover_sizes = table.map(config.cover_size(), function(size)
				return tonumber(size)
			end)
			table.insert(cover_sizes, 1, 0)
			for _, cover_size in ipairs(cover_sizes) do
				log.info("!ts", (cover_size == 0)
					and "original" or cover_size, "!lf")
				add_cover(db, music_folder, subpath, parent_id, cover_size)
			end
			log.info("!ts", "")
		end
	end
end

-------------
-- M A I N --
-------------
log.open("/dev/tty", "info")
local nixio = require "nixio"
-- nixio.fs.remove(config.db())

local db = open_db(config.db())
for _, music_folder in ipairs(config.music_folders()) do
	if music_folder.enabled == '1' then
		db:execute("begin transaction")
		process(db, music_folder, "", 0)
		db:execute("commit")
	end
end
-- TODO: cleanup removed entries!
db:close()

