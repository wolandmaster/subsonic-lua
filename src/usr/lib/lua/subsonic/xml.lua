-- Copyright 2015-2017 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

local xml = {}
xml.__index = xml

setmetatable(xml, {
	__call = function (cls, ...)
		return cls.new(...)
	end,
})

function xml.new(tag_name, attrs)
	local self = setmetatable({}, xml)
	self.tag_name = tag_name
	self.attrs = attrs or {}
	self.children = {}
	return self
end

function xml.child(self, tag_name, attrs)
	local child = xml.new(tag_name, attrs)
	child.ancestor = self
	table.insert(self.children, child)
	return child
end

function xml.sibling(self, tag_name, attrs)
	return xml.child(self.ancestor ~= nil and self.ancestor or self, tag_name, attrs)
end

function xml.parent(self)
	assert(self.ancestor, "no parent exists")
	return self.ancestor
end

function xml.root(self)
	return self.ancestor ~= nil and xml.root(self.ancestor) or self
end

function xml.build(self)
	local tag = '<' .. self.tag_name
	for key, value in pairs(self.attrs) do
		tag = tag .. ' ' .. key .. '="' .. escape(tostring(value)) .. '"'
	end
	if next(self.children) == nil then
		tag = tag .. '/>'
	else
		tag = tag .. '>'
		for _, child in ipairs(self.children) do
			tag = tag .. child:build()
		end
		tag = tag .. '</' .. self.tag_name .. '>'
	end
	return tag
end

function xml.build_root(self)
	return self:root():build()
end

function escape(str)
	return str:gsub("(.)", {
		["<"] = "&lt;", [">"] = "&gt;", ["&"] = "&amp;",
		["'"] = "&apos;", ['"'] = "&quot;"
	})
end

return xml

