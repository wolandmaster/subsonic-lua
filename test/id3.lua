-- Copyright 2015-2017 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

package.path = package.path .. ";./test/?.lua"

local id3 = require "subsonic.id3"
local test = require "test"

local fd = test.open("test/resources/utf16be")
test.assert_equals(test.binary(read_utf16_codepoint(fd, "be")), test.binary(410401))
test.assert_equals(test.binary(read_utf16_codepoint(fd, "be")), test.binary(66376))
test.assert_equals(test.binary(read_utf16_codepoint(fd, "be")), test.binary(24935))
test.assert_equals(test.binary(read_utf16_codepoint(fd, "be")), test.binary(32431))
test.assert_equals(test.binary(read_utf16_codepoint(fd, "be")), test.binary(97))
test.assert_equals(test.binary(read_utf16_codepoint(fd, "be")), test.binary(122))
fd:close()

local fd = test.open("test/resources/utf16le")
test.assert_equals(test.binary(read_utf16_codepoint(fd, "le")), test.binary(410401))
test.assert_equals(test.binary(read_utf16_codepoint(fd, "le")), test.binary(66376))
test.assert_equals(test.binary(read_utf16_codepoint(fd, "le")), test.binary(24935))
test.assert_equals(test.binary(read_utf16_codepoint(fd, "le")), test.binary(32431))
test.assert_equals(test.binary(read_utf16_codepoint(fd, "le")), test.binary(97))
test.assert_equals(test.binary(read_utf16_codepoint(fd, "le")), test.binary(122))
fd:close()

test.assert_equals(test.binary(string.byte(codepoint_to_utf8(98))), test.binary(98))
test.assert_equals(test.binary(string.byte(codepoint_to_utf8(336), 1, 2)), test.binary(197, 144))
test.assert_equals(test.binary(string.byte(codepoint_to_utf8(2401), 1, 3)), test.binary(224, 165, 161))
test.assert_equals(test.binary(string.byte(codepoint_to_utf8(65541), 1, 4)), test.binary(240, 144, 128, 133))

local id3v23_utf16 = id3("test/resources/id3v2.3_utf16"):read()
test.assert_equals(id3v23_utf16.TPE1, "Artist")
test.assert_equals(id3v23_utf16.COMM["eng"].comment, "Comment")
test.assert_equals(id3v23_utf16.APIC[3].mime_type, "image/png")

local id3v24_utf8 = id3("test/resources/id3v2.4_utf8"):read()
test.assert_equals(id3v24_utf8.TIT2, "Title")
test.assert_equals(id3v24_utf8.WXXX[""].url, "URL")
test.assert_equals(id3v24_utf8.APIC[3].mime_type, "image/jpeg")

local id3v24_utf16 = id3("test/resources/id3v2.4_utf16"):read()
test.assert_equals(id3v24_utf16.TALB, "Album")
test.assert_equals(id3v24_utf16.TPOS, "1")

local id3v24_iso88591 = id3("test/resources/id3v2.4_iso8859-1"):read()
test.assert_equals(id3v24_iso88591.TRCK, "01/02")
test.assert_equals(id3v24_iso88591.TCON, "Meditative Death Metal")

local id3v11 = id3("test/resources/id3v1.1"):read()
test.assert_equals(id3v11.TIT2, "Title")
test.assert_equals(id3v11.TPE2, "Artist")
test.assert_equals(id3v11.TALB, "Album")
test.assert_equals(id3v11.TDRC, 2000)
test.assert_equals(id3v11.COMM.comment, "Comment")
test.assert_equals(id3v11.TRCK, 1)
test.assert_equals(id3v11.TCON, "Metal")

