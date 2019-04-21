-- Copyright 2015-2017 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

require "subsonic.table"
require "subsonic.string"

local nixio = require "nixio"

local os, table, tostring, type = os, table, tostring, type

module "subsonic.log"

local LEVEL = { ["error"] = 1, ["warn"] = 2,
	["info"] = 3, ["debug"] = 4, ["trace"] = 5 }

local fh
local level

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
	if LEVEL[loglevel] <= LEVEL[level] then
		fh:lock("lock")		
		fh:write(os.date("%Y-%m-%d %H:%M:%S ")
			.. ("%-6s"):format(loglevel)
			.. table.concat(table.map({...}, function(value)
				return type(value) ~= "table" and tostring(value)
					or table.dump(value)
			end), " "):trim() .. "\n")
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

