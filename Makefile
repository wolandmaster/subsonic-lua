NAME = subsonic-lua

.PHONY: control

test-remove:
	rm -fr /usr/lib/lua/subsonic
	rm -f /www/cgi-bin/subsonic

test-deploy: test-remove
	cp -a src/usr/* /usr
	cp -a src/www/* /www

test: test-deploy
	lua test/fs.lua
	lua test/xml.lua
	lua test/id3.lua
	lua test/mpeg.lua

