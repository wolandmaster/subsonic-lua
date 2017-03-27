-- Copyright 2015-2017 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

-- http://stackoverflow.com/a/12401713
-- https://github.com/LuaDist/luasql-sqlite3/blob/master/tests/example.lua
-- https://realtimelogic.com/ba/doc/en/lua/luasql.html
-- https://keplerproject.github.io/luasql/manual.html

local log = require "subsonic.log"
local driver = require "luasql.sqlite3"

local db = {}
db.__index = db

setmetatable(db, {
	__call = function (cls, ...)
		return cls.new(...)
	end,
})

getmetatable("").__mod = function(str, values)
	return type(values) == "table" and str:format(unpack(values)) or str:format(values)
end

function db.new(sqlite)
	local self = setmetatable({}, db)
	self.env = assert(driver.sqlite3())
	self.conn = assert(self.env:connect(sqlite))
	return self
end

function db.execute(self, sql, filters)
	if sql:find("\n") then sql = "\n" .. sql end
	if sql:find("select") or sql:find("delete") or sql:find("update") then
		sql = sql .. self:build_filters(filters or {})
	end
	log.debug("executing sql: " .. sql)
	return assert(self.conn:execute(sql))
end

function db.rows(self, sql, filters)
	local cursor = self:execute(sql, filters)
	return function()
		return cursor:fetch()
	end
end

function db.query(self, sql, filters)
	local rows = {}
	local cursor = self:execute(sql, filters)
	local row = cursor:fetch({}, "a")
	while row do
		table.insert(rows, row)
		row = cursor:fetch({}, "a")
	end
	return rows
end

function db.insert(self, table_name, values)
	local column_list, value_list = {}, {}
	for column, value in pairs(values) do
		table.insert(column_list, column)
		table.insert(value_list, self:escape(value))
	end
	self:execute("\tinsert into %s (%s)\n\tvalues (%s)" % { 
		table_name,
		table.concat(column_list, ", "),
		table.concat(value_list, ", ")
	})
end

function db.update(self, table_name, values, filters)
	local updates = {} 
	for column, value in pairs(values) do
		table.insert(updates, column .. " = " .. self:escape(value))
	end
	self:execute("update %s set %s" % {
		table_name,
		table.concat(updates, ", ")
	}, filters)
end

function db.close(self)
	self.conn:close()
	self.env:close()
end

function db.escape(self, values)
	if type(values) == "table" then
		local escaped_values = {}
		for _, value in ipairs(values) do
			table.insert(escaped_values, self:escape(value))
		end
		return escaped_values
	elseif type(values) == "string" and values ~= "null" then
		return "'" .. self.conn:escape(values) .. "'"
	else
		return values
	end
end

function db.build_filters(self, filters)
	local sql = ""
	for column, values in pairs(filters) do
		sql = sql .. (sql:find("where") and " and " or " where ") .. column
		if type(values) == "table" then
			sql = sql .. " in (" .. table.concat(self:escape(values), ", ") .. ")"
		elseif values == "null" then
			sql = sql .. " is " .. values
		else
			sql = sql .. " = " .. self:escape(values)
		end
	end
	return sql
end

return db

