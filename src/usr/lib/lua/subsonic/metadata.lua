-- Copyright 2015-2017 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

local fs = require "subsonic.fs"
local id3 = require "subsonic.id3"
local mpeg = require "subsonic.mpeg"

local tonumber, type = tonumber, type

module "subsonic.metadata"

function read(path)
	local metadata = {}
	local suffix = fs.suffix(path)

	if suffix == "mp3" then
		mpeg_info = mpeg(path):read()
		id3_info = id3(path):read()

		metadata.bitrate = mpeg_info.bitrate
		metadata.name = id3_info.TIT2
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

