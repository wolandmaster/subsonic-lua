-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

function table.put(array, ...)
	for _, value in ipairs({...}) do
		table.insert(array, value)
	end
end

function table.map(array, func)
	local out = {}
	for key, value in pairs(array) do
		out[key] = func(value, key, array)
	end
	return out
end

function table.filter(array, func)
	local out = {}
	for key, value in pairs(array) do
		if func(value, key, array) then
			out[key] = value
		end
	end
	return out
end

function table.ifilter(array, func)
	local out = {}
	for key, value in ipairs(array) do
		if func(value, key, array) then
			table.insert(out, value)
		end
	end
	return out
end

-- key sorted iterator
function table.spairs(array, order)
	local keys = {} 
	for key, _ in pairs(array) do
		table.insert(keys, key)
	end 
	table.sort(keys, order)
	local index = 0
	local iter = function()
		index = index + 1
		return keys[index] == nil and nil
			or keys[index], array[keys[index]]
	end
	return iter
end

function table.dump(array)
	if type(array) == "table" then
		local str = "{ "
		for key, value in pairs(array) do
			if type(key) ~= "number" then key = '"' .. key .. '"' end
			str = str .. "[" .. key .. "] = " .. table.dump(value) .. ", "
		end
		return str:gsub(", $", " ") .. "} "
	else
		if type(array) == "number" then
			return tostring(array)
		else
			return '"' .. array .. '"'
		end
	end
end

