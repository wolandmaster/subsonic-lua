-- Copyright 2015-2017 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

local nixio = require "nixio"

local print, ipairs, pairs, math, table = print, ipairs, pairs, math, table
local io, tostring, type = io, tostring, type

module "test"

local red = function(s) return "\27[31m" .. s .. "\27[0m" end
local green = function(s) return "\27[32m" .. s .. "\27[0m" end

function assert_equals(actual, expected)
	print("expected: '" .. tostring(expected) .. "': " .. (actual == expected and green("passed")
		or red("failed") .. "\n  actual: '" .. tostring(actual) .. "'"))
end

function open(file)
	return nixio.open(file, "r")
end

function dump(t, indent)
	local indent = indent or ""
	io.write("{\n")
	for key, value in pairs(t) do
		io.write(indent, "\t[\"", tostring(key), "\"] = ")
		if type(value) == "table" then
			dump(value, indent .. "\t")
		else
			io.write(type(value) == "string" and ("%q"):format(value) or tostring(value))
			io.write(",\n")
		end
	end
	io.write(indent, "},\n")
end

function binary(...)
	local nums = {}
	for _, num in ipairs({...}) do
		local rest = num
		local bits = {}
		while rest > 0 do
			bit = math.fmod(rest, 2)
			table.insert(bits, 1, bit)
			rest = (rest - bit) / 2
		end
		table.insert(nums, table.concat(bits) .. " (" .. num .. ")")
	end
	return table.concat(nums, ", ")
end

