-- --- SDE-COPYRIGHT-NOTE-BEGIN ---
-- This copyright note is auto-generated by ./scripts/Create-CopyPatch.
--
-- Filename: lib/lua/sde/desc.lua
-- Copyright (C) 2006 - 2008 The OpenSDE Project
-- Copyright (C) 2005 - 2006 The T2 SDE Project
-- Copyright (C) 2005 - 2006 Juergen "George" Sawinski
--
-- More information can be found in the files COPYING and README.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License. A copy of the
-- GNU General Public License can be found in the file COPYING.
-- --- SDE-COPYRIGHT-NOTE-END ---

-- TODO:
--  - parser should also accept string as input
--  - implement the desc.validator

-- DESCRIPTION:
--   t = desc.parse(line-iterator)
--     Parse ".desc" file format by passing a line iterator and
--     return a table, where lower-case of last entry in
--       etc/desc_format
--     is the key. Example:
--     Parsing "[I] Title" returns `{ title = "Title" }'

-- package object structure
desc = desc or {}
desc.__format__ = {}

-- FIXME setmetatable(desc, { __call = function })

-- parse .desc text ; expects line iterator function as argument
function desc.parse(iter)
	local retval = {}

 	-- FIXME: Perhaps we'll gain some performance by not reading
	--        line by line
	for line in io.open(iter):lines() do
		local tag,cnt

		_,_,tag,cnt = string.find(line, "([[][^]]*[]])[ ]+(.*)")
		if tag then
			local fmt = desc.__format__[tag]
			if fmt then
				retval[fmt.name] = retval[fmt.name] or {}
				table.insert(retval[fmt.name], cnt)
			end
		end
	end

	return retval
end

-- similar to desc.parse, but validate the description
function desc.validate(iter)
	local retval = desc.parse(iter)

	-- TODO implement validating

	return retval
end

-- init: parse etc/desc_format
for line in io.open("etc/desc_format"):lines() do
	local required=false
	local tag

	if string.match(line, "^[[]") ~= nil then
		-- check if tag is required
		if string.match(line, "([*])") ~= nil then required=true; end

		-- use last tag definition as name
		for t in string.gfind(line,"[[]([^]]*)[]]") do tag = t; end
		tag = string.lower(tag)

		-- sort into __format__
		for t in string.gfind(line,"([[][^]]*[]])") do
			desc.__format__[t] = { name = tag; required = required }
		end
	end
end
