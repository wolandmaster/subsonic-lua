-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

-- Only supports ID3v2.3 and ID3v2.4 tags!

local nixio = require "nixio"
local log = require "subsonic.log"

local bor = nixio.bit.bor
local band = nixio.bit.band
local lshift = nixio.bit.lshift
local rshift = nixio.bit.rshift

local ENCODING = { ISO_8859_1 = 0, UTF_16 = 1, UTF_16BE = 2, UTF_8 = 3 }
local GENRE = { [0] = "Blues", "Classic Rock", "Country", "Dance", "Disco", "Funk",
	"Grunge", "Hip-Hop", "Jazz", "Metal", "New Age", "Oldies", "Other", "Pop", "R&B",
	"Rap", "Reggae", "Rock", "Techno", "Industrial", "Alternative", "Ska", "Death Metal",
	"Pranks", "Soundtrack", "Euro-Techno", "Ambient", "Trip-Hop", "Vocal", "Jazz+Funk",
	"Fusion", "Trance", "Classical", "Instrumental", "Acid", "House", "Game", "Sound Clip",
	"Gospel", "Noise", "AlternRock", "Bass", "Soul", "Punk", "Space", "Meditative",
	"Instrumental Pop", "Instrumental Rock", "Ethnic", "Gothic", "Darkwave",
	"Techno-Industrial", "Electronic", "Pop-Folk", "Eurodance", "Dream", "Southern Rock",
	"Comedy", "Cult", "Gangsta", "Top 40", "Christian Rap", "Pop/Funk", "Jungle",
	"Native American", "Cabaret", "New Wave", "Psychadelic", "Rave", "Showtunes", "Trailer", 
	"Lo-Fi", "Tribal", "Acid Punk", "Acid Jazz", "Polka", "Retro", "Musical", "Rock & Roll", 
	"Hard Rock", "Folk", "Folk-Rock", "National Folk", "Swing", "Fast Fusion", "Bebob",
	"Latin", "Revival", "Celtic", "Bluegrass", "Avantgarde", "Gothic Rock", "Progressive Rock", 
	"Psychedelic Rock", "Symphonic Rock", "Slow Rock", "Big Band", "Chorus", "Easy Listening", 
	"Acoustic", "Humour", "Speech", "Chanson", "Opera", "Chamber Music", "Sonata", "Symphony", 
	"Booty Bass", "Primus", "Porn Groove", "Satire", "Slow Jam", "Club", "Tango", "Samba", 
	"Folklore", "Ballad", "Power Ballad", "Rhythmic Soul", "Freestyle", "Duet", "Punk Rock",
	"Drum Solo", "Acapella", "Euro-House", "Dance Hall" }

local id3 = {}
id3.__index = id3

setmetatable(id3, {
	__call = function (cls, ...)
		return cls.new(...)
	end,
})

getmetatable("").__mod = function(str, values)
	return type(values) == "table" and str:format(unpack(values)) or str:format(values)
end

function id3.new(file)
	local self = setmetatable({}, id3)
	self.fd = assert(nixio.open(file, "r"))
	self.file = file
	self.frames = {}
	return self
end

function id3.read(self)
	if self.fd:seek(0, "set") and self.fd:read(3) == "ID3" then
		self:parse_v2()
	elseif self.fd:seek(-128, "end") and self.fd:read(3) == "TAG" then
		self:parse_v1()
	end
	self.fd:close()
	return self.frames
end

function id3.parse_v1(self)
	self.frames = {
		TIT2 = read_string(self.fd, 30),
		TPE2 = self.fd:seek(-95, "end") and read_string(self.fd, 30),
		TALB = self.fd:seek(-65, "end") and read_string(self.fd, 30),
		TDRC = self.fd:seek(-35, "end") and tonumber(read_string(self.fd, 4)),
		COMM = { comment = self.fd:seek(-31, "end") and read_string(self.fd, 30) },
		TCON = self.fd:seek(-1, "end") and GENRE[read_byte(self.fd)]
	}
    self.fd:seek(-3, "end") 
	local zero, track = read_two_byte(self.fd, "be")
	if zero == 0 and track ~= 0 then
		self.frames[".version"] = "ID3v1.1"
		self.frames.TRCK = track
	else
		self.frames[".version"] = "ID3v1"
	end
end

function id3.parse_v2(self)
	local version_major, version_minor = read_byte(self.fd), read_byte(self.fd)
	if version_major ~= 3 and version_major ~= 4 then
		log.warn("Not supported id3 format in file: " .. self.file)
		return
	end
	local unsync, extended_header, experimental, footer = read_flags(self.fd)
	local size = read_synchsafe_int(self.fd)
	local start = self.fd:tell()
	self.frames[".version"] = "ID3v2.%d.%d" % { version_major, version_minor }
	while self.fd:tell() < size + start - (footer or 0) do
		local id, value = read_frame(self.fd, version_major)
		if not id then return end
		if value then
			if self.frames[id] then
				merge(self.frames[id], value)
			else
				self.frames[id] = value
			end
		end
	end
end

-- P R I V A T E --

function read_byte(fd)
	return string.byte(fd:read(1))
end

function read_two_byte(fd, endian)
	local first_byte, second_byte = read_byte(fd), read_byte(fd)
	if endian == "le" then
		return second_byte, first_byte
	elseif endian == "be" then
		return first_byte, second_byte
	end
end

function read_flags(fd)
	local byte, flags = read_byte(fd), {}
 	for bit = 7, 0, -1 do
		table.insert(flags, nixio.bit.band(byte, nixio.bit.lshift(1, bit)) ~= 0)
	end
	return unpack(flags)
end

function read_int(fd)
	local b1, b2, b3, b4 = string.byte(fd:read(4), 1, 4)
	return bor(lshift(b1, 24), lshift(b2, 16), lshift(b3, 8), b4)
