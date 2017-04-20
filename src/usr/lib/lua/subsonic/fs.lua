-- Copyright 2015-2017 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

local nixio = require "nixio"

local table = table

module "subsonic.fs"

function join_path(...)
	return (table.concat({...}, "/"):gsub("/+", "/"))
end

function basename(path)
	return path:gsub("(.*/)(.*)", "%2")
end

function dirname(path)
	return path:gsub("(.*)(/.*)", "%1")
end

function suffix(path)
	return path:gsub("(.*%.)(.*)", "%2")
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

function iterate_folder(path)
	local iter = nixio.fs.dir(path)
	return function()
		local entry = iter()
		return entry and join_path(path, entry)
	end
end

function file_size(...)
	return nixio.fs.stat(join_path(...), "size")
end

function inode(path)
	return nixio.fs.stat(path, "ino")
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

