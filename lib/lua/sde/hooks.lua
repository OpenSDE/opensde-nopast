-- --- SDE-COPYRIGHT-NOTE-BEGIN ---
-- This copyright note is auto-generated by ./scripts/Create-CopyPatch.
--
-- Filename: lib/lua/sde/hooks.lua
-- Copyright (C) 2008 The OpenSDE Project
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
--  - add "protected" hooks (hooks, that can't be overriden simply)

-- DESCRIPTION:
-- 1. Create a new hook
--    h = hook() or h = hook.new()
--
-- 2. Using hooks
--
-- Access to the hooks with a given hook level (from 1 to 9):
--    h[num]:add(function-or-string)
--      Add a function to the hook with a hook level (num).
--
--    h[num]:set(function-or-string)
--      Replace the contents of hook-order "num" with a new function
--
--    h[num]:clear()
--      Clear all hooks.
--
--    h[num]:run()
--      Run a specific hook level
--
-- Access without hook level:
--    h:add(function-or-string)
--      Equivalent to h[5]:add(function-or-string)
--
--    h:set(function-or-string)
--      Equivalent to h[5]:set(function-or-string), however, clears
--      all other levels
--
--    h:clear()
--      Clear all hooks in all levels.
--
--    h:run()
--      Execute the hooks in all levels, starting at hook level 1.

-- INTERFACE -----------------------------------------------------------------
hook = { level = {} }
meta = {}

function hook.new()
   local h = hook
   return setmetatable(h, meta)
end

function hook:add(data)
   self[5]:add(data)
end

function hook:set(data)
   self:clear()
   self[5]:set(data)
end

function hook:run()
   for _,l in pairs(self.level) do l:run() end
end

function hook:clear()
   for _,l in pairs(self.level) do l:clear() end
end

-- h = hook()
setmetatable(hook, { __call = hook.new })

-- INTERNAL HOOKS __hook -----------------------------------------------------
local __hook = {}
local __meta = { __index = {} }

-- create a new __hook
function __hook.new()
   local h = { hooks = {} }
   return setmetatable(h, __meta)
end

-- __hook.add(hook-table, function-or-string)
-- add a function to the __hook
function __hook.add(h, data)
   if type(data) == "table" then
      for _,f in pairs(data) do
	 __hook.add(h, f)
      end
      return
   end

   -- insert hook
   if type(data) == "function" then
      table.insert(h.hooks, data)
   elseif type(data) == "string" then
      local f = loadstring(data)
      table.insert(h.hooks, f)
   else
      assert(type(data) == "function",
	     "function or string expected in hook.add(table, pos, function-or-string)")
   end
end

-- __hook.set(hook-table, function-or-string-or-nil)
-- add a function to the __hook
function __hook.set(h, data)
   h.hooks = {}
   __hook.add(h, data)
end

-- __hook.run(hook-table)
-- execute the hooks
function __hook.run(h)
   for _,f in pairs(h.hooks) do
      if f then f() end
   end
end

-- __hook.clear(hook-table)
-- clear all hooks
function __hook.clear(h)
   h.hooks = {}
end

-- METATABLE -----------------------------------------------------------------
function __meta.__index:add(data) __hook.add(self, data) end
function __meta.__index:set(data) __hook.set(self, data) end
function __meta.__index:clear()   __hook.clear(self) end
function __meta.__index:run()     __hook.run(self) end

function meta.__index(self, pos, data)
   -- clamp position
   if pos < 1 then pos = 1 end
   if pos > 9 then pos = 9 end

   -- create if it does not exist
   if not self.level[pos] then
      table.insert(self.level, pos, __hook.new())
   end

   return self.level[pos]
end

function meta.__newindex(self, pos, data)
   self[pos]:set(data)
end