end

function read_synchsafe_int(fd)
	local b1, b2, b3, b4 = string.byte(fd:read(4), 1, 4)
	return bor(lshift(b1, 21), lshift(b2, 14), lshift(b3, 7), b4)
end

function read_char(fd, encoding, endian)
	if encoding == ENCODING.ISO_8859_1 or encoding == ENCODING.UTF_8 then
		local chr = fd:read(1)
		if string.byte(chr) >= 0xf0 then chr = chr .. fd:read(3)
		elseif string.byte(chr) >= 0xe0 then chr = chr .. fd:read(2)
		elseif string.byte(chr) >= 0xc0 then chr = chr .. fd:read(1)
		end
		return chr
	elseif encoding == ENCODING.UTF_16 or encoding == ENCODING.UTF_16BE then
		return codepoint_to_utf8(read_utf16_codepoint(fd, endian))
	end
end

function read_utf16_bom(fd)
	local bom_high, bom_low = read_byte(fd), read_byte(fd)
	if bom_high == 0xff and bom_low == 0xfe then
		return "le"
	elseif bom_high == 0xfe and bom_low == 0xff then
		return "be"
	end
end

function read_utf16_codepoint(fd, endian)
	local high_byte, low_byte, codepoint = read_two_byte(fd, endian)
	if high_byte >= 0xd8 and high_byte <= 0xdf then
		codepoint = lshift(bor(lshift(band(high_byte, 0x27), 8), band(low_byte, 0xff)), 10)
		local high_byte, low_byte = read_two_byte(fd, endian)
		codepoint = bor(codepoint, lshift(band(high_byte, 0x23), 8), band(low_byte, 0xff)) + 0x10000
	else
		codepoint = bor(lshift(high_byte, 8), low_byte)
	end
	return codepoint
end

function read_string(fd, max_size, encoding)
	encoding = encoding or ENCODING.ISO_8859_1
	local start, str = fd:tell(), {}
	local endian = (encoding == ENCODING.UTF_16 or encoding == ENCODING.UTF_16BE) and read_utf16_bom(fd)
	repeat
		local chr = read_char(fd, encoding, endian)
		if chr ~= "\0" then table.insert(str, chr) end
	until chr == "\0" or fd:tell() == start + max_size
	return table.concat(str)
end

function read_frame(fd, version_major)
	local id, value = fd:read(4)
	if id:sub(1, 1) == "\0" then return nil end
	local size = (version_major == 4) and read_synchsafe_int(fd) or read_int(fd)
	local tag_preservation, file_preservation, read_only = read_flags(fd)
	local compression, encryption, grouping = read_flags(fd)
	local start = fd:tell()
	if id == "TXXX" then
		local encoding = read_byte(fd)
		local description = read_string(fd, start - fd:tell() + size, encoding)
		local text = read_string(fd, start - fd:tell() + size, encoding)
		value = { [description] = { text = text } }
	elseif id:sub(1, 1) == "T" then
		local encoding = read_byte(fd)
		value = read_string(fd, start - fd:tell() + size, encoding)
		if id == "TCON" then
			value = value:gsub("%((%d+)%)", function(genre_id)
				return GENRE[tonumber(genre_id)] .. " "
			end):gsub("%s*$", "")
		end
	elseif id == "WXXX" then
		local encoding = read_byte(fd)
		local description = read_string(fd, start - fd:tell() + size, encoding)
		local url = read_string(fd, start - fd:tell() + size)
		value = { [description] = { url = url } }
	elseif id:sub(1, 1) == "W" then
		value = read_string(fd, start - fd:tell() + size)
	elseif id == "COMM" then
		local encoding = read_byte(fd)
		local language = fd:read(3):gsub("%z", "")
		local description = read_string(fd, start - fd:tell() + size, encoding)
		local comment = read_string(fd, start - fd:tell() + size, encoding)
		value = { [language .. description] = { comment = comment } }
	elseif id == "APIC" then
		local encoding = read_byte(fd)
		local mime_type = read_string(fd, start - fd:tell() + size - 2)
		local picture_type = read_byte(fd)
		local description = read_string(fd, start - fd:tell() + size, encoding)
		local picture_data = fd:read(start - fd:tell() + size)
		value = { [picture_type] = { mime_type = mime_type, description = description, 
			picture_data = picture_data } }
	else
		fd:seek(size, "cur")
		-- not yet supported
	end
	return id, value
end

function codepoint_to_utf8(codepoint)
	local bytes = {}
	if codepoint < 0x80 then
		table.insert(bytes, codepoint)
	elseif codepoint < 0x800 then
		table.insert(bytes, bor(band(rshift(codepoint, 6), 0x1f), 0xc0))
		table.insert(bytes, bor(band(codepoint, 0x3f), 0x80))
	elseif codepoint < 0x10000 then
		table.insert(bytes, bor(band(rshift(codepoint, 12), 0x0f), 0xe0))
		table.insert(bytes, bor(band(rshift(codepoint, 6), 0x3f), 0x80))
		table.insert(bytes, bor(band(codepoint, 0x3f), 0x80))
	elseif codepoint < 0x110000 then
		table.insert(bytes, bor(band(rshift(codepoint, 18), 0x07), 0xf0))
		table.insert(bytes, bor(band(rshift(codepoint, 12), 0x3f), 0x80))
		table.insert(bytes, bor(band(rshift(codepoint, 6), 0x3f), 0x80))
		table.insert(bytes, bor(band(codepoint, 0x3f), 0x80))
	end
	return string.char(unpack(bytes))
end

function merge(base_table, other_table)
	for key, value in pairs(other_table) do
		base_table[key] = value
	end
end

return id3

