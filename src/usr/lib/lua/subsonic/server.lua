-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

local log = require "subsonic.log"
local rest = require "subsonic.rest"
local response = require "subsonic.response"
local config = config or require "subsonic.config"

module("subsonic.server", package.seeall)

local function url_decode(url)
	return url:gsub("+", " "):gsub("%%(%x%x)", function(h)
		return string.char(tonumber(h, 16)) end)
end

local function get_query_string()
	local qs = {}
	local query_string = os.getenv("QUERY_STRING")
	for key, value in query_string:gmatch("([^&=]+)=([^&=]*)&?") do
		qs[url_decode(key)] = tostring(url_decode(value))
	end
	return qs
end
	
-------------------------
-- P U B L I C   A P I --
-------------------------
function run()
	log.open(config.log_file(), config.log_level())
	log.info("request: " .. os.getenv("REQUEST_URI"))
	local subsonic_method = os.getenv("PATH_INFO"):gsub("%.view$", ""):sub(7)
	local method = subsonic_method:gsub("(%u)", function(s)
		return "_" .. s:lower() end)
	if rest[method] then
		rest[method](get_query_string())
	end
	log.close()
end

