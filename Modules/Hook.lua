local Hook = {}
Hook.__index = Hook

local getgenv = getgenv or function() return _G end
local env = getgenv()
local hookfunction = env.hookfunction or hookfunction
local hookmetamethod = env.hookmetamethod or hookmetamethod
local checkcaller = env.checkcaller or checkcaller
local getnamecallmethod = env.getnamecallmethod or function() return "" end
local newcclosure = env.newcclosure or function(f) return f end

function Hook.new()
    local self = setmetatable({}, Hook)
    self.Registry = {} 
    self.Debug = true
    return self
end

function Hook:Log(msg)
    if self.Debug then
        print(string.format("[Hook-Debug] [%s] %s", os.date("%X"), tostring(msg)))
    end
end

local function SafeExecute(replacement, original, ...)
    local args = {...}
    local success, result = pcall(function()
        return {replacement(original, unpack(args))}
    end)
    
    if not success then
        return false, result
    end
    
    return true, result
end

function Hook:HookFunction(target, replacement)
    assert(type(target) == "function", "HookFunction: Invalid target")
    assert(type(replacement) == "function", "HookFunction: Invalid replacement")

    local original
    
    local function detour(...)
        if checkcaller() then 
            return original(...) 
        end
        
        local success, results = SafeExecute(replacement, original, ...)
        
        if not success then
            self:Log("Error in HookFunction: " .. tostring(results))
            return original(...)
        end
        
        return unpack(results)
    end

    original = hookfunction(target, newcclosure(detour))
    self.Registry[target] = original
    return original
end

function Hook:HookMethod(object, method, replacement)
    assert(typeof(object) == "Instance" or typeof(object) == "userdata", "HookMethod: Invalid object")
    assert(type(method) == "string", "HookMethod: Invalid method name")
    
    local original
    
    local function detour(self_obj, ...)
        if checkcaller() then 
            return original(self_obj, ...) 
        end
        
        if getnamecallmethod() == method then
            local success, results = SafeExecute(replacement, original, self_obj, ...)
            
            if not success then
                self:Log("Error in HookMethod ("..method.."): " .. tostring(results))
                return original(self_obj, ...)
            end
            
            return unpack(results)
        end
        
        return original(self_obj, ...)
    end
    
    original = hookmetamethod(object, "__namecall", newcclosure(detour))
    self.Registry[method] = original
    return original
end

function Hook:Restore(id)
    local original = self.Registry[id]
    
    if original then
        if type(id) == "function" then
            hookfunction(id, original)
            self:Log("Restored function hook")
        else
            self:Log("Restoring non-function hooks is context-dependent (Metamethods require overwrite).")
        end
        
        self.Registry[id] = nil
    else
        self:Log("Attempted to restore invalid or non-existent hook.")
    end
end

return Hook
