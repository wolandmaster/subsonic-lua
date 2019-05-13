-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

function table.put(array, ...)
	for _, value in ipairs({...}) do
		table.insert(array, value)
	end
	return array
end

function table.map(array, func)
	local out = {}
	for key, value in pairs(array) do
		local out_value, out_key = func(value, key, array)
		out[out_key or key] = out_value
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

function table.keys(array)
	local keys = {}
	for key, _ in pairs(array) do
		table.insert(keys, key)
	end
	return keys
end

function table.compare_mixed(left, right)
	local left_type, right_type = type(left), type(right)
	if left_type ~= right_type then
		return left_type > right_type
	else
		return left < right
	end
end

function table.clone(array)
	return { unpack(array) }
end

function table.merge(...)
	local merged = {}
	for _, array in ipairs({...}) do
		for key, value in pairs(array) do
			merged[key] = value
		end
	end
	return merged
end

function table.dump(entry)
	if type(entry) == "table" then
		local str = "{"
		for key, value in pairs(entry) do
			if type(key) ~= "number" then key = '"' .. key .. '"' end
			str = str .. "[" .. key .. "]=" .. table.dump(value) .. ","
		end
		return str:gsub(",$", "") .. "}"
	else
		if type(entry) == "number" then
			return tostring(entry)
		elseif type(entry) == "string" then
			if entry:has_unprintable() then
				local hex = entry:tohex()
				return #hex > 8
				and '"' .. hex:sub(1, 4) .. ".." .. ((#hex - 8) / 2)
					.. ".." .. hex:sub(-4) .. '"'
				or '"' .. hex .. '"'
			else
				return '"' .. entry .. '"'
			end
		end
	end
end

