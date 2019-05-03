-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

local fs = require "subsonic.fs"
local id3 = require "subsonic.id3"
local mpeg = require "subsonic.mpeg"

local tonumber, type = tonumber, type

module "subsonic.metadata"

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

local IMAGE = {
	jpg = "image/jpeg", jpeg = "image/jpeg"
}

function is_media(...)
	local ext = fs.extension(fs.join_path(...)):lower()
	return AUDIO[ext] or VIDEO[ext]
end

function content_type(...)
	local ext = fs.extension(fs.join_path(...)):lower()
	return is_media(...) or IMAGE[ext] or "application/octet-stream"
end

function read(...)
	local path = fs.join_path(...)
	local metadata = {}
	local extension = fs.extension(path)
	if extension == "mp3" then
		-- mpeg_info = mpeg(path):read()
		id3_info = id3(path):read()

		-- metadata.bitrate = mpeg_info.bitrate
		metadata.title = id3_info.TIT2
		metadata.artist = id3_info.TPE2 or id3_info.TPE1
		metadata.album = id3_info.TALB
		metadata.year = tonumber(id3_info.TDRC)
		if id3_info.TRCK then
			metadata.track = (type(id3_info.TRCK) == "string")
				and tonumber((id3_info.TRCK:gsub("/%d+$", "")))
				or id3_info.TRCK
		end
		metadata.genre = id3_info.TCON
	end
	return metadata
end

