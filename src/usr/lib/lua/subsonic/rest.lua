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
		coverArt = tostring(song.music_directory_id),
		album = song.album_name,
		artist = song.artist_name,
		year = song.year,
		genre = song.genre,
		bitRate = song.bitrate
		-- duration =
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
	-- local modified_since = tonumber(qs.ifModifiedSince) or 0
	local modified_since = 0
	local music_folder_id = tonumber(qs.musicFolderId) or nil

	local db = database(config.db())
	local artist_filter = {
		music_folder_id = music_folder_id,
		parent_id = 0,
		mtime = { ">", modified_since }
	}
	local song_filter = {
		["song.music_folder_id"] = music_folder_id,
		["song.music_directory_id"] = 0,
		["song.mtime"] = { ">", modified_since }
	}
	local artists = db:query("select * from music_directory", artist_filter)
	local songs = db:query("select song.*, "
		.. "album.name as album_name, artist.name as artist_name from song "
		.. "left join album on song.album_id = album.id "
		.. "left join artist on album.artist_id = artist.id", song_filter)
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
	local songs = db:query("select song.*, "
		.. "album.name as album_name, artist.name as artist_name from song "
		.. "left join album on song.album_id = album.id "
		.. "left join artist on album.artist_id = artist.id",
		{ ["song.music_directory_id"] = tonumber(qs.id) })
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
	response.send_file(qs, music_folder.path, song.path)
end

function get_cover_art(qs)
	local db = database(config.db())
	local cover = db:query_first("select * from cover", {
		music_directory_id = tonumber(qs.id),
		dimension = qs.size and tonumber(qs.size) or 0
	})
	if not cover then
		cover = db:query_first("select * from cover", {
			music_directory_id = tonumber(qs.id), dimension = 0
		})
	end
	db:close()
	if cover then
		response.send_binary(cover.image,
			metadata.content_type(config.cover_file()))
	end
end

function get_random_songs(qs)
	local limit = qs.size and tonumber(qs.size) or 10
	local genre = qs.genre and " where (genre = '" .. qs.genre
		.. "' or genre is null)" or ""
	local from_year = qs.fromYear and " where (year >= " .. qs.fromYear
		.. " or year is null)" or ""
	local to_year = qs.toYear and " where (year <= " .. qs.toYear
		.. " or year is null)" or ""

	local db = database(config.db())
	local songs = db:query("select * from song"
		.. db:build_filters({ music_folder_id = qs.musicFolder
			and tonumber(qs.musicFolderId) } )
		.. from_year .. to_year .. genre
		.. " order by random() limit " .. limit)
	db:close()

	local resp = { randomSongs = {} }
	for _, song in ipairs(songs) do
		table.insert(resp.randomSongs, { song = build_song_child(song) })
	end
	response.send(resp, qs)
end

-- type:
-- random, newest, highest, recent, frequent, starred
-- alphabeticalByName, alphabeticalByArtist, byYear, byGenre
function get_album_list(qs)
	local sort = ""
	if not qs.type or qs.type == "random" then
		sort = " order by random()"
	elseif qs.type == "newest" then
		sort = " order by mtime desc"
	end
	local limit = qs.size and " limit " .. qs.size or " limit 10"
	local offset = qs.offset and " offset " .. qs.offset or " offset 0"
	local from_year = ""	-- TODO
	local to_year = ""		-- TODO
	local genre = ""		-- TODO
	local music_folder = qs.musicFolderId
		and " where music_folder_id = " .. qs.musicFolderId or ""

	local db = database(config.db())
	local folders = db:query("select * from music_directory"
		.. " where parent_id != 0" .. music_folder .. genre
		.. from_year .. to_year .. sort .. limit .. offset)
	db:close()

	local resp = { albumList = {} }
	for _, folder in ipairs(folders) do
		table.insert(resp.albumList, { album = {
			id = tostring(folder.id),
			parent = tostring(folder.parent_id),
			title = folder.name,
			isDir = true,
			coverArt = tostring(folder.id)
		} })
	end
	response.send(resp, qs)
end

function create_playlist(qs)
	log.debug(qs)
	response.send({}, qs)
end

function playlists(qs)
end

function playlist(qs)
end

function get_album_list_2(qs)
end

function scrobble(qs)
end

function get_playlists(qs)
end

