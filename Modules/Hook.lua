local Hook = {}
Hook.__index = Hook

local getgenv = getgenv or function() return _G end
local h_func = getgenv().hookfunction or hookfunction
local h_meta = getgenv().hookmetamethod or hookmetamethod
local c_call = getgenv().checkcaller or checkcaller
local unpack = table.unpack or unpack

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
    local results = { pcall(replacement, original, ...) }
    
    if not results[1] then
        return false, results[2]
    end
    
    table.remove(results, 1)
    return true, results
end

function Hook:HookFunction(target, replacement)
    assert(type(target) == "function", "HookFunction: Invalid target (expected function)")
    assert(type(replacement) == "function", "HookFunction: Invalid replacement (expected function)")

    local original
    
    local function detour(...)
        if c_call() then 
            return original(...) 
        end
        
        local success, result_table = SafeExecute(replacement, original, ...)
        
        if not success then
            self:Log("Error in HookFunction: " .. tostring(result_table))
            return original(...)
        end
        
        return unpack(result_table)
    end

    original = h_func(target, detour)
    self.Registry[target] = original
    return original
end

function Hook:HookMethod(object, method, replacement)
    assert(typeof(object) == "Instance" or typeof(object) == "userdata", "HookMethod: Invalid object")
    assert(type(method) == "string", "HookMethod: Invalid method name")
    
    local original
    
    local function detour(self_obj, ...)
        if c_call() then 
            return original(self_obj, ...) 
        end
        
        local success, result_table = SafeExecute(replacement, original, self_obj, ...)
        
        if not success then
            self:Log("Error in HookMethod ("..method.."): " .. tostring(result_table))
            return original(self_obj, ...)
        end
        
        return unpack(result_table)
    end
    
    original = h_meta(object, method, detour)
    self.Registry[method] = original
    return original
end

function Hook:Restore(id)
    local original = self.Registry[id]
    
    if original then
        if type(id) == "function" then
            h_func(id, original)
            self:Log("Restored function hook")
        else
            self:Log("Restoring non-function hooks is context-dependent.")
        end
        
        self.Registry[id] = nil
    else
        self:Log("Attempted to restore invalid or non-existent hook.")
    end
end

return Hook
