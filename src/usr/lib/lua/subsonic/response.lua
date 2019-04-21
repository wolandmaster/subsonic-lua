-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

local nixio = require "nixio"
local log = require "subsonic.log"
local fs = require "subsonic.fs"

local io = io

module "subsonic.response"

function send_xml(msg, status)
	status = status or "ok"
	io.write(
		'Status: 200 OK\r\n' ..
		'Content-Type: application/xml\r\n\r\n' ..
		'<?xml version="1.0" encoding="UTF-8"?>\r\n' ..
		'<subsonic-response status="' .. status .. '" version="1.14.0">' .. msg .. '</subsonic-response>'
	)
	io.flush()
end

function send_binary(data)
	io.write(
		'Status: 200 OK\r\n' ..
		'Content-Length: ' .. data:len() .. '\r\n' ..
		'Content-Type: application/octet-stream\r\n\r\n'
	)
	io.write(data)
	io.flush()
end

function send_file(...)
	local file = fs.join_path(...)
	local fh = nixio.open(file, 'r')
	io.write(
		'Status: 200 OK\r\n' ..
		'Content-Length: ' .. fs.file_size(file) .. '\r\n' ..
		'Content-Type: application/octet-stream\r\n\r\n'
	)
	repeat
		local buf = fh:read(2^13)	-- 8k
		io.write(buf)
	until (buf == "")
	io.flush()
	fh:close()
end

function send_error(error_code)
	if (error_code == 0) then
		send_xml('<error code="0" message="A generic error"/>', "failed")
	elseif (error_code == 10) then
		send_xml('<error code="10" message="Required parameter is missing"/>', "failed")
	elseif (error_code == 20) then
		send_xml('<error code="20" message="Incompatible Subsonic REST protocol version. Client must upgrade"/>', "failed")
	elseif (error_code == 30) then
		send_xml('<error code="30" message="Incompatible Subsonic REST protocol version. Server must upgrade"/>', "failed")
	elseif (error_code == 40) then
		send_xml('<error code="40" message="Wrong username or password"/>', "failed")
	elseif (error_code == 50) then
		send_xml('<error code="50" message="User is not authorized for the given operation"/>', "failed")
	elseif (error_code == 70) then
		send_xml('<error code="70" message="The requested data was not found"/>', "failed")
	end
end

