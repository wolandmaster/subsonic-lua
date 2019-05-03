-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

require "subsonic.table"

local nixio = require "nixio"
local nixiofs = require "nixio.fs"

local table, coroutine = table, coroutine

module "subsonic.fs"

function join_path(...)
	return (table.concat(table.ifilter({...}, function(value)
		return value ~= ""
	end), "/"):gsub("/+", "/"))
end

function basename(path)
	return path:gsub("(.*/)(.*)", "%2")
end

function dirname(path)
	return path:gsub("(.*)(/.*)", "%1")
end

function extension(path)
	return path:gsub("(.*%.)(.*)", "%2")
end

function no_extension(path)
	return path:gsub("(.*)(%..*)", "%1")
end

function path_type(path)
	return nixio.fs.stat(path, "type")
end

function is_dir(...)
	return path_type(join_path(...)) == "dir"
end

function is_file(...)
	return path_type(join_path(...)) == "reg"
end

function iterate_folder(base, path)
	local iter = nixio.fs.dir(join_path(base, path))
	return function()
		local entry = iter()
		return entry and join_path(path, entry)
	end
end

function dir(base, path)
	local entries = {}
	for entry in iterate_folder(base, path) do
		table.insert(entries, entry)
	end
	return sort_by_name(entries)
end

function iterate_files_recursive(path)
	local function walk(path)
		for entry in nixio.fs.dir(path) do
			local subpath = join_path(path, entry)
			if is_dir(subpath) then
				walk(subpath)
			else
				coroutine.yield(subpath)
			end
		end
	end
	return coroutine.wrap(function() walk(path) end)
end

function file_size(...)
	return nixio.fs.stat(join_path(...), "size")
end

function readfile(...)
	return nixiofs.readfile(join_path(...))
end

function inode(...)
	return nixio.fs.stat(join_path(...), "ino")
end

function last_modification(...)
	return nixio.fs.stat(join_path(...), "mtime")
end

function sort_by_name(entries)
	table.sort(entries)
	return entries
end

function sort_by_date(entries)
	table.sort(entries,
		function (left, right)
			return last_modification(left) > last_modification(right)
		end
	)
	return entries
end

function relative(path, base)
	return path:sub(join_path(base, "/"):len() + 1)
end

