NAME = subsonic-lua

.PHONY: control

.EXPORT_ALL_VARIABLES:

all: test

test-remove:
	rm -fr /usr/lib/lua/subsonic
	rm -f /www/cgi-bin/subsonic

test-deploy: test-remove
	cp -a src/usr/* /usr
	cp -a src/www/* /www
	ln -sf /usr/lib/lua/subsonic/update.lua /usr/local/bin/subsonic_update

test: test-deploy
	lua test/fs.lua
	lua test/xml.lua
	lua test/id3.lua
	lua test/mpeg.lua
	lua test/server.lua

