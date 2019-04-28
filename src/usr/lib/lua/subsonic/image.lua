-- Copyright 2015-2017 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

require "subsonic.string"

local ltn12 = require "ltn12"
local https = require "ssl.https"
local nixiofs = require "nixio.fs"

local fs = require "subsonic.fs"
local metadata = require "subsonic.metadata"

local table, string, math, os, pairs = table, string, math, os, pairs
local tostring = tostring

module "subsonic.image"

local IMG_RESIZE = "https://img-resize.com/resize"

local function generate_boundary()
	local boundary = ""
	local charset = {}
	for i = 48,  57 do table.insert(charset, string.char(i)) end
	for i = 65,  90 do table.insert(charset, string.char(i)) end
	for i = 97, 122 do table.insert(charset, string.char(i)) end
	math.randomseed(os.time())
	for i = 1,   20 do
		boundary = boundary .. charset[math.random(1, #charset)]
	end
	return boundary
end

local function multipart_form_data(boundary, array)
	local resp = ""
	for name, data in pairs(array) do
		resp = resp .. "--" .. boundary .. "\r\n"
			.. 'Content-Disposition: form-data; name="' .. name .. '"'
		if tostring(data):starts("@") then
			local file = data:sub(2)
			resp = resp ..'; filename="' .. fs.basename(file) .. '"\r\n'
				.. "Content-Type: " .. metadata.content_type(file)
			data = nixiofs.readfile(file)
		end
		resp = resp .. "\r\n\r\n" .. data .. "\r\n"
	end
	return resp .. "--" .. boundary .. "--\r\n"
end

-------------------------
-- P U B L I C   A P I --
-------------------------
function resize(file, size)
	local boundary = generate_boundary()
	local body = multipart_form_data(boundary, {
		op = "letterbox",
		letterboxWidth = size,
		letterboxHeight = size,
		input = "@" .. file
	})
	local resp = {}
	local one, code, headers, status = https.request({
		url = IMG_RESIZE,
		method = "POST",
		sink = ltn12.sink.table(resp),
		source = ltn12.source.string(body),
		headers = {
			["content-length"] = #body,
			["content-type"] = "multipart/form-data; boundary=" .. boundary
		}
	})
	if code ~= 200 then return nil, status end
	return table.concat(resp)
end

