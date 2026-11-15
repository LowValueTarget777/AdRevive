-- Resolve object-valued fields and array entries before using UObject methods.
return function(obj)
    for _ = 1, 3 do
        if type(obj) ~= "userdata" and type(obj) ~= "table" then break end
        local kind = obj.type and obj:type()
        if kind == "FWeakObjectPtr" then obj = obj:Get()
        elseif kind == "RemoteUnrealParam" or kind == "LocalUnrealParam" then obj = obj:get()
        else break end
    end
    return obj
end
