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

