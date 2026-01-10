local Hook = {}
Hook.__index = Hook

local getgenv = getgenv or function() return _G end
local env = getgenv()
local hookfunction = env.hookfunction or hookfunction
local hookmetamethod = env.hookmetamethod or hookmetamethod
local checkcaller = env.checkcaller or checkcaller
local getnamecallmethod = env.getnamecallmethod or function() return "" end
local newcclosure = env.newcclosure or function(f) return f end
local unpack = table.unpack or unpack

function Hook.new()
    local self = setmetatable({}, Hook)
    self.Registry = {}
    self.Debug = true
    return self
end

function Hook:Log(msg)
    if self.Debug then
        warn(string.format("[Hook-System] %s", tostring(msg)))
    end
end

local function SafeExecute(func, ...)
    local args = {...}
    local success, result = pcall(function()
        return {func(unpack(args))}
    end)
    return success, result
end

function Hook:HookFunction(target, replacement)
    if type(target) ~= "function" or type(replacement) ~= "function" then
        self:Log("HookFunction: Invalid arguments")
        return nil
    end

    local original
    
    local detour = newcclosure(function(...)
        if checkcaller() then
            return original(...)
        end

        local success, results = SafeExecute(replacement, original, ...)
        
        if not success then
            self:Log("Runtime Error (Function): " .. tostring(results))
            return original(...)
        end
        
        if results then
            return unpack(results)
        end
    end)

    original = hookfunction(target, detour)
    self.Registry[target] = original
    return original
end

function Hook:HookMethod(object, method, replacement)
    if typeof(object) ~= "Instance" and typeof(object) ~= "userdata" then
        self:Log("HookMethod: Invalid object")
        return nil
    end
    if type(method) ~= "string" then
        self:Log("HookMethod: Invalid method name")
        return nil
    end

    local original
    
    local detour = newcclosure(function(self_obj, ...)
        if checkcaller() then
            return original(self_obj, ...)
        end

        if getnamecallmethod() == method then
            local success, results = SafeExecute(replacement, original, self_obj, ...)
            
            if not success then
                self:Log("Runtime Error (Method - " .. method .. "): " .. tostring(results))
                return original(self_obj, ...)
            end
            
            if results then
                return unpack(results)
            end
        end

        return original(self_obj, ...)
    end)

    original = hookmetamethod(object, "__namecall", detour)
    self.Registry[method] = original
    return original
end

function Hook:Restore(id)
    local original = self.Registry[id]
    if original then
        if type(id) == "function" then
            hookfunction(id, original)
        end
        self.Registry[id] = nil
        self:Log("Restored hook: " .. tostring(id))
    end
end

return Hook
