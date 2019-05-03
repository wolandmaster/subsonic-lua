-- Copyright 2015-2017 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

package.path = package.path .. ";./test/?.lua"

require "subsonic.table"
require "subsonic.string"

local database = require "subsonic.db"
local fs = require "subsonic.fs"
local test = require "test"

-- open database
local db = database(":memory:")
test.assert_equals("open database", db ~= nil, true)

-- create table
db:execute([[
	create table test(
		id integer primary key not null unique,
		real_value real,
		text_value text,
		blob_value blob
	)
]])
test.assert_equals("create table", db:dump("test"), "{}")

-- insert values
test.assert_equals("insert value", table.dump(db:insert("test", {
	real_value = 1.1, text_value = "text",
	blob_value = fs.readfile("test/resources/sample.jpg") })),
	'{["real_value"]=1.1,["text_value"]="text",'
	.. '["blob_value"]="FFD8..514..FFD9",["id"]=1}')

-- close database
test.assert_equals("close database", db:close(), true)

