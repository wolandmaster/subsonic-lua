-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

package.path = package.path .. ";./test/?.lua"

config = require "config_stub"

local nixio = require "nixio"
local nixiofs = require "nixio.fs"
local test = require "test"
local server = require "subsonic.server"
local response = require "subsonic.response"

local function test_server(method, query)
	config.set_log_file(os.tmpname())
	local stdout = io.output()
	local tmp = io.tmpfile()
	io.output(tmp)
	query = "u=user&p=enc:123456789a&v=1.2.0&c=android" .. (query or "")
	nixio.setenv("QUERY_STRING", query)
	nixio.setenv("REQUEST_URI", "/cgi-bin/subsonic/rest/"
		.. method .. ".view?" .. query)
	nixio.setenv("PATH_INFO", "/rest/" .. method .. ".view")
	server.run()
	tmp:seek("set", 0)
	local response = tmp:read("*all")
	tmp:close()
	io.output(stdout)
	return response
end

local function xml_200_ok(msg)
	local resp = '<?xml version="1.0" encoding="UTF-8"?>\r\n'
	.. '<subsonic-response status="ok" version="'
	.. response.subsonic_api_version() .. '">'
	.. (msg or "") .. '</subsonic-response>'
	return response.http_200_ok("application/xml",
		{ "Content-Length: " .. #resp }) .. resp
end

local function json_200_ok(msg)
	local msg = (msg  and msg ~= "") and "," .. msg or ""
	local resp = '{"subsonic-response":{"status":"ok","version":"'
	.. response.subsonic_api_version() .. '"' .. (msg or "") .. '}}'
	return response.http_200_ok("application/json",
		{ "Content-Length: " .. #resp }) .. resp
end

local function assert_equals(id, actual, expected)
	if not test.assert_equals(id, actual, expected) then
		print(test.cyan("log:") .. "\n"
			.. nixiofs.readfile(config.log_file()))
	end
	nixio.fs.remove(config.log_file())
end

-- ping.view
assert_equals("ping xml", test_server("ping"), xml_200_ok())
assert_equals("ping json", test_server("ping", "&f=json"), json_200_ok())

-- getLicense.view
assert_equals("get license xml", test_server("getLicense"),
	xml_200_ok('<license valid="true"/>'))
assert_equals("get license json", test_server("getLicense", "&f=json"),
	json_200_ok('"license":{"valid":true}'))

-- getMusicFolders.view
config.set_music_folders({
	{ name = 'Music', enabled = '1' },
	{ name = 'Video', enabled = '1' },
	{ name = 'Dummy', enabled = '0' }
})
assert_equals("get music folders xml", test_server("getMusicFolders"),
	xml_200_ok('<musicFolders>'
	.. '<musicFolder id="1" name="Music"/>'
	.. '<musicFolder id="2" name="Video"/>'
	.. '</musicFolders>'))
assert_equals("get music folders json",
	test_server("getMusicFolders", "&f=json"), json_200_ok('"musicFolders":{'
	.. '"musicFolder":[{"id":1,"name":"Music"},{"id":2,"name":"Video"}]}'))

-- getIndexes.view?ifModifiedSince=0&musicFolderId=1
config.set_db('test/resources/subsonic.db')
config.set_music_folders({
	{ name = 'Music', enabled = '1' }
})
config.set_log_level("debug")
assert_equals("get indexes xml", test_server("getIndexes", "&musicFolderId=1"),
	xml_200_ok('<indexes lastModified="1555571361">'
	.. '<index name="A">'
	.. '<artist id="1" name="Artist"/></index>'
	.. '<child contentType="audio/mpeg" coverArt="0" id="1" isDir="false"'
	.. ' parent="0" path="Song1.mp3" size="0" suffix="mp3" title="Song1"/>'
	.. '</indexes>'))
assert_equals("get indexes json", test_server("getIndexes",
	"&musicFolderId=1&f=json"), json_200_ok('"indexes":{'
	.. '"lastModified":1555571361,"index":[{"name":"A","artist":[{"id":"1",'
	.. '"name":"Artist"}]}],"child":[{"contentType":"audio/mpeg",'
	.. '"coverArt":"0","id":"1","isDir":false,"parent":"0","path":"Song1.mp3",'
	.. '"size":0,"suffix":"mp3","title":"Song1"}]}'))

-- getMusicDirectory.view?id=1
config.set_db('test/resources/subsonic.db')
config.set_music_folders({ { name = 'Music', enabled = '1' } })
assert_equals("get music directory xml 1", test_server("getMusicDirectory",
	"&id=3"), xml_200_ok('<directory id="3" name="CD1" parent="2">'
	.. '<child contentType="audio/mpeg" coverArt="3" id="3" isDir="false"'
	.. ' parent="3" path="Artist/Album/CD1/Song4.mp3" size="0" suffix="mp3"'
	.. ' title="Song4"/></directory>'))
assert_equals("get music directory xml 2", test_server("getMusicDirectory",
	"&id=1"), xml_200_ok('<directory id="1" name="Artist" parent="0">'
	.. '<child album="Album" artist="Artist" coverArt="2" id="2" isDir="true"'
	.. ' parent="1" title="Album"/>'
	.. '<child contentType="audio/mpeg" coverArt="1" id="4" isDir="false"'
	.. ' parent="1" path="Artist/Song2.mp3" size="0" suffix="mp3"'
	.. ' title="Song2"/>'
	.. '</directory>'))


-- nixio.setenv("SERVER_SOFTWARE", "uhttpd")
-- config.set_db('test/resources/subsonic.db')
-- config.set_music_folders({ { name = 'Music', enabled = '1',
	-- path = 'test/media' } })
-- config.set_log_level("debug")
-- assert_equals("1", test_server("stream", "&id=1&c=musicstash&f=json"), "")

