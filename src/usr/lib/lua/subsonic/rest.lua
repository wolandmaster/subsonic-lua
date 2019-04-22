-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

-- http://www.subsonic.org/pages/api.jsp

require "subsonic.table"

local config = config or require "subsonic.config"
local fs = require "subsonic.fs"
local log = require "subsonic.log"
local xml = require "subsonic.xml"
local response = require "subsonic.response"
local metadata = require "subsonic.metadata"
local database = require "subsonic.db"

local ipairs, pairs, table, next, tonumber, unpack = ipairs, pairs, table, next, tonumber, unpack

local print = print

module "subsonic.rest"

local function build_song_child(song)
	return {
		id = song.id,
		parent = song.music_directory_id,
		title = song.title,
		isDir = false,
		path = song.path,
		size = song.size,
		suffix = fs.extension(song.path),
		contentType = metadata.content_type(song.path)
		-- album =
		-- artist =
		-- bitRate =
		-- coverArt =
		-- duration =
		-- genre =
		-- track =
		-- year =
	}
end
--	.. '<child album="Album-ID3" artist="Artist-ID3" bitRate="128" contentType="audio/mpeg" '
--	.. 'coverArt="1" duration="1" genre="Other" id="2" isDir="false" parent="3" '
--	.. 'path="Artist/Album/CD1/Song4.mp3" size="1234" suffix="mp3" title="Song4-ID3" track="1" year="1982"/>'

-- TODO: json
-- /rest/ping.view?f=json
-- {"subsonic-response":{"status":"ok","version":"1.16.0","type":"funkwhale","funkwhaleVersion":"0.18.3+git.a414461f"}}
-- https://github.com/ultrasonic/ultrasonic/tree/master/subsonic-api/src/integrationTest/resources;

-------------------------
-- P U B L I C   A P I --
-------------------------
function ping(qs)
	response.send_xml()
end

function get_license(qs)
	response.send_xml(xml("license", { valid = "true" }):build())
end

function get_music_folders(qs)
	local music_folders_xml = xml("musicFolders")
	for index, music_folder in ipairs(config.music_folders()) do
		if music_folder.enabled == '1' then
			music_folders_xml:child("musicFolder", {
				id = index,
				name = music_folder.name
			})
		end
	end
	response.send_xml(music_folders_xml:build())
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
		artist_filter["music_folder_id"] = music_folder_id
		song_filter["music_folder_id"] = music_folder_id
	end
	local artists = db:query("select * from music_directory", artist_filter)
	local songs = db:query("select * from song", song_filter)
	db:close()

	if next(artists) == nil and next(songs) == nil then
		log.info("no index change since " .. modified_since)
		response.send_xml()
		return
	end
	local current_index
	local current_index_xml
	local last_modified = 0
	local indexes_xml = xml("indexes")
	table.sort(artists, function(left, right) return left.name < right.name end)
	for _, artist in ipairs(artists) do
		local index = artist.name:sub(1, 1)
		if index ~= current_index then
			current_index = index
			current_index_xml = indexes_xml:child("index", { name = index })
		end
		if artist.mtime > last_modified then last_modified = artist.mtime end
		current_index_xml:child("artist", {
			id = artist.id,
			name = artist.name
		})
	end
	table.sort(songs, function(left, right) return left.title < right.title end)
	for _, song in ipairs(songs) do
		if song.mtime > last_modified then last_modified = song.mtime end
		indexes_xml:child("child", build_song_child(song))
	end
	response.send_xml(indexes_xml:attr({ lastModified = last_modified }):build())
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
	
	local directory_xml = xml("directory", {
		id = directory.id,
		parent = directory.parent_id,
		name = directory.name
	})
	table.sort(subfolders, function(left, right) return left.name < right.name end)
	for _, subfolder in ipairs(subfolders) do
		 directory_xml:child("child", {
			id = subfolder.id,
			parent = subfolder.parent_id,
			title = subfolder.name,
			isDir = true,
			artist = directory.name
		})
	end
	table.sort(songs, function(left, right) return left.title < right.title end)
	for _, song in ipairs(songs) do
		 directory_xml:child("child", build_song_child(song))
	end
	response.send_xml(directory_xml:build())
end

function stream(qs)
	local db = database(config.db())
	local song = db:query_first("select * from song", { id = tonumber(qs.id) })
	local music_folder = config.music_folders()[song.music_folder_id]
	db:close()
	response.send_file(music_folder.path, song.path)
end

function get_random_songs(qs)
end

function scrobble(qs)
end

function get_playlists(qs)
end

function get_album_list(qs)
end

function get_cover_art(qs)
end

