-- Copyright 2015-2017 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

local log = require "subsonic.log"
local rest = require "subsonic.rest"
local config = require "subsonic.config"
local response = require "subsonic.response"

module("subsonic.server", package.seeall)

function url_decode(url)
	return url:gsub("+", " "):gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
end

function get_query_string()
	local qs = {}
	for key, value in os.getenv("QUERY_STRING"):gmatch("([^&=]+)=([^&=]*)&?") do
		qs[url_decode(key)] = tostring(url_decode(value))
	end
	return qs
end

function run()
	log.open(config.get_log_file(), config.get_log_level())
	log.info("request: " .. os.getenv("REQUEST_URI"))
	local subsonic_method = os.getenv("PATH_INFO"):sub(7, -6)
	local method = subsonic_method:gsub("(%u)", function(s) return "_" .. s:lower() end)
	if rest[method] then
		local answer = rest[method](get_query_string()) or ""
		log.info("response: " .. answer)
		response.send_xml(answer)
	end
	log.close()
end

