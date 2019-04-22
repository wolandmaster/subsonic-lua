-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

package.path = package.path .. ";./test/?.lua"

local nixio = require "nixio"
local nixiofs = require "nixio.fs"
local test = require "test"

config = require "config_stub"
local server = require "subsonic.server"

function test_server(method, query)
	config.set_log_file(os.tmpname())
	local stdout = io.output()
	local tmp = io.tmpfile()
	io.output(tmp)
	query = "u=user&p=enc:123456789a&v=1.2.0&c=android" .. (query or "")
	nixio.setenv("QUERY_STRING", query)
	nixio.setenv("REQUEST_URI", "/cgi-bin/subsonic/rest/" .. method .. ".view?" .. query)
	nixio.setenv("PATH_INFO", "/rest/" .. method .. ".view")
	server.run()
	tmp:seek("set", 0)
	local response = tmp:read("*all")
	tmp:close()
	io.output(stdout)
	return response
end

function xml_200_ok(msg)
	return 'Status: 200 OK\r\n'
	.. 'Content-Type: application/xml\r\n\r\n'
	.. '<?xml version="1.0" encoding="UTF-8"?>\r\n'
	.. '<subsonic-response status="ok" version="1.14.0">'
	.. (msg or "") .. '</subsonic-response>'
end

function assert_equals(id, actual, expected)
	if not test.assert_equals(id, actual, expected) then
		print(test.cyan("log:") .. "\n" .. nixiofs.readfile(config.log_file()))
	end
	nixio.fs.remove(config.log_file())
end

-- ping.view?u=user&p=enc:123456789a&v=1.2.0&c=android
assert_equals("ping", test_server("ping"), xml_200_ok())

-- getLicense.view?u=user&p=enc:123456789a&v=1.2.0&c=android
assert_equals("get license", test_server("getLicense"), xml_200_ok('<license valid="true"/>'))

-- getMusicFolders.view?u=user&p=enc:123456789a&v=1.2.0&c=android
config.set_music_folders({
	{ name = 'Music', enabled = '1' },
	{ name = 'Video', enabled = '1' },
	{ name = 'Dummy', enabled = '0' }
})
assert_equals("get music folders", test_server("getMusicFolders"),
	xml_200_ok('<musicFolders>'
	.. '<musicFolder id="1" name="Music"/>'
	.. '<musicFolder id="2" name="Video"/>'
	.. '</musicFolders>'))

-- getIndexes.view?u=user&p=enc:123456789a&v=1.2.0&c=android&ifModifiedSince=0&musicFolderId=1
config.set_db('test/resources/subsonic.db')
config.set_music_folders({
	{ name = 'Music', enabled = '1' }
})
assert_equals("get indexes", test_server("getIndexes", "&musicFolderId=1"),
	xml_200_ok('<indexes lastModified="1555571361">'
	.. '<index name="A">'
	.. '<artist id="1" name="Artist"/></index>'
	.. '<child contentType="audio/mpeg" id="1" isDir="false" parent="0" path="Song1.mp3"'
	.. ' size="0" suffix="mp3" title="Song1"/>'
	.. '</indexes>'))

-- getMusicDirectory.view?u=user&p=enc:123456789a&v=1.2.0&c=android&id=1
config.set_music_folders({ { name = 'Music', enabled = '1' } })
config.set_db('test/resources/subsonic.db')
assert_equals("get music directory 1", test_server("getMusicDirectory", "&id=3"),
	xml_200_ok('<directory id="3" name="CD1" parent="2">'
	.. '<child contentType="audio/mpeg" id="3" isDir="false" parent="3"'
	.. ' path="Artist/Album/CD1/Song4.mp3" size="0" suffix="mp3" title="Song4"/>'
	.. '</directory>'))
assert_equals("get music directory 2", test_server("getMusicDirectory", "&id=1"),
	xml_200_ok('<directory id="1" name="Artist" parent="0">'
	.. '<child artist="Artist" id="2" isDir="true" parent="1" title="Album"/>'
	.. '<child contentType="audio/mpeg" id="4" isDir="false" parent="1"'
	.. ' path="Artist/Song2.mp3" size="0" suffix="mp3" title="Song2"/>'
	.. '</directory>'))

-- config.set_db('test/resources/subsonic-id3.db')
-- config.set_music_folders({ { name = 'Music', enabled = '1' } })
-- assert_equals("get music directory 2", test_server("getMusicDirectory", "&id=3"),
--	xml_200_ok('<directory id="3" name="CD1" parent="2">'
--	.. '<child album="Album-ID3" artist="Artist-ID3" bitRate="128" contentType="audio/mpeg" '
--	.. 'coverArt="1" duration="1" genre="Other" id="2" isDir="false" parent="3" '
--	.. 'path="Artist/Album/CD1/Song4.mp3" size="1234" suffix="mp3" title="Song4-ID3" track="1" year="1982"/>'
--	.. '</directory>'))

