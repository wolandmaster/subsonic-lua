-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

-- http://www.mpeg-tech.org/programmer/frame_header.html
-- http://www.datavoyage.com/mpgscript/mpeghdr.htm

local nixio = require "nixio"
local log = require "subsonic.log"

local bor = nixio.bit.bor
local band = nixio.bit.band
local lshift = nixio.bit.lshift
local rshift = nixio.bit.rshift

local VERSION = { [0] = "v2.5", [1] = "-", [2] = "v2", [3] = "v1" }
local LAYER = { [0] = "-", [1] = "layer III", [2] = "layer II", [3] = "layer I" }
local BITRATE_VERSION1_LAYER1 = { 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448 }
local BITRATE_VERSION1_LAYER2 = { 32, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 384 }
local BITRATE_VERSION1_LAYER3 = { 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320 }
local BITRATE_VERSION2_LAYER1 = { 32, 48, 56, 64, 80, 96, 112, 128, 144, 160, 176, 192, 224, 256 }
local BITRATE_VERSION2_LAYER23 = { 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160 }
local BITRATE = {
	[0] = { BITRATE_VERSION2_LAYER23, BITRATE_VERSION2_LAYER23, BITRATE_VERSION2_LAYER1 },
	[2] = { BITRATE_VERSION2_LAYER23, BITRATE_VERSION2_LAYER23, BITRATE_VERSION2_LAYER1 },
	[3] = { BITRATE_VERSION1_LAYER3, BITRATE_VERSION1_LAYER2, BITRATE_VERSION1_LAYER1 }
}
local SAMPLE_RATE = {
	[0] = { [0] = 11025, [1] = 12000, [2] = 8000 },
	[2] = { [0] = 22050, [1] = 24000, [2] = 16000 },
	[3] = { [0] = 44100, [1] = 48000, [2] = 32000 }
}
local CHANNEL_MODE = {
	[0] = "Stereo",
	[1] = "Joint Stereo",
	[2] = "Dual Channel",
	[3] = "Mono"
}
local SAME_BITRATE_FRAMES_TO_ASSUME_CBR = 15

local mpeg = {}
mpeg.__index = mpeg

setmetatable(mpeg, {
	__call = function (cls, ...)
		return cls.new(...)
	end,
})

local function read_byte(fd, count)
	count = count or 1
	return string.byte(fd:read(count), 1, count)
end

local function read_bit(num, from, to)
	to = to or from
	return band(rshift(num, 32 - to), lshift(1, to - from + 1) - 1)
end

local function read_synchsafe_int(fd)
	local b1, b2, b3, b4 = string.byte(fd:read(4), 1, 4)
	return bor(lshift(b1, 21), lshift(b2, 14), lshift(b3, 7), b4)
end

local function distinct(array)
	local distinct_hash = {}
	for _, value in ipairs(array) do
		distinct_hash[value] = true
	end
	local distinct_array = {}
	for key, _ in pairs(distinct_hash) do
		table.insert(distinct_array, key)
	end
	return distinct_array
end

local function sum(array)
	local array_sum = 0
	for _, value in ipairs(array) do
		array_sum = array_sum + value
	end
	return array_sum
end

-------------------------
-- P U B L I C   A P I --
-------------------------
function mpeg.new(file)
	local self = setmetatable({}, mpeg)
	self.file = file
	self.fd = assert(nixio.open(file, "r"))
	self.size = self.fd:stat("size")
	return self
end

function mpeg.read(self)
	local header, b1, b2, b3, b4 = {}, read_byte(self.fd, 4)
	if string.char(b1, b2, b3) == "ID3" then
		local id3_version_major, id3_version_minor, id3_flags = b4, read_byte(self.fd, 2)
		self.fd:seek(read_synchsafe_int(self.fd), "cur")
		b1, b2, b3, b4 = read_byte(self.fd, 4)
	end
	while self.fd:tell() < self.size do
		local header_bytes = bor(lshift(b1, 24), lshift(b2, 16), lshift(b3, 8), b4)
		local frame_sync = read_bit(header_bytes, 1, 11)
		local version = read_bit(header_bytes, 12, 13)
		local layer = read_bit(header_bytes, 14, 15)
		local protected = read_bit(header_bytes, 16)
		local bitrate = read_bit(header_bytes, 17, 20)
		local sample_rate = read_bit(header_bytes, 21, 22)
		local padding = read_bit(header_bytes, 23)
		local private = read_bit(header_bytes, 24)
		local channel_mode = read_bit(header_bytes, 25, 26)
		local mode_extension = read_bit(header_bytes, 27, 28)
		local copyright = read_bit(header_bytes, 29)
		local original = read_bit(header_bytes, 30)
		local emphasis = read_bit(header_bytes, 31, 32)

		if frame_sync == 0x7ff and version ~= 1 and layer ~= 0
		and bitrate ~= 0xf and bitrate ~= 0 and sample_rate ~= 3 then
			if next(header) == nil then
				header.version = VERSION[version]
				header.layer = LAYER[layer]
				header.sample_rate = SAMPLE_RATE[version][sample_rate]
				header.channel_mode = CHANNEL_MODE[channel_mode]
				header.bitrate_type = "vbr"
				header.bitrates = {}
			end
			header.bitrate = BITRATE[version][layer][bitrate]
			table.insert(header.bitrates, header.bitrate)

			if #header.bitrates == SAME_BITRATE_FRAMES_TO_ASSUME_CBR
			and #distinct(header.bitrates) == 1 then
				header.bitrate_type = "cbr"
				break
			end

			local slot_size, frame_size = header.bitrate * 1000 / header.sample_rate, 0
			if header.layer == "layer I" then
				frame_size = 4 * (12 * slot_size + padding)
			elseif header.layer == "layer III" 
			and (header.version == "v2" or header.version == "v2.5") then
				frame_size = 72 * slot_size + padding
			elseif header.layer == "layer II" or header.layer == "layer III" then
				frame_size = 144 * slot_size + padding
			end
			self.fd:seek(math.floor(frame_size - 4), "cur")
			b1, b2, b3, b4 = read_byte(self.fd, 4)
		else
			log.warn("mpeg frame not on boundary: "
				.. self.fd:tell() .. " (" .. self.file .. ")")
			b1, b2, b3, b4 = b2, b3, b4, read_byte(self.fd)
		end
	end
	self.fd:close()
	if header.bitrate_type == "vbr" then
		header.bitrate = math.floor(sum(header.bitrates) / #header.bitrates)
	end
	header.bitrates = nil
	return header
end

return mpeg

