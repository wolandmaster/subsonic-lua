-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

require "subsonic.table"
require "subsonic.string"

local nixio = require "nixio"
local socket = require "socket"

local os, table, tostring, type, math = os, table, tostring, type, math
local assert = assert

module "subsonic.log"

local LEVEL = { ["error"] = 1, ["warn"] = 2,
	["info"] = 3, ["debug"] = 4, ["trace"] = 5 }

local fh
local level

local function timestamp()
	local now = socket.gettime()
	local millis = tostring(("%.3f"):format(now))
		:gsub("(.*%.)(.*)", "%2")
	return os.date("%Y-%m-%d %H:%M:%S.", now) .. millis
end

function open(logfile, loglevel)
	fh = nixio.open(logfile, "a")
	level = loglevel or "info"
end

function close()
	fh:sync()
	fh:close()
end

function message(loglevel, ...)
	if fh == nil then
		open("/dev/tty", "info")
	end
	assert(LEVEL[level], "no such log level: " .. level)
	if LEVEL[loglevel] <= LEVEL[level] then
		fh:lock("lock")
		local time_stamp = timestamp() .. " " .. ("%-6s"):format(loglevel)
		local line_feed = "\n"
		local msg = table.concat(table.map({...}, function(value)
			if type(value) == "table" then
				return table.dump(value)
			elseif value == "!ts" then
				time_stamp = " "
				return ""
			elseif value == "!lf" then
				line_feed = ""
				return ""
			else
				return tostring(value)
			end
		end), " "):trim()
		fh:write(time_stamp .. msg .. line_feed)
		fh:sync()
		fh:lock("ulock")
	end
end

function trace(...)
	message("trace", ...)
end

function debug(...)
	message("debug", ...)
end

function info(...)
	message("info", ...)
end

function warn(...)
	message("warn", ...)
end

function error(...)
	message("error", ...)
end

