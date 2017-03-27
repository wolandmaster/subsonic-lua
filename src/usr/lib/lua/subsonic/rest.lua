-- Copyright 2015-2017 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

local fs = require "subsonic.fs"
local log = require "subsonic.log"
local xml = require "subsonic.xml"
local cache = require "subsonic.cache"
local config = require "subsonic.config"
local response = require "subsonic.response"
local metadata = require "subsonic.metadata"

local ipairs, pairs, table, next, tonumber = ipairs, pairs, table, next, tonumber

module "subsonic.rest"

local AUDIO = {
	mp3 = "audio/mpeg",
	flac = "audio/flac",
	wma = "audio/x-ms-wma",
	ogg = "audio/ogg",
	aac = "audio/aac"
}
local VIDEO = {
	avi = "video/x-msvideo",
	flv = "video/x-flv",
	mp4 = "video/mp4",
	mkv = "video/x-matroska",
	wmv = "video/x-ms-wmv",
	mov = "video/quicktime",
	mpg = "video/mpg", mpeg = "video/mpg"
}

function ping(qs)
end

function get_license(qs)
	return xml("license", { valid = "true" }):build()
end

function get_music_folders(qs)
	local music_folders = xml("musicFolders")
	for _, music_folder in ipairs(config.get_music_folders()) do
		if music_folder.enabled == '1' then
			music_folders:sibling("musicFolder", {
				id = music_folder[".index"],
				name = music_folder.name
			})
		end
	end
	return music_folders:build_root()
end

function get_indexes(qs)
	local modified_since = tonumber(qs.ifModifiedSince) or 0
	local music_folder_id = tonumber(qs.musicFolderId) or 1
	local music_folder = config.get_music_folders()[music_folder_id]
	local mtime = fs.last_modification(music_folder.path)
	local cached_music_folder = cache.get_entry({
		parent = "null",
		music_folder = music_folder_id
	})

	local indexes = {}
	if next(cached_music_folder) ~= nil and mtime == modified_since then
		log.info("no index change in '" .. music_folder.name .. "' since " .. modified_since)
		return ""
	elseif next(cached_music_folder) == nil or mtime > cached_music_folder.mtime then
		log.info("updating indexes cache of " .. music_folder.name)
		indexes = build_entries(music_folder)
		cache.set_entry(indexes)
		cache.set_entry({ build_entry(music_folder, music_folder.path) })
	else
		log.info("loading indexes from cache of " .. music_folder.name)
		indexes = cache.get_entries({ parent = cached_music_folder.id })
	end

	sort_entries(indexes)
	local current_index 
	local current_index_xml
	local indexes_xml = xml("indexes", { lastModified = mtime, ignoredArticles = "" })
	for _, entry in ipairs(indexes) do
		if entry.kind == "dir" then
			local index = entry.name:sub(1, 1)
			if index ~= current_index then
				current_index = index
				current_index_xml = indexes_xml:child("index", { name = index })
			end
			current_index_xml:child("artist", {
				id = entry.id,
				name = entry.name
			})
		elseif entry.kind == "reg" then
			indexes_xml:child("child", build_entry_xml(entry))
		elseif entry.kind == "lnk" then
			-- TODO: return a shortcut?
		end
	end
	return indexes_xml:build_root()
end

function get_music_directory(qs)
	local music_directory = cache.get_entry({ id = tonumber(qs.id) })
	local music_folder = config.get_music_folders()[music_directory.music_folder]
	local cached_child = cache.get_entries({ parent = tonumber(qs.id) })
	local mtime = fs.last_modification(music_folder.path, music_directory.path)
	
	local child = {}
	if next(cached_child) == nil or mtime > music_directory.mtime then
		log.info("updating child cache of " .. music_directory.path)
		child = build_entries(music_folder, music_directory.path)
		cache.set_entry(child)
		cache.update_entry({ mtime = mtime }, { id = music_directory.id })
	else
		log.info("loading child from cache of " .. music_directory.path)
		child = cached_child
	end

	sort_entries(child)
	local music_directory_xml = xml("musicDirectory", {
		id = tonumber(qs.id),
		name = music_directory.name
	})
	for _, entry in ipairs(child) do
		music_directory_xml:child("child", build_entry_xml(entry))
	end
	return music_directory_xml:build_root()
end

function stream(qs)
	local entry = cache.get_entry({ id = tonumber(qs.id) })
	local music_folder = config.get_music_folders()[entry.music_folder]
	response.send_file(music_folder.path, entry.path)
end

function get_random_songs(qs)
	local limit = tonumber(qs.size) or 50
	local random_songs = cache.get_random_entry(limit, {
		kind = "reg"
	})

	local random_songs_xml = xml("randomSongs")
	for _, entry in ipairs(random_songs) do
		random_songs_xml:child("song", build_entry_xml(entry))
	end
	return random_songs_xml:build_root()
end

function scrobble(qs)
end

function get_playlists(qs)
	local playlists_xml = xml("playlists")
	return playlists_xml:build_root()
end

function get_album_list(qs)
	local album_list_xml = xml("albumList")
	return album_list_xml:build_root()
end

--[[ P R I V A T E ]]--

function build_entries(music_folder, path)
	local entries = {}
	local folder = fs.join_path(music_folder.path, path)
	for subpath in fs.iterate_folder(folder) do
		local suffix = fs.suffix(subpath)
		if fs.is_dir(subpath) or AUDIO[suffix] or VIDEO[suffix] then
			local entry = build_entry(music_folder, subpath)
			entry.parent = fs.inode(folder)
			table.insert(entries, entry)
		end
	end
	return entries
end

function build_entry(music_folder, path)
	local entry = {
		id = fs.inode(path),
		name = fs.basename(path):gsub("_", " "),
		mtime = fs.last_modification(path),
		kind = fs.path_type(path),
		path = fs.relative(path, music_folder.path),
		music_folder = music_folder[".index"]
	}
	if fs.is_file(path) then
		entry.size = fs.file_size(path)
		for k, v in pairs(metadata.read(path)) do entry[k] = v end
	end
	return entry
end

function build_entry_xml(entry)
	local attributes = {
		id = entry.id,
		parent = entry.parent,
		title = entry.name,
		path = entry.path
	}
	if entry.kind == "dir" then
		attributes.isDir = true
	elseif entry.kind == "reg" then
		local suffix = fs.suffix(entry.path)
		attributes.isDir = false
		attributes.suffix = suffix
		attributes.size = entry.size
		attributes.contentType = AUDIO[suffix] or VIDEO[suffix]
		attributes.isVideo = VIDEO[suffix] ~= nil
		attributes.bitRate = entry.bitrate
		attributes.artist = entry.artist
		attributes.album = entry.album
		attributes.genre = entry.genre
		attributes.year = entry.year
		attributes.track = entry.track
		-- attributes.coverArt = 
	end
	return attributes
end

function sort_entries(entries)
	table.sort(entries, function(left, right)
		if left.kind < right.kind then
			return true
		elseif left.kind > right.kind then
			return false
		elseif left.track and right.track then
			return tonumber(left.track) < tonumber(right.track)
		else
			return left.name < right.name
		end
	end)
end

