-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

function string.starts(str, head)
	return str:sub(1, string.len(head)) == head
end

function string.ends(str, tail)
	return tail == "" or str:sub(-string.len(tail)) == tail
end

function string.trim(str)
	return str:match("^()%s*$") and "" or str:match("^%s*(.*%S)")
end

function string.tohex(str)
	return str:gsub(".", function(char)
		return string.format("%02X", string.byte(char))
	end)
end

function string.has_unprintable(str)
	for char in str:gmatch(".") do
		local byte = string.byte(char)
		if byte < 32 or byte > 126 then
			return true
		end
	end
	return false
end



