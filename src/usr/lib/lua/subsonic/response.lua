-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

require "subsonic.table"

local nixio = require "nixio"
local log = require "subsonic.log"
local metadata = require "subsonic.metadata"
local fs = require "subsonic.fs"

local io, table, pairs, ipairs, type = io, table, pairs, ipairs, type
local next, tostring, string = next, tostring, string

module "subsonic.response"

local SUBSONIC_API_VERSION = "1.0.0"

local function json_to_string(value)
	if type(value) == "string" then
		return '"' .. tostring(value) .. '"'
	else
		return tostring(value)
	end
end

local function xml_escape(str)
	return str:gsub("(.)", {
		["<"] = "&lt;",
		[">"] = "&gt;",
		["&"] = "&amp;",
		["'"] = "&apos;",
		['"'] = "&quot;"
	})
end

-------------------------
-- P U B L I C   A P I --
-------------------------
function subsonic_api_version()
	return SUBSONIC_API_VERSION
end

function to_xml(array)
	local xml = ""
	for key, value in table.spairs(array, table.compare_mixed) do
		if type(value) == "table" then
			if type(key) == "string" then
				xml = xml .. "<" .. key .. to_xml(value)
				.. (value[1] and "</" .. key .. ">" or "/>")
			elseif key == 1 then
				xml = xml .. ">" .. to_xml(value)
			else
				xml = xml .. to_xml(value)
			end
		else
			xml = xml .. " " .. key .. '="'
			.. xml_escape(tostring(value)) .. '"'
		end
	end
	return xml
end

function to_json(array, flag)
	flag = flag or {}
	local json = ""
	for key, value in table.spairs(array, table.compare_mixed) do
		if type(value) == "table" then
			if type(key) == "string" then
				if next(flag) == nil or flag.first ~= nil then
					json = json .. '"' .. key .. '":'
				end
				if flag.first ~= nil then json = json .. "[" end
				json = json .. "{" .. to_json(value) .. "}"
				if flag.last ~= nil then json = json .. "]" end
			elseif type(key) == "number" then
				local flag = { ["item"] = true }
				if key == 1 then flag.first = true end
				if key == #array then flag.last = true end
				if key > 1 and (next(value)) ~= (next(array[key - 1])) then
					flag.first = true
				end
				if array[key + 1] ~= nil
				and (next(value)) ~= (next(array[key + 1])) then
					flag.last = true
				end
				json = json .. to_json(value, flag) .. ","
			end
		else
			json = json .. '"' .. key .. '":' .. json_to_string(value) .. ","
		end
	end
	return json:gsub(",$", "")
end

function http_200_ok(content_type, headers)
	headers = headers and table.concat(headers, "\r\n") or ""
	if headers ~= "" then headers = headers .. "\r\n" end
	return "Status: 200 OK\r\n"
	.. "Access-Control-Allow-Origin: *\r\n"
	.. "Content-Type: " .. content_type .. "\r\n"
	.. headers .. "\r\n"
end

function send_xml(xml, status)
	local xml = xml or ""
	local status = status or "ok"
	local resp = '<?xml version="1.0" encoding="UTF-8"?>\r\n'
		.. '<subsonic-response status="' .. status .. '" version="'
		.. SUBSONIC_API_VERSION .. '">' .. xml .. '</subsonic-response>'
	log.info("send xml:", resp)
	io.write(http_200_ok("application/xml",
		{ "Content-Length: " .. #resp }) .. resp)
	io.flush()
end

function send_json(json, status)
	local json = (json and json ~= "") and "," .. json or ""
	local status = status or "ok"
	local resp = '{"subsonic-response":{"status":"' .. status .. '","version":"'
		.. SUBSONIC_API_VERSION .. '"' .. json .. '}}'
	log.info("send json:", resp)
	io.write(http_200_ok("application/json",
		{ "Content-Length: " .. #resp }) .. resp)
	io.flush()
end

function send(resp, qs, status)
	local qs = qs or {}
	local format = qs.f or "xml"
	if format == "xml" then
		send_xml(to_xml(resp), status)
	elseif format == "json" then
		send_json(to_json(resp), status)
	end
end

function send_binary(data, content_type)
	local content_type = content_type or "application/octet-stream"
	log.info("send", content_type, "with size:", #data)
	io.write(http_200_ok(content_type,
		{ "Content-Length: " .. #data }) .. data)
	io.flush()
end

function send_file(qs, ...)
	local file = fs.join_path(...)
	local fh = nixio.open(file, 'r')
	log.info("send file:", file)

	-- uhttpd always sends chunked transfer encoding header
	-- and music stash tries to read chunked data
	local server_software = nixio.getenv("SERVER_SOFTWARE") or ""
	local client_software = qs.c or ""
	local stacked = server_software:lower() == "uhttpd"
		and client_software:lower() == "musicstash"
	if stacked then
		log.debug("send stacked begin")
		io.write(http_200_ok(metadata.content_type(file)))
		io.write(string.format("%X", fh:stat("size")) .. "\r\n")
	else
		io.write(http_200_ok(metadata.content_type(file),
			{ "Content-Length: " .. fh:stat("size") }))
	end

	repeat
		local buf = fh:read(2^13)	-- 8k
		io.write(buf)
	until (buf == "")

	if stacked then
		io.write("\r\n0\r\n\r\n")
		log.debug("send stacked end")
	end
	io.flush()
	fh:close()
	log.debug("file sent (" .. file .. ")")
end

function send_error(error_code)
	if (error_code == 0) then
		send_xml('<error code="0" message="A generic error"/>', "failed")
	elseif (error_code == 10) then
		send_xml('<error code="10" '
		.. 'message="Required parameter is missing"/>', "failed")
	elseif (error_code == 20) then
		send_xml('<error code="20" '
		.. 'message="Incompatible Subsonic REST protocol version. '
		.. 'Client must upgrade"/>', "failed")
	elseif (error_code == 30) then
		send_xml('<error code="30" '
		.. 'message="Incompatible Subsonic REST protocol version. '
		.. 'Server must upgrade"/>', "failed")
	elseif (error_code == 40) then
		send_xml('<error code="40" '
		.. 'message="Wrong username or password"/>', "failed")
	elseif (error_code == 50) then
		send_xml('<error code="50" message="User is not authorized '
		.. 'for the given operation"/>', "failed")
	elseif (error_code == 70) then
		send_xml('<error code="70" message="The requested data '
		.. 'was not found"/>', "failed")
	end
end

