-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

package.path = package.path .. ";./test/?.lua"

local response = require "subsonic.response"
local test = require "test"

test.assert_equals("http 200 ok 1", response.http_200_ok("application/xml"),
	"Status: 200 OK\r\nAccess-Control-Allow-Origin: *\r\n"
	.. "Content-Type: application/xml\r\n\r\n")

test.assert_equals("http 200 ok 2", response.http_200_ok("application/xml",
	{ "Content-Length: 10" }), "Status: 200 OK\r\nAccess-Control-Allow-Origin: *\r\n"
	.. "Content-Type: application/xml\r\nContent-Length: 10\r\n\r\n")

test.assert_equals("http 200 ok 3", response.http_200_ok("application/xml",
	{ "Content-Length: 10", "Content-Encoding: gzip" }), "Status: 200 OK\r\n"
	.. "Access-Control-Allow-Origin: *\r\nContent-Type: application/xml\r\n"
	.. "Content-Length: 10\r\nContent-Encoding: gzip\r\n\r\n")

test.assert_equals("to xml 1", response.to_xml({ license = { valid = true } }),
	'<license valid="true"/>')

test.assert_equals("to xml 2", response.to_xml({ musicFolders = { 
	{ musicFolder = { id = "1", name = "Music" } },
	{ musicFolder = { id = "2", name = "Video" } }
	} }), '<musicFolders><musicFolder id="1" name="Music"/>'
	.. '<musicFolder id="2" name="Video"/></musicFolders>')

test.assert_equals("to xml 3", response.to_xml({ indexes = {
	lastModified = 1234, { index = { name = "A", { artist = { id = "1", name = "Artist" } } } }
	} }), '<indexes lastModified="1234"><index name="A"><artist id="1" name="Artist"/>'
	.. '</index></indexes>')

test.assert_equals("to xml 4", response.to_xml({ indexes = {
	{ shortcut = { id = "1" } }, { shortcut = { id = "2" } },
	{ index = { name = "A" } }, { index = { name = "B" } } } }),
	'<indexes><shortcut id="1"/><shortcut id="2"/><index name="A"/><index name="B"/></indexes>')

test.assert_equals("to json 1", response.to_json({ license = { valid = true } }),
	'"license":{"valid":true}')

test.assert_equals("to json 2", response.to_json({ musicFolders = { 
	{ musicFolder = { id = 1, name = "Music" } },
	{ musicFolder = { id = 2, name = "Video" } }
	} }), '"musicFolders":{"musicFolder":[{"id":1,"name":"Music"},'
	.. '{"id":2,"name":"Video"}]}')

test.assert_equals("to json 3", response.to_json({ indexes = {
	lastModified = 1234, { index = { name = "A", { artist = { id = "1", name = "Artist" } } } }
	} }), '"indexes":{"lastModified":1234,"index":[{"name":"A","artist":[{'
	.. '"id":"1","name":"Artist"}]}]}')

test.assert_equals("to json 4", response.to_json({ indexes = {
	{ shortcut = { id = "1" } }, { shortcut = { id = "2" } },
	{ index = { name = "A" } }, { index = { name = "B" } } } }),
	'"indexes":{"shortcut":[{"id":"1"},{"id":"2"}],"index":[{"name":"A"},{"name":"B"}]}')

