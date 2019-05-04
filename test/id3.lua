-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

package.path = package.path .. ";./test/?.lua"

local id3 = require "subsonic.id3"
local test = require "test"

local fd = test.open("test/resources/utf16be")
test.assert_equals("utf16be 410401",
	test.binary(read_utf16_codepoint(fd, "be")), test.binary(410401))
test.assert_equals("utf16be 66376",
	test.binary(read_utf16_codepoint(fd, "be")), test.binary(66376))
test.assert_equals("utf16be 24935",
	test.binary(read_utf16_codepoint(fd, "be")), test.binary(24935))
test.assert_equals("utf16be 32431",
	test.binary(read_utf16_codepoint(fd, "be")), test.binary(32431))
test.assert_equals("utf16be 97",
	test.binary(read_utf16_codepoint(fd, "be")), test.binary(97))
test.assert_equals("utf16be 122",
	test.binary(read_utf16_codepoint(fd, "be")), test.binary(122))
fd:close()

local fd = test.open("test/resources/utf16le")
test.assert_equals("utf16le 410401",
	test.binary(read_utf16_codepoint(fd, "le")), test.binary(410401))
test.assert_equals("utf16le 66376",
	test.binary(read_utf16_codepoint(fd, "le")), test.binary(66376))
test.assert_equals("utf16le 24935",
	test.binary(read_utf16_codepoint(fd, "le")), test.binary(24935))
test.assert_equals("utf16le 32431",
	test.binary(read_utf16_codepoint(fd, "le")), test.binary(32431))
test.assert_equals("utf16le 97",
	test.binary(read_utf16_codepoint(fd, "le")), test.binary(97))
test.assert_equals("utf16le 122",
	test.binary(read_utf16_codepoint(fd, "le")), test.binary(122))
fd:close()

test.assert_equals("utf8 98",
	test.binary(string.byte(codepoint_to_utf8(98))), test.binary(98))
test.assert_equals("utf8 336",
	test.binary(string.byte(codepoint_to_utf8(336), 1, 2)),
	test.binary(197, 144))
test.assert_equals("utf8 2401",
	test.binary(string.byte(codepoint_to_utf8(2401), 1, 3)),
	test.binary(224, 165, 161))
test.assert_equals("utf8 65541",
	test.binary(string.byte(codepoint_to_utf8(65541), 1, 4)),
	test.binary(240, 144, 128, 133))

local id3v23_utf16 = id3("test/resources/id3v2.3_utf16"):read()
test.assert_equals("id3v2.3 utf16 tpe1", id3v23_utf16.TPE1, "Artist")
test.assert_equals("id3v2.3 utf16 comm",
	id3v23_utf16.COMM["eng"].comment, "Comment")
test.assert_equals("id3v2.3 utf16 apic",
	id3v23_utf16.APIC[3].mime_type, "image/png")

local id3v24_utf8 = id3("test/resources/id3v2.4_utf8"):read()
test.assert_equals("id3v2.4 utf8 tit2", id3v24_utf8.TIT2, "Title")
test.assert_equals("id3v2.4 utf8 wxxx", id3v24_utf8.WXXX[""].url, "URL")
test.assert_equals("id3v2.4 utf8 apic",
	id3v24_utf8.APIC[3].mime_type, "image/jpeg")

local id3v24_utf16 = id3("test/resources/id3v2.4_utf16"):read()
test.assert_equals("id3v2.4 utf16 talb", id3v24_utf16.TALB, "Album")
test.assert_equals("id3v2.4 utf16 tpos", id3v24_utf16.TPOS, "1")

local id3v24_iso88591 = id3("test/resources/id3v2.4_iso8859-1"):read()
test.assert_equals("id3v2.4 iso8859-1 trck", id3v24_iso88591.TRCK, "01/02")
test.assert_equals("id3v2.4 iso8859-1 tcon",
	id3v24_iso88591.TCON, "Meditative Death Metal")

local id3v11 = id3("test/resources/id3v1.1"):read()
test.assert_equals("id3v1.1 tit2", id3v11.TIT2, "Title")
test.assert_equals("id3v1.1 tpe2", id3v11.TPE2, "Artist")
test.assert_equals("id3v1.1 talb", id3v11.TALB, "Album")
test.assert_equals("id3v1.1 tdrc", id3v11.TDRC, 2000)
test.assert_equals("id3v1.1 comm", id3v11.COMM.comment, "Comment")
test.assert_equals("id3v1.1 trck", id3v11.TRCK, 1)
test.assert_equals("id3v1.1 tcon", id3v11.TCON, "Metal")

