-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

local nixio = require "nixio"
local log = require "subsonic.log"
local fs = require "subsonic.fs"

local io, table = io, table

module "subsonic.response"

local SUBSONIC_API_VERSION = "1.0.0"

-------------------------
-- P U B L I C   A P I --
-------------------------
function http_200_ok(content_type, headers)
	headers = headers and table.concat(headers, "\r\n") or ""
	if headers ~= "" then headers = headers .. "\r\n" end
	return "Status: 200 OK\r\n"
	.. "Access-Control-Allow-Origin: *\r\n"
	.. "Content-Type: " .. content_type .. "\r\n"
	.. headers .. "\r\n"
end

function subsonic_api_version()
	return SUBSONIC_API_VERSION
end

function send_xml(msg, status)
	msg = msg or ""
	status = status or "ok"
	log.debug("send xml:", msg)
	io.write(http_200_ok("application/xml")
	.. '<?xml version="1.0" encoding="UTF-8"?>\r\n'
	.. '<subsonic-response status="' .. status .. '" version="'
	.. SUBSONIC_API_VERSION .. '">' .. msg .. '</subsonic-response>')
	io.flush()
end

function send_json(msg, status)
	msg = msg and "," .. msg or ""
	status = status or "ok"
	log.debug("send json:", msg)
	io.write(http_200_ok("application/json")
	.. 'Content-Type: application/json\r\n\r\n'
	.. '{"subsonic-response":{"status":"' .. status .. '","version":"'
	.. SUBSONIC_API_VERSION .. '"' .. msg .. '}}')
	io.flush()
end

function send_binary(data)
	io.write(http_200_ok("application/octet-stream",
		{ "Content-Length: " .. data:len() }))
	io.write(data)
	io.flush()
end

function send_file(...)
	local file = fs.join_path(...)
	local fh = nixio.open(file, 'r')
	log.debug("send file:", file)
	io.write(http_200_ok("application/octet-stream",
		{ "Content-Length: " .. fs.file_size(file) }))
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

