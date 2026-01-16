local Hook = {}
Hook.__index = Hook

local env = (getgenv or function() return _G end)()
local hookfunction = env.hookfunction
local hookmetamethod = env.hookmetamethod
local checkcaller = env.checkcaller
local getnamecallmethod = env.getnamecallmethod
local newcclosure = env.newcclosure

function Hook.new()
	return setmetatable({
		Registry = {},
		Debug = true
	}, Hook)
end

function Hook:Log(msg: string)
	if self.Debug then
		print("[Hook] " .. msg)
	end
end

function Hook:HookFunction(target: any, replacement: any)
	if type(target) ~= "function" then return end

	local original
	local detour = newcclosure(function(...)
		if checkcaller() then 
			return original(...) 
		end
		
		return replacement(original, ...)
	end)

	original = hookfunction(target, detour)
	self.Registry[target] = original
	return original
end

function Hook:HookMethod(object: Instance, method: string, replacement: any)
	local original
	
	local detour = newcclosure(function(self_obj, ...)
		local namecall = getnamecallmethod()
		
		if namecall == method and not checkcaller() then
			return replacement(original, self_obj, ...)
		end
		
		return original(self_obj, ...)
	end)
	
	original = hookmetamethod(object, "__namecall", detour)
	self.Registry[method] = original
	return original
end

function Hook:Restore(id: any)
	local original = self.Registry[id]
	if not original then return end

	if type(id) == "function" then
		hookfunction(id, original)
	end
	
	self.Registry[id] = nil
end

return Hook
