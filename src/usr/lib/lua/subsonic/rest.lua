-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

-- http://www.subsonic.org/pages/api.jsp
-- https://github.com/ultrasonic/ultrasonic
--	/tree/master/subsonic-api/src/integrationTest/resources

require "subsonic.table"

local config = config or require "subsonic.config"
local fs = require "subsonic.fs"
local log = require "subsonic.log"
local response = require "subsonic.response"
local metadata = require "subsonic.metadata"
local database = require "subsonic.db"

local table, ipairs, pairs, next = table, ipairs, pairs, next
local tonumber, tostring = tonumber, tostring

local print = print

module "subsonic.rest"

local function build_song_child(song)
	return {
		id = tostring(song.id),
		parent = tostring(song.music_directory_id),
		title = song.title,
		isDir = false,
		path = song.path,
		size = song.size,
		suffix = fs.extension(song.path),
		contentType = metadata.content_type(song.path),
		track = song.track,
		coverArt = tostring(song.music_directory_id)
		-- album =
		-- artist =
		-- bitRate =
		-- duration =
		-- genre =
		-- year =
	}
end

-------------------------
-- P U B L I C   A P I --
-------------------------
function ping(qs)
	response.send({}, qs)
end

function get_license(qs)
	local resp = { license = { valid = true } }
	response.send(resp, qs)
end

function get_music_folders(qs)
	local resp = { musicFolders = {} }
	for index, music_folder in ipairs(config.music_folders()) do
		if music_folder.enabled == '1' then
			table.insert(resp.musicFolders, { musicFolder = {
				id = index,
				name = music_folder.name
			} })
		end
	end
	response.send(resp, qs)
end

function get_indexes(qs)
	local modified_since = tonumber(qs.ifModifiedSince) or 0
	local music_folder_id = tonumber(qs.musicFolderId) or 0

	local db = database(config.db())
	local artist_filter = {
		parent_id = 0, mtime = { ">", modified_since }
	}
	local song_filter = {
		music_directory_id = 0, mtime = { ">", modified_since }
	}
	if music_folder_id ~= 0 then
		artist_filter.music_folder_id = music_folder_id
		song_filter.music_folder_id = music_folder_id
	end
	local artists = db:query("select * from music_directory", artist_filter)
	local songs = db:query("select * from song", song_filter)
	db:close()

	if next(artists) == nil and next(songs) == nil then
		log.info("no index change since " .. modified_since)
		response.send({}, qs)
		return
	end

	local resp = { indexes = {} }
	local current_index = {}
	local current_index_initial
	local last_modified = 0
	table.sort(artists, function(left, right)
		return left.name < right.name end)
	for _, artist in ipairs(artists) do
		local index_initial = artist.name:sub(1, 1):upper()
		if index_initial ~= current_index_initial then
			current_index_initial = index_initial
			table.insert(resp.indexes, { index = { name = index_initial } })
			current_index = resp.indexes[#resp.indexes].index
		end
		table.insert(current_index, { artist = {
			id = tostring(artist.id),
			name = artist.name
		} })
		if artist.mtime > last_modified then last_modified = artist.mtime end
	end
	table.sort(songs, function(left, right)
		return left.track < right.track end)
	for _, song in ipairs(songs) do
		if song.mtime > last_modified then last_modified = song.mtime end
		table.insert(resp.indexes, { child = build_song_child(song) })
	end
	resp.indexes.lastModified = last_modified
	response.send(resp, qs)
end

function get_music_directory(qs)
	local db = database(config.db())
	local directory = db:query_first("select * from music_directory",
		{ id = tonumber(qs.id) })
	local subfolders = db:query("select * from music_directory",
		{ parent_id = tonumber(qs.id) })
	local songs = db:query("select * from song",
		{ music_directory_id = tonumber(qs.id) })
	db:close()

	local resp = { directory = {
		id = directory.id,
		parent = directory.parent_id,
		name = directory.name
	} }
	table.sort(subfolders, function(left, right)
		return left.name < right.name end)
	for _, subfolder in ipairs(subfolders) do
		table.insert(resp.directory, { child = {
			id = tostring(subfolder.id),
			parent = tostring(subfolder.parent_id),
			title = subfolder.name,
			isDir = true,
			artist = directory.name,
			album = subfolder.name:gsub("^%d%d%d%d%s*[_-]*%s*", ""),
			coverArt = tostring(subfolder.id)
		} })
	end
	table.sort(songs, function(left, right)
		return left.track < right.track end)
	for _, song in ipairs(songs) do
		table.insert(resp.directory, { child = build_song_child(song) })
	end
	response.send(resp, qs)
end

function stream(qs)
	local db = database(config.db())
	local song = db:query_first("select * from song", { id = tonumber(qs.id) })
	local music_folder = config.music_folders()[song.music_folder_id]
	db:close()
	response.send_file(music_folder.path, song.path)
end

function get_cover_art(qs)
	local db = database(config.db())
	local covers = table.map(db:query("select * from cover",
		{ music_directory_id = tonumber(qs.id) }), function(cover)
		return cover, cover.dimension
	end)
	db:close()
	log.debug("covers:", covers)
	if next(covers) ~= nil then
		local cover = covers[tonumber(qs.size)] or covers[0]
		response.send_binary(cover.image,
			metadata.content_type(config.cover_file()))
	end
end

function get_random_songs(qs)
end

function scrobble(qs)
end

function get_playlists(qs)
end

function get_album_list(qs)
end

