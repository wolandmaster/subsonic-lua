-- Copyright 2015-2017 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

local nixio = require "nixio"

local os, tostring = os, tostring

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

function message(loglevel, msg)
	if LEVEL[loglevel] <= LEVEL[level] then
		fh:lock("lock")
		fh:write(os.date("%Y-%m-%d %H:%M:%S ")
			.. ("%-6s"):format(loglevel)
			.. tostring(msg):gsub("^%s*(.-)%s*$", "%1") .. "\n")
		fh:lock("ulock")
	end
end

function trace(msg)
	message("trace", msg)
end

function debug(msg)
	message("debug", msg)
end

function info(msg)
	message("info", msg)
end

function warn(msg)
	message("warn", msg)
end

function error(msg)
	message("error", msg)
end

