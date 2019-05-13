-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

-- http://stackoverflow.com/a/12401713
-- https://github.com/LuaDist/luasql-sqlite3/blob/master/tests/example.lua
-- https://realtimelogic.com/ba/doc/en/lua/luasql.html
-- https://keplerproject.github.io/luasql/manual.html

require "subsonic.string"
require "subsonic.table"

local log = require "subsonic.log"
local fs = require "subsonic.fs"
local driver = require "luasql.sqlite3"

local db = {}
db.__index = db

setmetatable(db, {
	__call = function (cls, ...)
		return cls.new(...)
	end,
})

getmetatable("").__mod = function(str, values)
	return type(values) == "table"
		and str:format(unpack(values)) or str:format(values)
end

local function escape(self, value)
	if type(value) == "table" then
		local escaped_value = {}
		for _, value in ipairs(value) do
			table.insert(escaped_value, self:escape(value))
		end
		return escaped_value
	elseif type(value) == "string" and value ~= "null" then
		return value:has_unprintable()
			and "X'" .. value:tohex() .. "'"
			or "'" .. self.conn:escape(value) .. "'"
	else
		return value
	end
end

local function ellipsize_blob(str)
	return (str:gsub("(X'%w%w%w%w)%w+(%w%w%w%w')", "%1..%2"))
end

-------------------------
-- P U B L I C   A P I --
-------------------------
function db.new(sqlite)
	local self = setmetatable({}, db)
	log.debug("open db:", sqlite)
	self.env = assert(driver.sqlite3())
	self.conn = assert(self.env:connect(sqlite))
	return self
end

function db.execute(self, sql, filters)
	if sql:find("\n") then sql = "\n" .. sql end
	if sql:find("select") or sql:find("delete") or sql:find("update") then
		sql = sql .. self:build_filters(filters or {})
	end
	sql = sql:replace_except_first(" where ", " and ")
	log.debug("sql execute:", ellipsize_blob(sql))
	return assert(self.conn:execute(sql))
end

function db.rows(self, sql, filters)
	local cursor = self:execute(sql, filters)
	return function()
		return cursor:fetch()
	end
end

function db.query_first(self, sql, filters)
	local cursor = self:execute(sql, filters)
	local row = cursor:fetch({}, "a")
	log.debug("sql query row:", row or "nil")
	cursor:close()
	return row
end

function db.query(self, sql, filters)
	local rows = {}
	local cursor = self:execute(sql, filters)
	local row = cursor:fetch({}, "a")
	while row do
		table.insert(rows, row)
		log.debug("sql query row:", row)
		row = cursor:fetch({}, "a")
	end
	cursor:close()
	return rows
end

function db.insert(self, table_name, values)
	local column_list, value_list = {}, {}
	for column, value in pairs(values) do
		table.insert(column_list, column)
		table.insert(value_list, escape(self, value))
	end
	self:execute("\tinsert into %s (%s)\n\tvalues (%s)" % {
		table_name,
		table.concat(column_list, ", "),
		table.concat(value_list, ", ")
	})
	local cursor = self:execute("select * from " .. table_name
		.. " where id = last_insert_rowid()")
	local last_row = cursor:fetch({}, "a")
	log.debug("sql last inserted row:", last_row)
	cursor:close()
	return last_row
end

function db.update(self, table_name, values, filters)
	local updates = {}
	for column, value in pairs(values) do
		table.insert(updates, column .. " = " .. escape(self, value))
	end
	self:execute("update %s set %s" % {
		table_name,
		table.concat(updates, ", ")
	}, filters)
end

function db.dump(self, table_name)
	return table.dump(self:query("select * from " .. table_name))
end

function db.close(self)
	log.debug("close db")
	self.conn:close()
	return self.env:close()
end

function db.build_filters(self, filters)
	local sql = ""
	for column, value in pairs(filters) do
		sql = sql .. " where " .. column
		if type(value) == "table" then
			if value[1]:starts("<") or value[1]:starts(">") then
				sql = sql .. " " .. value[1] .. " " .. escape(self, value[2])
			else
				sql = sql .. " in ("
				.. table.concat(escape(self, value), ", ") .. ")"
			end
		elseif value == "null" then
			sql = sql .. " is " .. value
		else
			sql = sql .. " = " .. escape(self, value)
		end
	end
	return sql
end

return db

