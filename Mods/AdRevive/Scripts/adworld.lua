--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]

local ____modules = {}
local ____moduleCache = {}
local ____originalRequire = require
local function require(file, ...)
    if ____moduleCache[file] then
        return ____moduleCache[file].value
    end
    if ____modules[file] then
        local module = ____modules[file]
        local value = nil
        if (select("#", ...) > 0) then value = module(...) else value = module(file) end
        ____moduleCache[file] = { value = value }
        return value
    else
        if ____originalRequire then
            return ____originalRequire(file)
        else
            error("module '" .. file .. "' not found")
        end
    end
end
____modules = {
["lualib_bundle"] = function(...) 
local function __TS__ArrayAt(self, relativeIndex)
    local absoluteIndex = relativeIndex < 0 and #self + relativeIndex or relativeIndex
    if absoluteIndex >= 0 and absoluteIndex < #self then
        return self[absoluteIndex + 1]
    end
    return nil
end

local function __TS__ArrayIsArray(value)
    return type(value) == "table" and (value[1] ~= nil or next(value) == nil)
end

local function __TS__ArrayConcat(self, ...)
    local items = {...}
    local result = {}
    local len = 0
    for i = 1, #self do
        len = len + 1
        result[len] = self[i]
    end
    for i = 1, #items do
        local item = items[i]
        if __TS__ArrayIsArray(item) then
            for j = 1, #item do
                len = len + 1
                result[len] = item[j]
            end
        else
            len = len + 1
            result[len] = item
        end
    end
    return result
end

local __TS__Symbol, Symbol
do
    local symbolMetatable = {__tostring = function(self)
        return ("Symbol(" .. (self.description or "")) .. ")"
    end}
    function __TS__Symbol(description)
        return setmetatable({description = description}, symbolMetatable)
    end
    Symbol = {
        asyncDispose = __TS__Symbol("Symbol.asyncDispose"),
        dispose = __TS__Symbol("Symbol.dispose"),
        iterator = __TS__Symbol("Symbol.iterator"),
        hasInstance = __TS__Symbol("Symbol.hasInstance"),
        species = __TS__Symbol("Symbol.species"),
        toStringTag = __TS__Symbol("Symbol.toStringTag")
    }
end

local function __TS__ArrayEntries(array)
    local key = 0
    return {
        [Symbol.iterator] = function(self)
            return self
        end,
        next = function(self)
            local result = {done = array[key + 1] == nil, value = {key, array[key + 1]}}
            key = key + 1
            return result
        end
    }
end

local function __TS__ArrayEvery(self, callbackfn, thisArg)
    for i = 1, #self do
        if not callbackfn(thisArg, self[i], i - 1, self) then
            return false
        end
    end
    return true
end

local function __TS__ArrayFill(self, value, start, ____end)
    local relativeStart = start or 0
    local relativeEnd = ____end or #self
    if relativeStart < 0 then
        relativeStart = relativeStart + #self
    end
    if relativeEnd < 0 then
        relativeEnd = relativeEnd + #self
    end
    do
        local i = relativeStart
        while i < relativeEnd do
            self[i + 1] = value
            i = i + 1
        end
    end
    return self
end

local function __TS__ArrayFilter(self, callbackfn, thisArg)
    local result = {}
    local len = 0
    for i = 1, #self do
        if callbackfn(thisArg, self[i], i - 1, self) then
            len = len + 1
            result[len] = self[i]
        end
    end
    return result
end

local function __TS__ArrayForEach(self, callbackFn, thisArg)
    for i = 1, #self do
        callbackFn(thisArg, self[i], i - 1, self)
    end
end

local function __TS__ArrayFind(self, predicate, thisArg)
    for i = 1, #self do
        local elem = self[i]
        if predicate(thisArg, elem, i - 1, self) then
            return elem
        end
    end
    return nil
end

local function __TS__ArrayFindIndex(self, callbackFn, thisArg)
    for i = 1, #self do
        if callbackFn(thisArg, self[i], i - 1, self) then
            return i - 1
        end
    end
    return -1
end

local __TS__Iterator
do
    local function iteratorGeneratorStep(self)
        local co = self.____coroutine
        local status, value = coroutine.resume(co)
        if not status then
            error(value, 0)
        end
        if coroutine.status(co) == "dead" then
            return
        end
        return true, value
    end
    local function iteratorIteratorStep(self)
        local result = self:next()
        if result.done then
            return
        end
        return true, result.value
    end
    local function iteratorStringStep(self, index)
        index = index + 1
        if index > #self then
            return
        end
        return index, string.sub(self, index, index)
    end
    function __TS__Iterator(iterable)
        if type(iterable) == "string" then
            return iteratorStringStep, iterable, 0
        elseif iterable.____coroutine ~= nil then
            return iteratorGeneratorStep, iterable
        elseif iterable[Symbol.iterator] then
            local iterator = iterable[Symbol.iterator](iterable)
            return iteratorIteratorStep, iterator
        else
            return ipairs(iterable)
        end
    end
end

local __TS__ArrayFrom
do
    local function arrayLikeStep(self, index)
        index = index + 1
        if index > self.length then
            return
        end
        return index, self[index]
    end
    local function arrayLikeIterator(arr)
        if type(arr.length) == "number" then
            return arrayLikeStep, arr, 0
        end
        return __TS__Iterator(arr)
    end
    function __TS__ArrayFrom(arrayLike, mapFn, thisArg)
        local result = {}
        if mapFn == nil then
            for ____, v in arrayLikeIterator(arrayLike) do
                result[#result + 1] = v
            end
        else
            local i = 0
            for ____, v in arrayLikeIterator(arrayLike) do
                local ____mapFn_3 = mapFn
                local ____thisArg_1 = thisArg
                local ____v_2 = v
                local ____i_0 = i
                i = ____i_0 + 1
                result[#result + 1] = ____mapFn_3(____thisArg_1, ____v_2, ____i_0)
            end
        end
        return result
    end
end

local function __TS__ArrayIncludes(self, searchElement, fromIndex)
    if fromIndex == nil then
        fromIndex = 0
    end
    local len = #self
    local k = fromIndex
    if fromIndex < 0 then
        k = len + fromIndex
    end
    if k < 0 then
        k = 0
    end
    for i = k + 1, len do
        if self[i] == searchElement then
            return true
        end
    end
    return false
end

local function __TS__ArrayIndexOf(self, searchElement, fromIndex)
    if fromIndex == nil then
        fromIndex = 0
    end
    local len = #self
    if len == 0 then
        return -1
    end
    if fromIndex >= len then
        return -1
    end
    if fromIndex < 0 then
        fromIndex = len + fromIndex
        if fromIndex < 0 then
            fromIndex = 0
        end
    end
    for i = fromIndex + 1, len do
        if self[i] == searchElement then
            return i - 1
        end
    end
    return -1
end

local function __TS__ArrayJoin(self, separator)
    if separator == nil then
        separator = ","
    end
    local parts = {}
    for i = 1, #self do
        parts[i] = tostring(self[i])
    end
    return table.concat(parts, separator)
end

local function __TS__ArrayMap(self, callbackfn, thisArg)
    local result = {}
    for i = 1, #self do
        result[i] = callbackfn(thisArg, self[i], i - 1, self)
    end
    return result
end

local function __TS__ArrayPush(self, ...)
    local items = {...}
    local len = #self
    for i = 1, #items do
        len = len + 1
        self[len] = items[i]
    end
    return len
end

local function __TS__ArrayPushArray(self, items)
    local len = #self
    for i = 1, #items do
        len = len + 1
        self[len] = items[i]
    end
    return len
end

local function __TS__CountVarargs(...)
    return select("#", ...)
end

local function __TS__ArrayReduce(self, callbackFn, ...)
    local len = #self
    local k = 0
    local accumulator = nil
    if __TS__CountVarargs(...) ~= 0 then
        accumulator = ...
    elseif len > 0 then
        accumulator = self[1]
        k = 1
    else
        error("Reduce of empty array with no initial value", 0)
    end
    for i = k + 1, len do
        accumulator = callbackFn(
            nil,
            accumulator,
            self[i],
            i - 1,
            self
        )
    end
    return accumulator
end

local function __TS__ArrayReduceRight(self, callbackFn, ...)
    local len = #self
    local k = len - 1
    local accumulator = nil
    if __TS__CountVarargs(...) ~= 0 then
        accumulator = ...
    elseif len > 0 then
        accumulator = self[k + 1]
        k = k - 1
    else
        error("Reduce of empty array with no initial value", 0)
    end
    for i = k + 1, 1, -1 do
        accumulator = callbackFn(
            nil,
            accumulator,
            self[i],
            i - 1,
            self
        )
    end
    return accumulator
end

local function __TS__ArrayReverse(self)
    local i = 1
    local j = #self
    while i < j do
        local temp = self[j]
        self[j] = self[i]
        self[i] = temp
        i = i + 1
        j = j - 1
    end
    return self
end

local function __TS__ArrayUnshift(self, ...)
    local items = {...}
    local numItemsToInsert = #items
    if numItemsToInsert == 0 then
        return #self
    end
    for i = #self, 1, -1 do
        self[i + numItemsToInsert] = self[i]
    end
    for i = 1, numItemsToInsert do
        self[i] = items[i]
    end
    return #self
end

local function __TS__ArraySort(self, compareFn)
    if compareFn ~= nil then
        table.sort(
            self,
            function(a, b) return compareFn(nil, a, b) < 0 end
        )
    else
        table.sort(self)
    end
    return self
end

local function __TS__ArraySlice(self, first, last)
    local len = #self
    first = first or 0
    if first < 0 then
        first = len + first
        if first < 0 then
            first = 0
        end
    else
        if first > len then
            first = len
        end
    end
    last = last or len
    if last < 0 then
        last = len + last
        if last < 0 then
            last = 0
        end
    else
        if last > len then
            last = len
        end
    end
    local out = {}
    first = first + 1
    last = last + 1
    local n = 1
    while first < last do
        out[n] = self[first]
        first = first + 1
        n = n + 1
    end
    return out
end

local function __TS__ArraySome(self, callbackfn, thisArg)
    for i = 1, #self do
        if callbackfn(thisArg, self[i], i - 1, self) then
            return true
        end
    end
    return false
end

local function __TS__ArraySplice(self, ...)
    local args = {...}
    local len = #self
    local actualArgumentCount = __TS__CountVarargs(...)
    local start = args[1]
    local deleteCount = args[2]
    if start < 0 then
        start = len + start
        if start < 0 then
            start = 0
        end
    elseif start > len then
        start = len
    end
    local itemCount = actualArgumentCount - 2
    if itemCount < 0 then
        itemCount = 0
    end
    local actualDeleteCount
    if actualArgumentCount == 0 then
        actualDeleteCount = 0
    elseif actualArgumentCount == 1 then
        actualDeleteCount = len - start
    else
        actualDeleteCount = deleteCount or 0
        if actualDeleteCount < 0 then
            actualDeleteCount = 0
        end
        if actualDeleteCount > len - start then
            actualDeleteCount = len - start
        end
    end
    local out = {}
    for k = 1, actualDeleteCount do
        local from = start + k
        if self[from] ~= nil then
            out[k] = self[from]
        end
    end
    if itemCount < actualDeleteCount then
        for k = start + 1, len - actualDeleteCount do
            local from = k + actualDeleteCount
            local to = k + itemCount
            if self[from] then
                self[to] = self[from]
            else
                self[to] = nil
            end
        end
        for k = len - actualDeleteCount + itemCount + 1, len do
            self[k] = nil
        end
    elseif itemCount > actualDeleteCount then
        for k = len - actualDeleteCount, start + 1, -1 do
            local from = k + actualDeleteCount
            local to = k + itemCount
            if self[from] then
                self[to] = self[from]
            else
                self[to] = nil
            end
        end
    end
    local j = start + 1
    for i = 3, actualArgumentCount do
        self[j] = args[i]
        j = j + 1
    end
    for k = #self, len - actualDeleteCount + itemCount + 1, -1 do
        self[k] = nil
    end
    return out
end

local function __TS__ArrayToObject(self)
    local object = {}
    for i = 1, #self do
        object[i - 1] = self[i]
    end
    return object
end

local function __TS__ArrayFlat(self, depth)
    if depth == nil then
        depth = 1
    end
    local result = {}
    local len = 0
    for i = 1, #self do
        local value = self[i]
        if depth > 0 and __TS__ArrayIsArray(value) then
            local toAdd
            if depth == 1 then
                toAdd = value
            else
                toAdd = __TS__ArrayFlat(value, depth - 1)
            end
            for j = 1, #toAdd do
                local val = toAdd[j]
                len = len + 1
                result[len] = val
            end
        else
            len = len + 1
            result[len] = value
        end
    end
    return result
end

local function __TS__ArrayFlatMap(self, callback, thisArg)
    local result = {}
    local len = 0
    for i = 1, #self do
        local value = callback(thisArg, self[i], i - 1, self)
        if __TS__ArrayIsArray(value) then
            for j = 1, #value do
                len = len + 1
                result[len] = value[j]
            end
        else
            len = len + 1
            result[len] = value
        end
    end
    return result
end

local function __TS__ArraySetLength(self, length)
    if length < 0 or length ~= length or length == math.huge or math.floor(length) ~= length then
        error(
            "invalid array length: " .. tostring(length),
            0
        )
    end
    for i = length + 1, #self do
        self[i] = nil
    end
    return length
end

local __TS__Unpack = table.unpack or unpack

local function __TS__ArrayToReversed(self)
    local copy = {__TS__Unpack(self)}
    __TS__ArrayReverse(copy)
    return copy
end

local function __TS__ArrayToSorted(self, compareFn)
    local copy = {__TS__Unpack(self)}
    __TS__ArraySort(copy, compareFn)
    return copy
end

local function __TS__ArrayToSpliced(self, start, deleteCount, ...)
    local copy = {__TS__Unpack(self)}
    __TS__ArraySplice(copy, start, deleteCount, ...)
    return copy
end

local function __TS__ArrayWith(self, index, value)
    local copy = {__TS__Unpack(self)}
    copy[index + 1] = value
    return copy
end

local function __TS__New(target, ...)
    local instance = setmetatable({}, target.prototype)
    instance:____constructor(...)
    return instance
end

local function __TS__InstanceOf(obj, classTbl)
    if type(classTbl) ~= "table" then
        error("Right-hand side of 'instanceof' is not an object", 0)
    end
    if classTbl[Symbol.hasInstance] ~= nil then
        return not not classTbl[Symbol.hasInstance](classTbl, obj)
    end
    if type(obj) == "table" then
        local luaClass = obj.constructor
        while luaClass ~= nil do
            if luaClass == classTbl then
                return true
            end
            luaClass = luaClass.____super
        end
    end
    return false
end

local function __TS__Class(self)
    local c = {prototype = {}}
    c.prototype.__index = c.prototype
    c.prototype.constructor = c
    return c
end

local __TS__Promise
do
    local function makeDeferredPromiseFactory()
        local resolve
        local reject
        local function executor(____, res, rej)
            resolve = res
            reject = rej
        end
        return function()
            local promise = __TS__New(__TS__Promise, executor)
            return promise, resolve, reject
        end
    end
    local makeDeferredPromise = makeDeferredPromiseFactory()
    local function isPromiseLike(value)
        return __TS__InstanceOf(value, __TS__Promise)
    end
    local function doNothing(self)
    end
    local ____pcall = _G.pcall
    __TS__Promise = __TS__Class()
    __TS__Promise.name = "__TS__Promise"
    function __TS__Promise.prototype.____constructor(self, executor)
        self.state = 0
        self.fulfilledCallbacks = {}
        self.rejectedCallbacks = {}
        self.finallyCallbacks = {}
        local success, ____error = ____pcall(
            executor,
            nil,
            function(____, v) return self:resolve(v) end,
            function(____, err) return self:reject(err) end
        )
        if not success then
            self:reject(____error)
        end
    end
    function __TS__Promise.resolve(value)
        if __TS__InstanceOf(value, __TS__Promise) then
            return value
        end
        local promise = __TS__New(__TS__Promise, doNothing)
        promise.state = 1
        promise.value = value
        return promise
    end
    function __TS__Promise.reject(reason)
        local promise = __TS__New(__TS__Promise, doNothing)
        promise.state = 2
        promise.rejectionReason = reason
        return promise
    end
    __TS__Promise.prototype["then"] = function(self, onFulfilled, onRejected)
        local promise, resolve, reject = makeDeferredPromise()
        self:addCallbacks(
            onFulfilled and self:createPromiseResolvingCallback(onFulfilled, resolve, reject) or resolve,
            onRejected and self:createPromiseResolvingCallback(onRejected, resolve, reject) or reject
        )
        return promise
    end
    function __TS__Promise.prototype.addCallbacks(self, fulfilledCallback, rejectedCallback)
        if self.state == 1 then
            return fulfilledCallback(nil, self.value)
        end
        if self.state == 2 then
            return rejectedCallback(nil, self.rejectionReason)
        end
        local ____self_fulfilledCallbacks_0 = self.fulfilledCallbacks
        ____self_fulfilledCallbacks_0[#____self_fulfilledCallbacks_0 + 1] = fulfilledCallback
        local ____self_rejectedCallbacks_1 = self.rejectedCallbacks
        ____self_rejectedCallbacks_1[#____self_rejectedCallbacks_1 + 1] = rejectedCallback
    end
    function __TS__Promise.prototype.catch(self, onRejected)
        return self["then"](self, nil, onRejected)
    end
    function __TS__Promise.prototype.finally(self, onFinally)
        if onFinally then
            local ____self_finallyCallbacks_2 = self.finallyCallbacks
            ____self_finallyCallbacks_2[#____self_finallyCallbacks_2 + 1] = onFinally
            if self.state ~= 0 then
                onFinally(nil)
            end
        end
        return self
    end
    function __TS__Promise.prototype.resolve(self, value)
        if isPromiseLike(value) then
            return value:addCallbacks(
                function(____, v) return self:resolve(v) end,
                function(____, err) return self:reject(err) end
            )
        end
        if self.state == 0 then
            self.state = 1
            self.value = value
            return self:invokeCallbacks(self.fulfilledCallbacks, value)
        end
    end
    function __TS__Promise.prototype.reject(self, reason)
        if self.state == 0 then
            self.state = 2
            self.rejectionReason = reason
            return self:invokeCallbacks(self.rejectedCallbacks, reason)
        end
    end
    function __TS__Promise.prototype.invokeCallbacks(self, callbacks, value)
        local callbacksLength = #callbacks
        local finallyCallbacks = self.finallyCallbacks
        local finallyCallbacksLength = #finallyCallbacks
        if callbacksLength ~= 0 then
            for i = 1, callbacksLength - 1 do
                callbacks[i](callbacks, value)
            end
            if finallyCallbacksLength == 0 then
                return callbacks[callbacksLength](callbacks, value)
            end
            callbacks[callbacksLength](callbacks, value)
        end
        if finallyCallbacksLength ~= 0 then
            for i = 1, finallyCallbacksLength - 1 do
                finallyCallbacks[i](finallyCallbacks)
            end
            return finallyCallbacks[finallyCallbacksLength](finallyCallbacks)
        end
    end
    function __TS__Promise.prototype.createPromiseResolvingCallback(self, f, resolve, reject)
        return function(____, value)
            local success, resultOrError = ____pcall(f, nil, value)
            if not success then
                return reject(nil, resultOrError)
            end
            return self:handleCallbackValue(resultOrError, resolve, reject)
        end
    end
    function __TS__Promise.prototype.handleCallbackValue(self, value, resolve, reject)
        if isPromiseLike(value) then
            local nextpromise = value
            if nextpromise.state == 1 then
                return resolve(nil, nextpromise.value)
            elseif nextpromise.state == 2 then
                return reject(nil, nextpromise.rejectionReason)
            else
                return nextpromise:addCallbacks(resolve, reject)
            end
        else
            return resolve(nil, value)
        end
    end
end

local __TS__AsyncAwaiter, __TS__Await
do
    local ____coroutine = _G.coroutine or ({})
    local cocreate = ____coroutine.create
    local coresume = ____coroutine.resume
    local costatus = ____coroutine.status
    local coyield = ____coroutine.yield
    function __TS__AsyncAwaiter(generator)
        return __TS__New(
            __TS__Promise,
            function(____, resolve, reject)
                local fulfilled, step, resolved, asyncCoroutine
                function fulfilled(self, value)
                    local success, resultOrError = coresume(asyncCoroutine, value)
                    if success then
                        return step(resultOrError)
                    end
                    return reject(nil, resultOrError)
                end
                function step(result)
                    if resolved then
                        return
                    end
                    if costatus(asyncCoroutine) == "dead" then
                        return resolve(nil, result)
                    end
                    return __TS__Promise.resolve(result):addCallbacks(fulfilled, reject)
                end
                resolved = false
                asyncCoroutine = cocreate(generator)
                local success, resultOrError = coresume(
                    asyncCoroutine,
                    function(____, v)
                        resolved = true
                        return __TS__Promise.resolve(v):addCallbacks(resolve, reject)
                    end
                )
                if success then
                    return step(resultOrError)
                else
                    return reject(nil, resultOrError)
                end
            end
        )
    end
    function __TS__Await(thing)
        return coyield(thing)
    end
end

local function __TS__ClassExtends(target, base)
    target.____super = base
    local staticMetatable = setmetatable({__index = base}, base)
    setmetatable(target, staticMetatable)
    local baseMetatable = getmetatable(base)
    if baseMetatable then
        if type(baseMetatable.__index) == "function" then
            staticMetatable.__index = baseMetatable.__index
        end
        if type(baseMetatable.__newindex) == "function" then
            staticMetatable.__newindex = baseMetatable.__newindex
        end
    end
    setmetatable(target.prototype, base.prototype)
    if type(base.prototype.__index) == "function" then
        target.prototype.__index = base.prototype.__index
    end
    if type(base.prototype.__newindex) == "function" then
        target.prototype.__newindex = base.prototype.__newindex
    end
    if type(base.prototype.__tostring) == "function" then
        target.prototype.__tostring = base.prototype.__tostring
    end
end

local function __TS__CloneDescriptor(____bindingPattern0)
    local value
    local writable
    local set
    local get
    local configurable
    local enumerable
    enumerable = ____bindingPattern0.enumerable
    configurable = ____bindingPattern0.configurable
    get = ____bindingPattern0.get
    set = ____bindingPattern0.set
    writable = ____bindingPattern0.writable
    value = ____bindingPattern0.value
    local descriptor = {enumerable = enumerable == true, configurable = configurable == true}
    local hasGetterOrSetter = get ~= nil or set ~= nil
    local hasValueOrWritableAttribute = writable ~= nil or value ~= nil
    if hasGetterOrSetter and hasValueOrWritableAttribute then
        error("Invalid property descriptor. Cannot both specify accessors and a value or writable attribute.", 0)
    end
    if get or set then
        descriptor.get = get
        descriptor.set = set
    else
        descriptor.value = value
        descriptor.writable = writable == true
    end
    return descriptor
end

local function __TS__Decorate(self, originalValue, decorators, context)
    local result = originalValue
    do
        local i = #decorators
        while i >= 0 do
            local decorator = decorators[i + 1]
            if decorator ~= nil then
                local ____decorator_result_0 = decorator(self, result, context)
                if ____decorator_result_0 == nil then
                    ____decorator_result_0 = result
                end
                result = ____decorator_result_0
            end
            i = i - 1
        end
    end
    return result
end

local function __TS__ObjectAssign(target, ...)
    local sources = {...}
    for i = 1, #sources do
        local source = sources[i]
        for key in pairs(source) do
            target[key] = source[key]
        end
    end
    return target
end

local function __TS__ObjectGetOwnPropertyDescriptor(object, key)
    local metatable = getmetatable(object)
    if not metatable then
        return
    end
    if not rawget(metatable, "_descriptors") then
        return
    end
    return rawget(metatable, "_descriptors")[key]
end

local __TS__DescriptorGet
do
    local getmetatable = _G.getmetatable
    local ____rawget = _G.rawget
    function __TS__DescriptorGet(self, metatable, key)
        while metatable do
            local rawResult = ____rawget(metatable, key)
            if rawResult ~= nil then
                return rawResult
            end
            local descriptors = ____rawget(metatable, "_descriptors")
            if descriptors then
                local descriptor = descriptors[key]
                if descriptor ~= nil then
                    if descriptor.get then
                        return descriptor.get(self)
                    end
                    return descriptor.value
                end
            end
            metatable = getmetatable(metatable)
        end
    end
end

local __TS__DescriptorSet
do
    local getmetatable = _G.getmetatable
    local ____rawget = _G.rawget
    local rawset = _G.rawset
    function __TS__DescriptorSet(self, metatable, key, value)
        while metatable do
            local descriptors = ____rawget(metatable, "_descriptors")
            if descriptors then
                local descriptor = descriptors[key]
                if descriptor ~= nil then
                    if descriptor.set then
                        descriptor.set(self, value)
                    else
                        if descriptor.writable == false then
                            error(
                                ((("Cannot assign to read only property '" .. key) .. "' of object '") .. tostring(self)) .. "'",
                                0
                            )
                        end
                        descriptor.value = value
                    end
                    return
                end
            end
            metatable = getmetatable(metatable)
        end
        rawset(self, key, value)
    end
end

local __TS__SetDescriptor
do
    local getmetatable = _G.getmetatable
    local function descriptorIndex(self, key)
        return __TS__DescriptorGet(
            self,
            getmetatable(self),
            key
        )
    end
    local function descriptorNewIndex(self, key, value)
        return __TS__DescriptorSet(
            self,
            getmetatable(self),
            key,
            value
        )
    end
    function __TS__SetDescriptor(target, key, desc, isPrototype)
        if isPrototype == nil then
            isPrototype = false
        end
        local ____isPrototype_0
        if isPrototype then
            ____isPrototype_0 = target
        else
            ____isPrototype_0 = getmetatable(target)
        end
        local metatable = ____isPrototype_0
        if not metatable then
            metatable = {}
            setmetatable(target, metatable)
        end
        local value = rawget(target, key)
        if value ~= nil then
            rawset(target, key, nil)
        end
        if not rawget(metatable, "_descriptors") then
            metatable._descriptors = {}
        end
        metatable._descriptors[key] = __TS__CloneDescriptor(desc)
        metatable.__index = descriptorIndex
        metatable.__newindex = descriptorNewIndex
    end
end

local function __TS__DecorateLegacy(decorators, target, key, desc)
    local result = target
    do
        local i = #decorators
        while i >= 0 do
            local decorator = decorators[i + 1]
            if decorator ~= nil then
                local oldResult = result
                if key == nil then
                    result = decorator(nil, result)
                elseif desc == true then
                    local value = rawget(target, key)
                    local descriptor = __TS__ObjectGetOwnPropertyDescriptor(target, key) or ({configurable = true, writable = true, value = value})
                    local desc = decorator(nil, target, key, descriptor) or descriptor
                    local isSimpleValue = desc.configurable == true and desc.writable == true and not desc.get and not desc.set
                    if isSimpleValue then
                        rawset(target, key, desc.value)
                    else
                        __TS__SetDescriptor(
                            target,
                            key,
                            __TS__ObjectAssign({}, descriptor, desc)
                        )
                    end
                elseif desc == false then
                    result = decorator(nil, target, key, desc)
                else
                    result = decorator(nil, target, key)
                end
                result = result or oldResult
            end
            i = i - 1
        end
    end
    return result
end

local function __TS__DecorateParam(paramIndex, decorator)
    return function(____, target, key) return decorator(nil, target, key, paramIndex) end
end

local function __TS__StringIncludes(self, searchString, position)
    if not position then
        position = 1
    else
        position = position + 1
    end
    local index = string.find(self, searchString, position, true)
    return index ~= nil
end

local Error, RangeError, ReferenceError, SyntaxError, TypeError, URIError
do
    local function getErrorStack(self, constructor)
        if debug == nil then
            return nil
        end
        local level = 1
        while true do
            local info = debug.getinfo(level, "f")
            level = level + 1
            if not info then
                level = 1
                break
            elseif info.func == constructor then
                break
            end
        end
        if __TS__StringIncludes(_VERSION, "Lua 5.0") then
            return debug.traceback(("[Level " .. tostring(level)) .. "]")
        elseif _VERSION == "Lua 5.1" then
            return string.sub(
                debug.traceback("", level),
                2
            )
        else
            return debug.traceback(nil, level)
        end
    end
    local function wrapErrorToString(self, getDescription)
        return function(self)
            local description = getDescription(self)
            local caller = debug.getinfo(3, "f")
            local isClassicLua = __TS__StringIncludes(_VERSION, "Lua 5.0")
            if isClassicLua or caller and caller.func ~= error then
                return description
            else
                return (description .. "\n") .. tostring(self.stack)
            end
        end
    end
    local function initErrorClass(self, Type, name)
        Type.name = name
        return setmetatable(
            Type,
            {__call = function(____, _self, message) return __TS__New(Type, message) end}
        )
    end
    local ____initErrorClass_1 = initErrorClass
    local ____class_0 = __TS__Class()
    ____class_0.name = ""
    function ____class_0.prototype.____constructor(self, message)
        if message == nil then
            message = ""
        end
        self.message = message
        self.name = "Error"
        self.stack = getErrorStack(nil, __TS__New)
        local metatable = getmetatable(self)
        if metatable and not metatable.__errorToStringPatched then
            metatable.__errorToStringPatched = true
            metatable.__tostring = wrapErrorToString(nil, metatable.__tostring)
        end
    end
    function ____class_0.prototype.__tostring(self)
        return self.message ~= "" and (self.name .. ": ") .. self.message or self.name
    end
    Error = ____initErrorClass_1(nil, ____class_0, "Error")
    local function createErrorClass(self, name)
        local ____initErrorClass_3 = initErrorClass
        local ____class_2 = __TS__Class()
        ____class_2.name = ____class_2.name
        __TS__ClassExtends(____class_2, Error)
        function ____class_2.prototype.____constructor(self, ...)
            ____class_2.____super.prototype.____constructor(self, ...)
            self.name = name
        end
        return ____initErrorClass_3(nil, ____class_2, name)
    end
    RangeError = createErrorClass(nil, "RangeError")
    ReferenceError = createErrorClass(nil, "ReferenceError")
    SyntaxError = createErrorClass(nil, "SyntaxError")
    TypeError = createErrorClass(nil, "TypeError")
    URIError = createErrorClass(nil, "URIError")
end

local function __TS__ObjectGetOwnPropertyDescriptors(object)
    local metatable = getmetatable(object)
    if not metatable then
        return {}
    end
    return rawget(metatable, "_descriptors") or ({})
end

local function __TS__Delete(target, key)
    local descriptors = __TS__ObjectGetOwnPropertyDescriptors(target)
    local descriptor = descriptors[key]
    if descriptor then
        if not descriptor.configurable then
            error(
                __TS__New(
                    TypeError,
                    ((("Cannot delete property " .. tostring(key)) .. " of ") .. tostring(target)) .. "."
                ),
                0
            )
        end
        descriptors[key] = nil
        return true
    end
    target[key] = nil
    return true
end

local function __TS__StringAccess(self, index)
    if index >= 0 and index < #self then
        return string.sub(self, index + 1, index + 1)
    end
end

local function __TS__DelegatedYield(iterable)
    if type(iterable) == "string" then
        for index = 0, #iterable - 1 do
            coroutine.yield(__TS__StringAccess(iterable, index))
        end
    elseif iterable.____coroutine ~= nil then
        local co = iterable.____coroutine
        while true do
            local status, value = coroutine.resume(co)
            if not status then
                error(value, 0)
            end
            if coroutine.status(co) == "dead" then
                return value
            else
                coroutine.yield(value)
            end
        end
    elseif iterable[Symbol.iterator] then
        local iterator = iterable[Symbol.iterator](iterable)
        while true do
            local result = iterator:next()
            if result.done then
                return result.value
            else
                coroutine.yield(result.value)
            end
        end
    else
        for ____, value in ipairs(iterable) do
            coroutine.yield(value)
        end
    end
end

local function __TS__FunctionBind(fn, ...)
    local boundArgs = {...}
    return function(____, ...)
        local args = {...}
        __TS__ArrayUnshift(
            args,
            __TS__Unpack(boundArgs)
        )
        return fn(__TS__Unpack(args))
    end
end

local __TS__Generator
do
    local function generatorIterator(self)
        return self
    end
    local function generatorNext(self, ...)
        local co = self.____coroutine
        if coroutine.status(co) == "dead" then
            return {done = true}
        end
        local status, value = coroutine.resume(co, ...)
        if not status then
            error(value, 0)
        end
        return {
            value = value,
            done = coroutine.status(co) == "dead"
        }
    end
    function __TS__Generator(fn)
        return function(...)
            local args = {...}
            local argsLength = __TS__CountVarargs(...)
            return {
                ____coroutine = coroutine.create(function() return fn(__TS__Unpack(args, 1, argsLength)) end),
                [Symbol.iterator] = generatorIterator,
                next = generatorNext
            }
        end
    end
end

local function __TS__InstanceOfObject(value)
    local valueType = type(value)
    return valueType == "table" or valueType == "function"
end

local function __TS__LuaIteratorSpread(self, state, firstKey)
    local results = {}
    local key, value = self(state, firstKey)
    while key do
        results[#results + 1] = {key, value}
        key, value = self(state, key)
    end
    return __TS__Unpack(results)
end

local Map
do
    Map = __TS__Class()
    Map.name = "Map"
    function Map.prototype.____constructor(self, entries)
        self[Symbol.toStringTag] = "Map"
        self.items = {}
        self.size = 0
        self.nextKey = {}
        self.previousKey = {}
        if entries == nil then
            return
        end
        local iterable = entries
        if iterable[Symbol.iterator] then
            local iterator = iterable[Symbol.iterator](iterable)
            while true do
                local result = iterator:next()
                if result.done then
                    break
                end
                local value = result.value
                self:set(value[1], value[2])
            end
        else
            local array = entries
            for ____, kvp in ipairs(array) do
                self:set(kvp[1], kvp[2])
            end
        end
    end
    function Map.prototype.clear(self)
        self.items = {}
        self.nextKey = {}
        self.previousKey = {}
        self.firstKey = nil
        self.lastKey = nil
        self.size = 0
    end
    function Map.prototype.delete(self, key)
        local contains = self:has(key)
        if contains then
            self.size = self.size - 1
            local next = self.nextKey[key]
            local previous = self.previousKey[key]
            if next ~= nil and previous ~= nil then
                self.nextKey[previous] = next
                self.previousKey[next] = previous
            elseif next ~= nil then
                self.firstKey = next
                self.previousKey[next] = nil
            elseif previous ~= nil then
                self.lastKey = previous
                self.nextKey[previous] = nil
            else
                self.firstKey = nil
                self.lastKey = nil
            end
            self.nextKey[key] = nil
            self.previousKey[key] = nil
        end
        self.items[key] = nil
        return contains
    end
    function Map.prototype.forEach(self, callback)
        for ____, key in __TS__Iterator(self:keys()) do
            callback(nil, self.items[key], key, self)
        end
    end
    function Map.prototype.get(self, key)
        return self.items[key]
    end
    function Map.prototype.has(self, key)
        return self.nextKey[key] ~= nil or self.lastKey == key
    end
    function Map.prototype.set(self, key, value)
        local isNewValue = not self:has(key)
        if isNewValue then
            self.size = self.size + 1
        end
        self.items[key] = value
        if self.firstKey == nil then
            self.firstKey = key
            self.lastKey = key
        elseif isNewValue then
            self.nextKey[self.lastKey] = key
            self.previousKey[key] = self.lastKey
            self.lastKey = key
        end
        return self
    end
    Map.prototype[Symbol.iterator] = function(self)
        return self:entries()
    end
    function Map.prototype.entries(self)
        local items = self.items
        local nextKey = self.nextKey
        local key = self.firstKey
        return {
            [Symbol.iterator] = function(self)
                return self
            end,
            next = function(self)
                local result = {done = not key, value = {key, items[key]}}
                key = nextKey[key]
                return result
            end
        }
    end
    function Map.prototype.keys(self)
        local nextKey = self.nextKey
        local key = self.firstKey
        return {
            [Symbol.iterator] = function(self)
                return self
            end,
            next = function(self)
                local result = {done = not key, value = key}
                key = nextKey[key]
                return result
            end
        }
    end
    function Map.prototype.values(self)
        local items = self.items
        local nextKey = self.nextKey
        local key = self.firstKey
        return {
            [Symbol.iterator] = function(self)
                return self
            end,
            next = function(self)
                local result = {done = not key, value = items[key]}
                key = nextKey[key]
                return result
            end
        }
    end
    Map[Symbol.species] = Map
end

local function __TS__MapGroupBy(items, keySelector)
    local result = __TS__New(Map)
    local i = 0
    for ____, item in __TS__Iterator(items) do
        local key = keySelector(nil, item, i)
        if result:has(key) then
            local ____temp_0 = result:get(key)
            ____temp_0[#____temp_0 + 1] = item
        else
            result:set(key, {item})
        end
        i = i + 1
    end
    return result
end

local __TS__Match = string.match

local __TS__MathAtan2 = math.atan2 or math.atan

local __TS__MathModf = math.modf

local function __TS__NumberIsNaN(value)
    return value ~= value
end

local function __TS__MathSign(val)
    if __TS__NumberIsNaN(val) or val == 0 then
        return val
    end
    if val < 0 then
        return -1
    end
    return 1
end

local function __TS__NumberIsFinite(value)
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function __TS__MathTrunc(val)
    if not __TS__NumberIsFinite(val) or val == 0 then
        return val
    end
    return val > 0 and math.floor(val) or math.ceil(val)
end

local function __TS__Number(value)
    local valueType = type(value)
    if valueType == "number" then
        return value
    elseif valueType == "string" then
        local numberValue = tonumber(value)
        if numberValue then
            return numberValue
        end
        if value == "Infinity" then
            return math.huge
        end
        if value == "-Infinity" then
            return -math.huge
        end
        local stringWithoutSpaces = string.gsub(value, "%s", "")
        if stringWithoutSpaces == "" then
            return 0
        end
        return 0 / 0
    elseif valueType == "boolean" then
        return value and 1 or 0
    else
        return 0 / 0
    end
end

local function __TS__NumberIsInteger(value)
    return __TS__NumberIsFinite(value) and math.floor(value) == value
end

local function __TS__StringSubstring(self, start, ____end)
    if ____end ~= ____end then
        ____end = 0
    end
    if ____end ~= nil and start > ____end then
        start, ____end = ____end, start
    end
    if start >= 0 then
        start = start + 1
    else
        start = 1
    end
    if ____end ~= nil and ____end < 0 then
        ____end = 0
    end
    return string.sub(self, start, ____end)
end

local __TS__ParseInt
do
    local parseIntBasePattern = "0123456789aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTvVwWxXyYzZ"
    function __TS__ParseInt(numberString, base)
        if base == nil then
            base = 10
            local hexMatch = __TS__Match(numberString, "^%s*-?0[xX]")
            if hexMatch ~= nil then
                base = 16
                numberString = (__TS__Match(hexMatch, "-")) and "-" .. __TS__StringSubstring(numberString, #hexMatch) or __TS__StringSubstring(numberString, #hexMatch)
            end
        end
        if base < 2 or base > 36 then
            return 0 / 0
        end
        local allowedDigits = base <= 10 and __TS__StringSubstring(parseIntBasePattern, 0, base) or __TS__StringSubstring(parseIntBasePattern, 0, 10 + 2 * (base - 10))
        local pattern = ("^%s*(-?[" .. allowedDigits) .. "]*)"
        local number = tonumber((__TS__Match(numberString, pattern)), base)
        if number == nil then
            return 0 / 0
        end
        if number >= 0 then
            return math.floor(number)
        else
            return math.ceil(number)
        end
    end
end

local function __TS__ParseFloat(numberString)
    local infinityMatch = __TS__Match(numberString, "^%s*(-?Infinity)")
    if infinityMatch ~= nil then
        return __TS__StringAccess(infinityMatch, 0) == "-" and -math.huge or math.huge
    end
    local number = tonumber((__TS__Match(numberString, "^%s*(-?%d+%.?%d*)")))
    return number or 0 / 0
end

local __TS__NumberToString
do
    local radixChars = "0123456789abcdefghijklmnopqrstuvwxyz"
    function __TS__NumberToString(self, radix)
        if radix == nil or radix == 10 or self == math.huge or self == -math.huge or self ~= self then
            return tostring(self)
        end
        radix = math.floor(radix)
        if radix < 2 or radix > 36 then
            error("toString() radix argument must be between 2 and 36", 0)
        end
        local integer, fraction = __TS__MathModf(math.abs(self))
        local result = ""
        if radix == 8 then
            result = string.format("%o", integer)
        elseif radix == 16 then
            result = string.format("%x", integer)
        else
            repeat
                do
                    result = __TS__StringAccess(radixChars, integer % radix) .. result
                    integer = math.floor(integer / radix)
                end
            until not (integer ~= 0)
        end
        if fraction ~= 0 then
            result = result .. "."
            local delta = 1e-16
            repeat
                do
                    fraction = fraction * radix
                    delta = delta * radix
                    local digit = math.floor(fraction)
                    result = result .. __TS__StringAccess(radixChars, digit)
                    fraction = fraction - digit
                end
            until not (fraction >= delta)
        end
        if self < 0 then
            result = "-" .. result
        end
        return result
    end
end

local function __TS__NumberToFixed(self, fractionDigits)
    if math.abs(self) >= 1e+21 or self ~= self then
        return tostring(self)
    end
    local f = math.floor(fractionDigits or 0)
    if f < 0 or f > 99 then
        error("toFixed() digits argument must be between 0 and 99", 0)
    end
    return string.format(
        ("%." .. tostring(f)) .. "f",
        self
    )
end

local function __TS__ObjectDefineProperty(target, key, desc)
    local luaKey = type(key) == "number" and key + 1 or key
    local value = rawget(target, luaKey)
    local hasGetterOrSetter = desc.get ~= nil or desc.set ~= nil
    local descriptor
    if hasGetterOrSetter then
        if value ~= nil then
            error(
                "Cannot redefine property: " .. tostring(key),
                0
            )
        end
        descriptor = desc
    else
        local valueExists = value ~= nil
        local ____desc_set_4 = desc.set
        local ____desc_get_5 = desc.get
        local ____desc_configurable_0 = desc.configurable
        if ____desc_configurable_0 == nil then
            ____desc_configurable_0 = valueExists
        end
        local ____desc_enumerable_1 = desc.enumerable
        if ____desc_enumerable_1 == nil then
            ____desc_enumerable_1 = valueExists
        end
        local ____desc_writable_2 = desc.writable
        if ____desc_writable_2 == nil then
            ____desc_writable_2 = valueExists
        end
        local ____temp_3
        if desc.value ~= nil then
            ____temp_3 = desc.value
        else
            ____temp_3 = value
        end
        descriptor = {
            set = ____desc_set_4,
            get = ____desc_get_5,
            configurable = ____desc_configurable_0,
            enumerable = ____desc_enumerable_1,
            writable = ____desc_writable_2,
            value = ____temp_3
        }
    end
    __TS__SetDescriptor(target, luaKey, descriptor)
    return target
end

local function __TS__ObjectEntries(obj)
    local result = {}
    local len = 0
    for key in pairs(obj) do
        len = len + 1
        result[len] = {key, obj[key]}
    end
    return result
end

local function __TS__ObjectFromEntries(entries)
    local obj = {}
    local iterable = entries
    if iterable[Symbol.iterator] then
        local iterator = iterable[Symbol.iterator](iterable)
        while true do
            local result = iterator:next()
            if result.done then
                break
            end
            local value = result.value
            obj[value[1]] = value[2]
        end
    else
        for ____, entry in ipairs(entries) do
            obj[entry[1]] = entry[2]
        end
    end
    return obj
end

local function __TS__ObjectGroupBy(items, keySelector)
    local result = {}
    local i = 0
    for ____, item in __TS__Iterator(items) do
        local key = keySelector(nil, item, i)
        if result[key] ~= nil then
            local ____result_key_0 = result[key]
            ____result_key_0[#____result_key_0 + 1] = item
        else
            result[key] = {item}
        end
        i = i + 1
    end
    return result
end

local function __TS__ObjectKeys(obj)
    local result = {}
    local len = 0
    for key in pairs(obj) do
        len = len + 1
        result[len] = key
    end
    return result
end

local function __TS__ObjectRest(target, usedProperties)
    local result = {}
    for property in pairs(target) do
        if not usedProperties[property] then
            result[property] = target[property]
        end
    end
    return result
end

local function __TS__ObjectValues(obj)
    local result = {}
    local len = 0
    for key in pairs(obj) do
        len = len + 1
        result[len] = obj[key]
    end
    return result
end

local function __TS__PromiseAll(iterable)
    local results = {}
    local toResolve = {}
    local numToResolve = 0
    local i = 0
    for ____, item in __TS__Iterator(iterable) do
        if __TS__InstanceOf(item, __TS__Promise) then
            if item.state == 1 then
                results[i + 1] = item.value
            elseif item.state == 2 then
                return __TS__Promise.reject(item.rejectionReason)
            else
                numToResolve = numToResolve + 1
                toResolve[i] = item
            end
        else
            results[i + 1] = item
        end
        i = i + 1
    end
    if numToResolve == 0 then
        return __TS__Promise.resolve(results)
    end
    return __TS__New(
        __TS__Promise,
        function(____, resolve, reject)
            for index, promise in pairs(toResolve) do
                promise["then"](
                    promise,
                    function(____, data)
                        results[index + 1] = data
                        numToResolve = numToResolve - 1
                        if numToResolve == 0 then
                            resolve(nil, results)
                        end
                    end,
                    function(____, reason)
                        reject(nil, reason)
                    end
                )
            end
        end
    )
end

local function __TS__PromiseAllSettled(iterable)
    local results = {}
    local toResolve = {}
    local numToResolve = 0
    local i = 0
    for ____, item in __TS__Iterator(iterable) do
        if __TS__InstanceOf(item, __TS__Promise) then
            if item.state == 1 then
                results[i + 1] = {status = "fulfilled", value = item.value}
            elseif item.state == 2 then
                results[i + 1] = {status = "rejected", reason = item.rejectionReason}
            else
                numToResolve = numToResolve + 1
                toResolve[i] = item
            end
        else
            results[i + 1] = {status = "fulfilled", value = item}
        end
        i = i + 1
    end
    if numToResolve == 0 then
        return __TS__Promise.resolve(results)
    end
    return __TS__New(
        __TS__Promise,
        function(____, resolve)
            for index, promise in pairs(toResolve) do
                promise["then"](
                    promise,
                    function(____, data)
                        results[index + 1] = {status = "fulfilled", value = data}
                        numToResolve = numToResolve - 1
                        if numToResolve == 0 then
                            resolve(nil, results)
                        end
                    end,
                    function(____, reason)
                        results[index + 1] = {status = "rejected", reason = reason}
                        numToResolve = numToResolve - 1
                        if numToResolve == 0 then
                            resolve(nil, results)
                        end
                    end
                )
            end
        end
    )
end

local function __TS__PromiseAny(iterable)
    local rejections = {}
    local pending = {}
    for ____, item in __TS__Iterator(iterable) do
        if __TS__InstanceOf(item, __TS__Promise) then
            if item.state == 1 then
                return __TS__Promise.resolve(item.value)
            elseif item.state == 2 then
                rejections[#rejections + 1] = item.rejectionReason
            else
                pending[#pending + 1] = item
            end
        else
            return __TS__Promise.resolve(item)
        end
    end
    if #pending == 0 then
        return __TS__Promise.reject("No promises to resolve with .any()")
    end
    local numResolved = 0
    return __TS__New(
        __TS__Promise,
        function(____, resolve, reject)
            for ____, promise in ipairs(pending) do
                promise["then"](
                    promise,
                    function(____, data)
                        resolve(nil, data)
                    end,
                    function(____, reason)
                        rejections[#rejections + 1] = reason
                        numResolved = numResolved + 1
                        if numResolved == #pending then
                            reject(nil, {name = "AggregateError", message = "All Promises rejected", errors = rejections})
                        end
                    end
                )
            end
        end
    )
end

local function __TS__PromiseRace(iterable)
    local pending = {}
    for ____, item in __TS__Iterator(iterable) do
        if __TS__InstanceOf(item, __TS__Promise) then
            if item.state == 1 then
                return __TS__Promise.resolve(item.value)
            elseif item.state == 2 then
                return __TS__Promise.reject(item.rejectionReason)
            else
                pending[#pending + 1] = item
            end
        else
            return __TS__Promise.resolve(item)
        end
    end
    return __TS__New(
        __TS__Promise,
        function(____, resolve, reject)
            for ____, promise in ipairs(pending) do
                promise["then"](
                    promise,
                    function(____, value) return resolve(nil, value) end,
                    function(____, reason) return reject(nil, reason) end
                )
            end
        end
    )
end

local Set
do
    Set = __TS__Class()
    Set.name = "Set"
    function Set.prototype.____constructor(self, values)
        self[Symbol.toStringTag] = "Set"
        self.size = 0
        self.nextKey = {}
        self.previousKey = {}
        if values == nil then
            return
        end
        local iterable = values
        if iterable[Symbol.iterator] then
            local iterator = iterable[Symbol.iterator](iterable)
            while true do
                local result = iterator:next()
                if result.done then
                    break
                end
                self:add(result.value)
            end
        else
            local array = values
            for ____, value in ipairs(array) do
                self:add(value)
            end
        end
    end
    function Set.prototype.add(self, value)
        local isNewValue = not self:has(value)
        if isNewValue then
            self.size = self.size + 1
        end
        if self.firstKey == nil then
            self.firstKey = value
            self.lastKey = value
        elseif isNewValue then
            self.nextKey[self.lastKey] = value
            self.previousKey[value] = self.lastKey
            self.lastKey = value
        end
        return self
    end
    function Set.prototype.clear(self)
        self.nextKey = {}
        self.previousKey = {}
        self.firstKey = nil
        self.lastKey = nil
        self.size = 0
    end
    function Set.prototype.delete(self, value)
        local contains = self:has(value)
        if contains then
            self.size = self.size - 1
            local next = self.nextKey[value]
            local previous = self.previousKey[value]
            if next ~= nil and previous ~= nil then
                self.nextKey[previous] = next
                self.previousKey[next] = previous
            elseif next ~= nil then
                self.firstKey = next
                self.previousKey[next] = nil
            elseif previous ~= nil then
                self.lastKey = previous
                self.nextKey[previous] = nil
            else
                self.firstKey = nil
                self.lastKey = nil
            end
            self.nextKey[value] = nil
            self.previousKey[value] = nil
        end
        return contains
    end
    function Set.prototype.forEach(self, callback)
        for ____, key in __TS__Iterator(self:keys()) do
            callback(nil, key, key, self)
        end
    end
    function Set.prototype.has(self, value)
        return self.nextKey[value] ~= nil or self.lastKey == value
    end
    Set.prototype[Symbol.iterator] = function(self)
        return self:values()
    end
    function Set.prototype.entries(self)
        local nextKey = self.nextKey
        local key = self.firstKey
        return {
            [Symbol.iterator] = function(self)
                return self
            end,
            next = function(self)
                local result = {done = not key, value = {key, key}}
                key = nextKey[key]
                return result
            end
        }
    end
    function Set.prototype.keys(self)
        local nextKey = self.nextKey
        local key = self.firstKey
        return {
            [Symbol.iterator] = function(self)
                return self
            end,
            next = function(self)
                local result = {done = not key, value = key}
                key = nextKey[key]
                return result
            end
        }
    end
    function Set.prototype.values(self)
        local nextKey = self.nextKey
        local key = self.firstKey
        return {
            [Symbol.iterator] = function(self)
                return self
            end,
            next = function(self)
                local result = {done = not key, value = key}
                key = nextKey[key]
                return result
            end
        }
    end
    function Set.prototype.union(self, other)
        local result = __TS__New(Set, self)
        for ____, item in __TS__Iterator(other) do
            result:add(item)
        end
        return result
    end
    function Set.prototype.intersection(self, other)
        local result = __TS__New(Set)
        for ____, item in __TS__Iterator(self) do
            if other:has(item) then
                result:add(item)
            end
        end
        return result
    end
    function Set.prototype.difference(self, other)
        local result = __TS__New(Set, self)
        for ____, item in __TS__Iterator(other) do
            result:delete(item)
        end
        return result
    end
    function Set.prototype.symmetricDifference(self, other)
        local result = __TS__New(Set, self)
        for ____, item in __TS__Iterator(other) do
            if self:has(item) then
                result:delete(item)
            else
                result:add(item)
            end
        end
        return result
    end
    function Set.prototype.isSubsetOf(self, other)
        for ____, item in __TS__Iterator(self) do
            if not other:has(item) then
                return false
            end
        end
        return true
    end
    function Set.prototype.isSupersetOf(self, other)
        for ____, item in __TS__Iterator(other) do
            if not self:has(item) then
                return false
            end
        end
        return true
    end
    function Set.prototype.isDisjointFrom(self, other)
        for ____, item in __TS__Iterator(self) do
            if other:has(item) then
                return false
            end
        end
        return true
    end
    Set[Symbol.species] = Set
end

local function __TS__SparseArrayNew(...)
    local sparseArray = {...}
    sparseArray.sparseLength = __TS__CountVarargs(...)
    return sparseArray
end

local function __TS__SparseArrayPush(sparseArray, ...)
    local args = {...}
    local argsLen = __TS__CountVarargs(...)
    local listLen = sparseArray.sparseLength
    for i = 1, argsLen do
        sparseArray[listLen + i] = args[i]
    end
    sparseArray.sparseLength = listLen + argsLen
end

local function __TS__SparseArraySpread(sparseArray)
    local _unpack = unpack or table.unpack
    return _unpack(sparseArray, 1, sparseArray.sparseLength)
end

local WeakMap
do
    WeakMap = __TS__Class()
    WeakMap.name = "WeakMap"
    function WeakMap.prototype.____constructor(self, entries)
        self[Symbol.toStringTag] = "WeakMap"
        self.items = {}
        setmetatable(self.items, {__mode = "k"})
        if entries == nil then
            return
        end
        local iterable = entries
        if iterable[Symbol.iterator] then
            local iterator = iterable[Symbol.iterator](iterable)
            while true do
                local result = iterator:next()
                if result.done then
                    break
                end
                local value = result.value
                self.items[value[1]] = value[2]
            end
        else
            for ____, kvp in ipairs(entries) do
                self.items[kvp[1]] = kvp[2]
            end
        end
    end
    function WeakMap.prototype.delete(self, key)
        local contains = self:has(key)
        self.items[key] = nil
        return contains
    end
    function WeakMap.prototype.get(self, key)
        return self.items[key]
    end
    function WeakMap.prototype.has(self, key)
        return self.items[key] ~= nil
    end
    function WeakMap.prototype.set(self, key, value)
        self.items[key] = value
        return self
    end
    WeakMap[Symbol.species] = WeakMap
end

local WeakSet
do
    WeakSet = __TS__Class()
    WeakSet.name = "WeakSet"
    function WeakSet.prototype.____constructor(self, values)
        self[Symbol.toStringTag] = "WeakSet"
        self.items = {}
        setmetatable(self.items, {__mode = "k"})
        if values == nil then
            return
        end
        local iterable = values
        if iterable[Symbol.iterator] then
            local iterator = iterable[Symbol.iterator](iterable)
            while true do
                local result = iterator:next()
                if result.done then
                    break
                end
                self.items[result.value] = true
            end
        else
            for ____, value in ipairs(values) do
                self.items[value] = true
            end
        end
    end
    function WeakSet.prototype.add(self, value)
        self.items[value] = true
        return self
    end
    function WeakSet.prototype.delete(self, value)
        local contains = self:has(value)
        self.items[value] = nil
        return contains
    end
    function WeakSet.prototype.has(self, value)
        return self.items[value] == true
    end
    WeakSet[Symbol.species] = WeakSet
end

local function __TS__SourceMapTraceBack(fileName, sourceMap)
    _G.__TS__sourcemap = _G.__TS__sourcemap or ({})
    _G.__TS__sourcemap[fileName] = sourceMap
    if _G.__TS__originalTraceback == nil then
        local originalTraceback = debug.traceback
        _G.__TS__originalTraceback = originalTraceback
        debug.traceback = function(thread, message, level)
            local trace
            if thread == nil and message == nil and level == nil then
                trace = originalTraceback()
            elseif __TS__StringIncludes(_VERSION, "Lua 5.0") then
                trace = originalTraceback((("[Level " .. tostring(level)) .. "] ") .. tostring(message))
            else
                trace = originalTraceback(thread, message, level)
            end
            if type(trace) ~= "string" then
                return trace
            end
            local function replacer(____, file, srcFile, line)
                local fileSourceMap = _G.__TS__sourcemap[file]
                if fileSourceMap ~= nil and fileSourceMap[line] ~= nil then
                    local data = fileSourceMap[line]
                    if type(data) == "number" then
                        return (srcFile .. ":") .. tostring(data)
                    end
                    return (data.file .. ":") .. tostring(data.line)
                end
                return (file .. ":") .. line
            end
            local result = string.gsub(
                trace,
                "([^%s<]+)%.lua:(%d+)",
                function(file, line) return replacer(nil, file .. ".lua", file .. ".ts", line) end
            )
            local function stringReplacer(____, file, line)
                local fileSourceMap = _G.__TS__sourcemap[file]
                if fileSourceMap ~= nil and fileSourceMap[line] ~= nil then
                    local chunkName = (__TS__Match(file, "%[string \"([^\"]+)\"%]"))
                    local sourceName = string.gsub(chunkName, ".lua$", ".ts")
                    local data = fileSourceMap[line]
                    if type(data) == "number" then
                        return (sourceName .. ":") .. tostring(data)
                    end
                    return (data.file .. ":") .. tostring(data.line)
                end
                return (file .. ":") .. line
            end
            result = string.gsub(
                result,
                "(%[string \"[^\"]+\"%]):(%d+)",
                function(file, line) return stringReplacer(nil, file, line) end
            )
            return result
        end
    end
end

local function __TS__Spread(iterable)
    local arr = {}
    if type(iterable) == "string" then
        for i = 0, #iterable - 1 do
            arr[i + 1] = __TS__StringAccess(iterable, i)
        end
    else
        local len = 0
        for ____, item in __TS__Iterator(iterable) do
            len = len + 1
            arr[len] = item
        end
    end
    return __TS__Unpack(arr)
end

local function __TS__StringCharAt(self, pos)
    if pos ~= pos then
        pos = 0
    end
    if pos < 0 then
        return ""
    end
    return string.sub(self, pos + 1, pos + 1)
end

local function __TS__StringCharCodeAt(self, index)
    if index ~= index then
        index = 0
    end
    if index < 0 then
        return 0 / 0
    end
    return string.byte(self, index + 1) or 0 / 0
end

local function __TS__StringEndsWith(self, searchString, endPosition)
    if endPosition == nil or endPosition > #self then
        endPosition = #self
    end
    return string.sub(self, endPosition - #searchString + 1, endPosition) == searchString
end

local function __TS__StringPadEnd(self, maxLength, fillString)
    if fillString == nil then
        fillString = " "
    end
    if maxLength ~= maxLength then
        maxLength = 0
    end
    if maxLength == -math.huge or maxLength == math.huge then
        error("Invalid string length", 0)
    end
    if #self >= maxLength or #fillString == 0 then
        return self
    end
    maxLength = maxLength - #self
    if maxLength > #fillString then
        fillString = fillString .. string.rep(
            fillString,
            math.floor(maxLength / #fillString)
        )
    end
    return self .. string.sub(
        fillString,
        1,
        math.floor(maxLength)
    )
end

local function __TS__StringPadStart(self, maxLength, fillString)
    if fillString == nil then
        fillString = " "
    end
    if maxLength ~= maxLength then
        maxLength = 0
    end
    if maxLength == -math.huge or maxLength == math.huge then
        error("Invalid string length", 0)
    end
    if #self >= maxLength or #fillString == 0 then
        return self
    end
    maxLength = maxLength - #self
    if maxLength > #fillString then
        fillString = fillString .. string.rep(
            fillString,
            math.floor(maxLength / #fillString)
        )
    end
    return string.sub(
        fillString,
        1,
        math.floor(maxLength)
    ) .. self
end

local __TS__StringReplace
do
    local sub = string.sub
    function __TS__StringReplace(source, searchValue, replaceValue)
        local startPos, endPos = string.find(source, searchValue, nil, true)
        if not startPos then
            return source
        end
        local before = sub(source, 1, startPos - 1)
        local replacement = type(replaceValue) == "string" and replaceValue or replaceValue(nil, searchValue, startPos - 1, source)
        local after = sub(source, endPos + 1)
        return (before .. replacement) .. after
    end
end

local __TS__StringSplit
do
    local sub = string.sub
    local find = string.find
    function __TS__StringSplit(source, separator, limit)
        if limit == nil then
            limit = 4294967295
        end
        if limit == 0 then
            return {}
        end
        local result = {}
        local resultIndex = 1
        if separator == nil or separator == "" then
            for i = 1, #source do
                result[resultIndex] = sub(source, i, i)
                resultIndex = resultIndex + 1
            end
        else
            local currentPos = 1
            while resultIndex <= limit do
                local startPos, endPos = find(source, separator, currentPos, true)
                if not startPos then
                    break
                end
                result[resultIndex] = sub(source, currentPos, startPos - 1)
                resultIndex = resultIndex + 1
                currentPos = endPos + 1
            end
            if resultIndex <= limit then
                result[resultIndex] = sub(source, currentPos)
            end
        end
        return result
    end
end

local __TS__StringReplaceAll
do
    local sub = string.sub
    local find = string.find
    function __TS__StringReplaceAll(source, searchValue, replaceValue)
        if type(replaceValue) == "string" then
            local concat = table.concat(
                __TS__StringSplit(source, searchValue),
                replaceValue
            )
            if #searchValue == 0 then
                return (replaceValue .. concat) .. replaceValue
            end
            return concat
        end
        local parts = {}
        local partsIndex = 1
        if #searchValue == 0 then
            parts[1] = replaceValue(nil, "", 0, source)
            partsIndex = 2
            for i = 1, #source do
                parts[partsIndex] = sub(source, i, i)
                parts[partsIndex + 1] = replaceValue(nil, "", i, source)
                partsIndex = partsIndex + 2
            end
        else
            local currentPos = 1
            while true do
                local startPos, endPos = find(source, searchValue, currentPos, true)
                if not startPos then
                    break
                end
                parts[partsIndex] = sub(source, currentPos, startPos - 1)
                parts[partsIndex + 1] = replaceValue(nil, searchValue, startPos - 1, source)
                partsIndex = partsIndex + 2
                currentPos = endPos + 1
            end
            parts[partsIndex] = sub(source, currentPos)
        end
        return table.concat(parts)
    end
end

local function __TS__StringSlice(self, start, ____end)
    if start == nil or start ~= start then
        start = 0
    end
    if ____end ~= ____end then
        ____end = 0
    end
    if start >= 0 then
        start = start + 1
    end
    if ____end ~= nil and ____end < 0 then
        ____end = ____end - 1
    end
    return string.sub(self, start, ____end)
end

local function __TS__StringStartsWith(self, searchString, position)
    if position == nil or position < 0 then
        position = 0
    end
    return string.sub(self, position + 1, #searchString + position) == searchString
end

local function __TS__StringSubstr(self, from, length)
    if from ~= from then
        from = 0
    end
    if length ~= nil then
        if length ~= length or length <= 0 then
            return ""
        end
        length = length + from
    end
    if from >= 0 then
        from = from + 1
    end
    return string.sub(self, from, length)
end

local function __TS__StringTrim(self)
    local result = string.gsub(self, "^[%s ﻿]*(.-)[%s ﻿]*$", "%1")
    return result
end

local function __TS__StringTrimEnd(self)
    local result = string.gsub(self, "[%s ﻿]*$", "")
    return result
end

local function __TS__StringTrimStart(self)
    local result = string.gsub(self, "^[%s ﻿]*", "")
    return result
end

local __TS__SymbolRegistryFor, __TS__SymbolRegistryKeyFor
do
    local symbolRegistry = {}
    function __TS__SymbolRegistryFor(key)
        if not symbolRegistry[key] then
            symbolRegistry[key] = __TS__Symbol(key)
        end
        return symbolRegistry[key]
    end
    function __TS__SymbolRegistryKeyFor(sym)
        for key in pairs(symbolRegistry) do
            if symbolRegistry[key] == sym then
                return key
            end
        end
        return nil
    end
end

local function __TS__TypeOf(value)
    local luaType = type(value)
    if luaType == "table" then
        return "object"
    elseif luaType == "nil" then
        return "undefined"
    else
        return luaType
    end
end

local function __TS__Using(self, cb, ...)
    local args = {...}
    local thrownError
    local ok, result = xpcall(
        function() return cb(__TS__Unpack(args)) end,
        function(err)
            thrownError = err
            return thrownError
        end
    )
    local argArray = {__TS__Unpack(args)}
    do
        local i = #argArray - 1
        while i >= 0 do
            local ____self_0 = argArray[i + 1]
            ____self_0[Symbol.dispose](____self_0)
            i = i - 1
        end
    end
    if not ok then
        error(thrownError, 0)
    end
    return result
end

local function __TS__UsingAsync(self, cb, ...)
    local args = {...}
    return __TS__AsyncAwaiter(function(____awaiter_resolve)
        local thrownError
        local ok, result = xpcall(
            function() return cb(
                nil,
                __TS__Unpack(args)
            ) end,
            function(err)
                thrownError = err
                return thrownError
            end
        )
        local argArray = {__TS__Unpack(args)}
        do
            local i = #argArray - 1
            while i >= 0 do
                if argArray[i + 1][Symbol.dispose] ~= nil then
                    local ____self_0 = argArray[i + 1]
                    ____self_0[Symbol.dispose](____self_0)
                end
                if argArray[i + 1][Symbol.asyncDispose] ~= nil then
                    local ____self_1 = argArray[i + 1]
                    __TS__Await(____self_1[Symbol.asyncDispose](____self_1))
                end
                i = i - 1
            end
        end
        if not ok then
            error(thrownError, 0)
        end
        return ____awaiter_resolve(nil, result)
    end)
end

return {
  __TS__ArrayAt = __TS__ArrayAt,
  __TS__ArrayConcat = __TS__ArrayConcat,
  __TS__ArrayEntries = __TS__ArrayEntries,
  __TS__ArrayEvery = __TS__ArrayEvery,
  __TS__ArrayFill = __TS__ArrayFill,
  __TS__ArrayFilter = __TS__ArrayFilter,
  __TS__ArrayForEach = __TS__ArrayForEach,
  __TS__ArrayFind = __TS__ArrayFind,
  __TS__ArrayFindIndex = __TS__ArrayFindIndex,
  __TS__ArrayFrom = __TS__ArrayFrom,
  __TS__ArrayIncludes = __TS__ArrayIncludes,
  __TS__ArrayIndexOf = __TS__ArrayIndexOf,
  __TS__ArrayIsArray = __TS__ArrayIsArray,
  __TS__ArrayJoin = __TS__ArrayJoin,
  __TS__ArrayMap = __TS__ArrayMap,
  __TS__ArrayPush = __TS__ArrayPush,
  __TS__ArrayPushArray = __TS__ArrayPushArray,
  __TS__ArrayReduce = __TS__ArrayReduce,
  __TS__ArrayReduceRight = __TS__ArrayReduceRight,
  __TS__ArrayReverse = __TS__ArrayReverse,
  __TS__ArrayUnshift = __TS__ArrayUnshift,
  __TS__ArraySort = __TS__ArraySort,
  __TS__ArraySlice = __TS__ArraySlice,
  __TS__ArraySome = __TS__ArraySome,
  __TS__ArraySplice = __TS__ArraySplice,
  __TS__ArrayToObject = __TS__ArrayToObject,
  __TS__ArrayFlat = __TS__ArrayFlat,
  __TS__ArrayFlatMap = __TS__ArrayFlatMap,
  __TS__ArraySetLength = __TS__ArraySetLength,
  __TS__ArrayToReversed = __TS__ArrayToReversed,
  __TS__ArrayToSorted = __TS__ArrayToSorted,
  __TS__ArrayToSpliced = __TS__ArrayToSpliced,
  __TS__ArrayWith = __TS__ArrayWith,
  __TS__AsyncAwaiter = __TS__AsyncAwaiter,
  __TS__Await = __TS__Await,
  __TS__Class = __TS__Class,
  __TS__ClassExtends = __TS__ClassExtends,
  __TS__CloneDescriptor = __TS__CloneDescriptor,
  __TS__CountVarargs = __TS__CountVarargs,
  __TS__Decorate = __TS__Decorate,
  __TS__DecorateLegacy = __TS__DecorateLegacy,
  __TS__DecorateParam = __TS__DecorateParam,
  __TS__Delete = __TS__Delete,
  __TS__DelegatedYield = __TS__DelegatedYield,
  __TS__DescriptorGet = __TS__DescriptorGet,
  __TS__DescriptorSet = __TS__DescriptorSet,
  Error = Error,
  RangeError = RangeError,
  ReferenceError = ReferenceError,
  SyntaxError = SyntaxError,
  TypeError = TypeError,
  URIError = URIError,
  __TS__FunctionBind = __TS__FunctionBind,
  __TS__Generator = __TS__Generator,
  __TS__InstanceOf = __TS__InstanceOf,
  __TS__InstanceOfObject = __TS__InstanceOfObject,
  __TS__Iterator = __TS__Iterator,
  __TS__LuaIteratorSpread = __TS__LuaIteratorSpread,
  Map = Map,
  __TS__MapGroupBy = __TS__MapGroupBy,
  __TS__Match = __TS__Match,
  __TS__MathAtan2 = __TS__MathAtan2,
  __TS__MathModf = __TS__MathModf,
  __TS__MathSign = __TS__MathSign,
  __TS__MathTrunc = __TS__MathTrunc,
  __TS__New = __TS__New,
  __TS__Number = __TS__Number,
  __TS__NumberIsFinite = __TS__NumberIsFinite,
  __TS__NumberIsInteger = __TS__NumberIsInteger,
  __TS__NumberIsNaN = __TS__NumberIsNaN,
  __TS__ParseInt = __TS__ParseInt,
  __TS__ParseFloat = __TS__ParseFloat,
  __TS__NumberToString = __TS__NumberToString,
  __TS__NumberToFixed = __TS__NumberToFixed,
  __TS__ObjectAssign = __TS__ObjectAssign,
  __TS__ObjectDefineProperty = __TS__ObjectDefineProperty,
  __TS__ObjectEntries = __TS__ObjectEntries,
  __TS__ObjectFromEntries = __TS__ObjectFromEntries,
  __TS__ObjectGetOwnPropertyDescriptor = __TS__ObjectGetOwnPropertyDescriptor,
  __TS__ObjectGetOwnPropertyDescriptors = __TS__ObjectGetOwnPropertyDescriptors,
  __TS__ObjectGroupBy = __TS__ObjectGroupBy,
  __TS__ObjectKeys = __TS__ObjectKeys,
  __TS__ObjectRest = __TS__ObjectRest,
  __TS__ObjectValues = __TS__ObjectValues,
  __TS__ParseFloat = __TS__ParseFloat,
  __TS__ParseInt = __TS__ParseInt,
  __TS__Promise = __TS__Promise,
  __TS__PromiseAll = __TS__PromiseAll,
  __TS__PromiseAllSettled = __TS__PromiseAllSettled,
  __TS__PromiseAny = __TS__PromiseAny,
  __TS__PromiseRace = __TS__PromiseRace,
  Set = Set,
  __TS__SetDescriptor = __TS__SetDescriptor,
  __TS__SparseArrayNew = __TS__SparseArrayNew,
  __TS__SparseArrayPush = __TS__SparseArrayPush,
  __TS__SparseArraySpread = __TS__SparseArraySpread,
  WeakMap = WeakMap,
  WeakSet = WeakSet,
  __TS__SourceMapTraceBack = __TS__SourceMapTraceBack,
  __TS__Spread = __TS__Spread,
  __TS__StringAccess = __TS__StringAccess,
  __TS__StringCharAt = __TS__StringCharAt,
  __TS__StringCharCodeAt = __TS__StringCharCodeAt,
  __TS__StringEndsWith = __TS__StringEndsWith,
  __TS__StringIncludes = __TS__StringIncludes,
  __TS__StringPadEnd = __TS__StringPadEnd,
  __TS__StringPadStart = __TS__StringPadStart,
  __TS__StringReplace = __TS__StringReplace,
  __TS__StringReplaceAll = __TS__StringReplaceAll,
  __TS__StringSlice = __TS__StringSlice,
  __TS__StringSplit = __TS__StringSplit,
  __TS__StringStartsWith = __TS__StringStartsWith,
  __TS__StringSubstr = __TS__StringSubstr,
  __TS__StringSubstring = __TS__StringSubstring,
  __TS__StringTrim = __TS__StringTrim,
  __TS__StringTrimEnd = __TS__StringTrimEnd,
  __TS__StringTrimStart = __TS__StringTrimStart,
  __TS__Symbol = __TS__Symbol,
  Symbol = Symbol,
  __TS__SymbolRegistryFor = __TS__SymbolRegistryFor,
  __TS__SymbolRegistryKeyFor = __TS__SymbolRegistryKeyFor,
  __TS__TypeOf = __TS__TypeOf,
  __TS__Unpack = __TS__Unpack,
  __TS__Using = __TS__Using,
  __TS__UsingAsync = __TS__UsingAsync
}
 end,
["src.rules"] = function(...) 
local ____lualib = require("lualib_bundle")
local Set = ____lualib.Set
local __TS__ArrayMap = ____lualib.__TS__ArrayMap
local __TS__SparseArrayNew = ____lualib.__TS__SparseArrayNew
local __TS__SparseArrayPush = ____lualib.__TS__SparseArrayPush
local __TS__SparseArraySpread = ____lualib.__TS__SparseArraySpread
local __TS__New = ____lualib.__TS__New
local __TS__ArrayFlatMap = ____lualib.__TS__ArrayFlatMap
local __TS__ObjectValues = ____lualib.__TS__ObjectValues
local __TS__ArrayFlat = ____lualib.__TS__ArrayFlat
local __TS__ArrayFilter = ____lualib.__TS__ArrayFilter
local __TS__ObjectAssign = ____lualib.__TS__ObjectAssign
local __TS__ArrayForEach = ____lualib.__TS__ArrayForEach
local ____exports = {}
____exports.WIDTH = 620
____exports.HEIGHT = 765
____exports.FLOOR = 675
____exports.AD_SECONDS = 30
____exports.FIRST_WAVE_AT = 3
____exports.FIRST_BOSS_AT = 52
____exports.CARD_X = {76, 226}
____exports.CARD_Y = 297
____exports.HERO = "魂-背影"
____exports.ALLIES = {
    {
        name = "暗魔天堡之主：魔渊",
        short = "魔渊",
        text = "重击贯敌",
        hp = 48,
        damage = 16,
        interval = 0.66,
        size = 7,
        speed = 445,
        pierce = 1
    },
    {
        name = "剑痴：花千笑",
        short = "花千笑",
        text = "快剑连发",
        hp = 30,
        damage = 6,
        interval = 0.25,
        size = 4,
        speed = 540,
        pierce = 0
    },
    {
        name = "拳痴：铁狂",
        short = "铁狂",
        text = "厚血重拳",
        hp = 72,
        damage = 16,
        interval = 0.7,
        size = 9,
        speed = 380,
        pierce = 0
    },
    {
        name = "双蛇夫人：白赤练",
        short = "白赤练",
        text = "蛇刃穿两敌",
        hp = 34,
        damage = 8,
        interval = 0.49,
        size = 4,
        speed = 510,
        pierce = 2
    },
    {
        name = "天玄派：毕远掌门残躯",
        short = "毕远掌门",
        text = "宽刃剑气",
        hp = 44,
        damage = 12,
        interval = 0.54,
        size = 10,
        speed = 450,
        pierce = 0
    },
    {
        name = "组织少主：沐小葵",
        short = "沐小葵",
        text = "轻刃疾射",
        hp = 34,
        damage = 7,
        interval = 0.29,
        size = 5,
        speed = 610,
        pierce = 0
    },
    {
        name = "少主护卫：玉妖",
        short = "玉妖",
        text = "迅刃贯敌",
        hp = 38,
        damage = 8,
        interval = 0.38,
        size = 4,
        speed = 560,
        pierce = 1
    },
    {
        name = "少主护卫：铁鬼",
        short = "铁鬼",
        text = "铁甲护阵",
        hp = 94,
        damage = 11,
        interval = 0.68,
        size = 8,
        speed = 395,
        pierce = 0
    },
    {
        name = "雷枪：长鸿",
        short = "长鸿",
        text = "雷枪高速贯敌",
        hp = 40,
        damage = 11,
        interval = 0.53,
        size = 4,
        speed = 780,
        pierce = 1
    },
    {
        name = "风雪刀客",
        short = "风雪刀客",
        text = "快刀横斩",
        hp = 36,
        damage = 8,
        interval = 0.37,
        size = 8,
        speed = 510,
        pierce = 0
    },
    {
        name = "被面具控制的舞狮尊主：烈焰",
        short = "烈焰",
        text = "大范围烈刃",
        hp = 54,
        damage = 18,
        interval = 0.75,
        size = 12,
        speed = 415,
        pierce = 0
    }
}
____exports.WEAPONS = {
    {name = "黑伤", text = "刀伤 +5", damage = 5},
    {name = "黑伤双刃", text = "双列飞刀 · 刀伤 +2", double = true, damage = 2},
    {name = "圣母邪扇", text = "刃宽 +3 · 刀伤 +1", size = 3, damage = 1},
    {name = "白山风雷剑", text = "弹速 +80 · 射速 +12%", speed = 80, rate = 0.12},
    {name = "妖锯", text = "刃宽 +2 · 刀伤 +3", size = 2, damage = 3},
    {name = "炽刃", text = "刀伤 +7", damage = 7},
    {name = "破军", text = "穿透 +1 · 刀伤 +2", pierce = 1, damage = 2},
    {name = "乱莺剑", text = "射速 +28%", rate = 0.28},
    {name = "紫冥剑", text = "射速 +12% · 刀伤 +3", rate = 0.12, damage = 3},
    {name = "木制黑伤", text = "移速 +40 · 刀伤 +2", move = 40, damage = 2},
    {name = "亡命斩马刀", text = "刀伤 +5 · 刃宽 +2", damage = 5, size = 2}
}
____exports.ENEMIES = {scout = {
    "无面剑客队长",
    "剑盾人偶",
    "和事佬",
    "机灵鬼",
    "铁面",
    "白山女探",
    "水行钓者",
    "活金人·刀",
    "哇哇哇",
    "人屠子",
    "冰封人屠",
    "冰爆客",
    "冰雪歌女",
    "冰雪琴女",
    "刀盾暴徒",
    "双斧暴徒",
    "双镐疯妇",
    "合金炮偶",
    "吼吼吼",
    "哈哈哈",
    "哼哼哼",
    "嘿嘿嘿",
    "大司乐",
    "大娘亲",
    "大盾暴徒",
    "失心医者",
    "山贼",
    "山贼高手",
    "巨刃疯妇",
    "幽怨女娃：呜呜呜",
    "影魅杀手",
    "憨哥哥",
    "戎装疯妇",
    "投掷暴徒",
    "无面剑客",
    "无面枪兵",
    "无面枪兵队长",
    "无面枪骑兵",
    "暴徒",
    "村中长老",
    "村花姐",
    "枪盾人偶",
    "歌女人偶",
    "毒爆客",
    "水行弟子",
    "水行投者",
    "水行潜者",
    "活金人·拳",
    "活金人·棍",
    "活铁人·刀",
    "活铁人·拳",
    "活铁人·棍",
    "活铜人·拳",
    "溺水贼",
    "漂浮之头",
    "火弓客",
    "火蒺藜飞贼",
    "爆弹客",
    "狂焰山贼",
    "猎人",
    "琴女人偶",
    "画戟战偶",
    "疯妇",
    "癫秀才",
    "白山剑护法",
    "白山双刺护法",
    "白山女徒",
    "白衣鬼差",
    "紫衣刀卫",
    "紫衣双剑客",
    "纵火疯妇",
    "羽弓客",
    "腐坏暴徒",
    "腐坏疯妇",
    "腐坏纵火狂",
    "荆棘暴徒",
    "血剑客",
    "重弩客",
    "野火鬼差",
    "金面",
    "铁齿伞偶",
    "长刀水行潜者",
    "长枪暴徒",
    "阳体人偶",
    "阳体人偶：上半身",
    "阳体人偶：下半身",
    "阴体人偶",
    "雪隐潜者",
    "雷铳鬼差",
    "飞刀疯妇",
    "飞贼",
    "马匪",
    "驯犬客",
    "鬼差",
    "鬼差火枪手",
    "鬼差火枪骑兵",
    "鬼差骑兵",
    "鬼枪盾偶",
    "黄袍暴徒",
    "黄金刺杀偶"
}, elite = {
    "追命：六绝凶镰",
    "鬼差队长：火流星",
    "堕落将军：武轩",
    "癫狂暴徒：铁杀",
    "力者和锯者",
    "活人偶清道夫",
    "七星剑阵：大师兄",
    "三号·乐师偶：玉瓒",
    "亡命徒：荆野",
    "力者：石破天惊之态",
    "卅四号·混沌魔偶：玉琮",
    "发狂的水行帮主：游龙",
    "吞噬尸体的小雪",
    "大师兄的绝望剑意",
    "女妖骨婉约",
    "守门人拙壁",
    "少年左殇",
    "左殇：真龙之躯",
    "巨锤客：万钧",
    "廿一号·剑偶：玉璧",
    "悲痛欲绝的阿瑾",
    "操偶师：荡秽",
    "斧老大：彭猛",
    "昆仑叛教者：荒行子",
    "横刀：毕峰",
    "水行帮主：游龙",
    "沐小葵：铁玉女王",
    "火刀：祝原",
    "火流星：磷火意识",
    "灭法之法：寒岁",
    "灭法之法：炎茹",
    "灭法之法：蛊鹤",
    "灭法之法：雷婷",
    "独眼弓客",
    "玉琮：寒冰",
    "玉琮：混沌",
    "玉琮：钢刃",
    "玉面郎君",
    "琴女烟千岁",
    "疯婆子奎艳艳",
    "痴狂暴徒：残钢",
    "白赤练：献祭之蛇",
    "神医：谢秋冬",
    "红衣女剑客",
    "组织冥主：左殇（序章）",
    "组织猎杀者：追命",
    "舞狮尊主的最后一舞",
    "苦叶寺：碧海大师残躯",
    "荒行子：撕裂锯轮",
    "虎炮：雷当",
    "赤影骨刃：囚锋",
    "软剑：乌冷霜",
    "金面具黑衣人",
    "长鸿：雷电枪骑",
    "雷当：独臂虎",
    "鬼差高手：勾魂",
    "鬼差高手：斩骑",
    "鬼差高手：断肠"
}, boss = {
    "组织冥主：左殇（终章）",
    "救苦救难梦华圣母娘娘",
    "十二号·偃月刀偶：玉鼎",
    "新娘阿花",
    "梦差：冷荼",
    "三张脸的诡异魔偶"
}}
local ____Set_1 = Set
local ____array_0 = __TS__SparseArrayNew(table.unpack(__TS__ArrayMap(
    ____exports.ALLIES,
    function(____, ally) return ally.name end
)))
__TS__SparseArrayPush(
    ____array_0,
    "金面具黑衣人",
    "沐小葵：铁玉女王",
    "白赤练：献祭之蛇",
    "长鸿：雷电枪骑",
    "舞狮尊主的最后一舞"
)
local alliedIdentities = __TS__New(
    ____Set_1,
    {__TS__SparseArraySpread(____array_0)}
)
local function enemyPool(tribe)
    return __TS__ArrayFlatMap(
        ____exports.ENEMIES[tribe],
        function(____, name, id) return alliedIdentities:has(name) and ({}) or ({id}) end
    )
end
____exports.SPAWN_POOL = {
    scout = enemyPool("scout"),
    elite = enemyPool("elite"),
    boss = enemyPool("boss")
}
function ____exports.isEnemy(tribe, id)
    return not alliedIdentities:has(____exports.ENEMIES[tribe][id + 1])
end
local ____array_2 = __TS__SparseArrayNew(
    ____exports.HERO,
    table.unpack(__TS__ArrayMap(
        ____exports.ALLIES,
        function(____, a) return a.name end
    ))
)
__TS__SparseArrayPush(
    ____array_2,
    table.unpack(__TS__ArrayMap(
        ____exports.WEAPONS,
        function(____, w) return w.name end
    ))
)
__TS__SparseArrayPush(
    ____array_2,
    table.unpack(__TS__ArrayFilter(
        __TS__ArrayFlat(__TS__ObjectValues(____exports.ENEMIES)),
        function(____, name) return not alliedIdentities:has(name) end
    ))
)
____exports.ALL_ART = {__TS__SparseArraySpread(____array_2)}
function ____exports.rewardInfo(id)
    if id < #____exports.ALLIES then
        return __TS__ObjectAssign({}, ____exports.ALLIES[id + 1], {kind = "队友"})
    end
    local w = ____exports.WEAPONS[id - #____exports.ALLIES + 1]
    return {name = w.name, short = w.name, text = w.text, kind = "武器"}
end
function ____exports.weaponStats(stacks)
    local s = {
        damage = 10,
        rate = 4,
        speed = 480,
        move = 390,
        size = 4,
        pierce = 0,
        double = false
    }
    __TS__ArrayForEach(
        ____exports.WEAPONS,
        function(____, w, i)
            local n = stacks[i + 1]
            s.damage = s.damage + (w.damage or 0) * n
            s.rate = s.rate + 4 * (w.rate or 0) * n
            s.speed = s.speed + (w.speed or 0) * n
            s.move = s.move + (w.move or 0) * n
            s.size = s.size + (w.size or 0) * n
            s.pierce = s.pierce + (w.pierce or 0) * n
            if w.double and n > 0 then
                s.double = true
            end
        end
    )
    return s
end
function ____exports.rewardHP(taken)
    return 100 + 2 * math.ceil(22 * taken + 1.8 * taken * taken)
end
local function growthSquared(minutes)
    local afterOpening = math.max(0, minutes - ____exports.AD_SECONDS / 60)
    return minutes ^ 2 + 0.16 * afterOpening ^ 2
end
function ____exports.enemyStats(tribe, time, variant)
    local boss = tribe == "boss"
    local hp, attack, speed = table.unpack(({scout = {15, 4, 50}, elite = {70, 12, 47}, boss = {235, 19, 39}})[tribe], 1, 3)
    local minutes = time / 60
    local squared = growthSquared(minutes)
    local hpGrowth = boss and 1 + 0.16 * minutes + 1.5 * squared or 1 + 0.12 * minutes + 0.52 * squared
    local attackGrowth = boss and 1 + 0.1 * minutes + 0.38 * squared or 1 + 0.14 * minutes + 0.2 * squared
    return {
        max = math.ceil(hp * hpGrowth * (1 + 0.055 * (variant % 4))),
        attack = math.ceil(attack * attackGrowth),
        speed = speed * (1 + 0.78 * time / (time + 70))
    }
end
function ____exports.army(time)
    local minutes = time / 60
    local baseRate = 0.2 + 0.07 * minutes + 0.46 * growthSquared(minutes)
    local openingWeight = math.max(0, 1 - minutes / 3) ^ 2
    local enemiesPerSecond = baseRate + (0.2 + 0.4 * minutes) * openingWeight
    local count = math.max(
        1,
        math.floor(0.85 * enemiesPerSecond + 0.5)
    )
    local eliteMinutes = math.max(0, (time - ____exports.AD_SECONDS) / 60)
    local eliteWeight = eliteMinutes ^ 2
    return {count = count, interval = count / enemiesPerSecond, eliteChance = 0.7 * eliteWeight / (5 + eliteWeight)}
end
local rangedProfiles = {}
for ____, name in ipairs({
    "琴女烟千岁",
    "三号·乐师偶：玉瓒",
    "琴女人偶",
    "冰雪琴女",
    "冰雪歌女",
    "歌女人偶",
    "大司乐"
}) do
    rangedProfiles[name] = "music"
end
for ____, name in ipairs({
    "鬼差火枪手",
    "鬼差火枪骑兵",
    "雷铳鬼差",
    "合金炮偶",
    "虎炮：雷当",
    "雷当：独臂虎"
}) do
    rangedProfiles[name] = "gun"
end
for ____, name in ipairs({
    "火弓客",
    "羽弓客",
    "重弩客",
    "独眼弓客",
    "猎人"
}) do
    rangedProfiles[name] = "bow"
end
function ____exports.missileType(tribe, unit)
    return rangedProfiles[____exports.ENEMIES[tribe][unit + 1]]
end
____exports.BALLISTICS = {music = {
    speed = 155,
    delay = 3.8,
    spread = {-0.12, 0, 0.12},
    damage = 0.53,
    radius = 7
}, gun = {
    speed = 315,
    delay = 3.1,
    spread = {0},
    damage = 0.87,
    radius = 5
}, bow = {
    speed = 232,
    delay = 3.5,
    spread = {0},
    damage = 0.65,
    radius = 4
}}
return ____exports
 end,
["src.worldNotice"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__StringReplace = ____lualib.__TS__StringReplace
local ____exports = {}
function ____exports.formatNotice(event, words)
    local text = words[event.key]
    if event.id ~= nil then
        text = __TS__StringReplace(text, "{name}", words.names[event.id + 1])
    end
    if event.amount ~= nil then
        text = __TS__StringReplace(
            text,
            "{n}",
            tostring(event.amount)
        )
    end
    if event.copies ~= nil and event.copies ~= nil then
        text = text .. " ×" .. tostring(event.copies)
    end
    if event.key == "heroHit" and event.lost ~= nil then
        text = text .. " · " .. __TS__StringReplace(words.drop, "{name}", words.names[event.lost + 1])
    end
    return text
end
return ____exports
 end,
["src.world"] = function(...) 
local ____lualib = require("lualib_bundle")
local __TS__ArrayMap = ____lualib.__TS__ArrayMap
local __TS__ArrayForEach = ____lualib.__TS__ArrayForEach
local __TS__ObjectAssign = ____lualib.__TS__ObjectAssign
local __TS__ArrayIncludes = ____lualib.__TS__ArrayIncludes
local __TS__ArraySort = ____lualib.__TS__ArraySort
local __TS__ArrayIndexOf = ____lualib.__TS__ArrayIndexOf
local __TS__ArraySplice = ____lualib.__TS__ArraySplice
local __TS__ArrayReduce = ____lualib.__TS__ArrayReduce
local ____exports = {}
local ____rules = require("src.rules")
local ALLIES = ____rules.ALLIES
local WEAPONS = ____rules.WEAPONS
local SPAWN_POOL = ____rules.SPAWN_POOL
local WIDTH = ____rules.WIDTH
local HEIGHT = ____rules.HEIGHT
local FLOOR = ____rules.FLOOR
local CARD_X = ____rules.CARD_X
local CARD_Y = ____rules.CARD_Y
local FIRST_WAVE_AT = ____rules.FIRST_WAVE_AT
local FIRST_BOSS_AT = ____rules.FIRST_BOSS_AT
local army = ____rules.army
local enemyStats = ____rules.enemyStats
local rewardHP = ____rules.rewardHP
local weaponStats = ____rules.weaponStats
local missileType = ____rules.missileType
local BALLISTICS = ____rules.BALLISTICS
function ____exports.random(w)
    w.seed = (1664525 * w.seed + 1013904223) % 4294967296
    return w.seed / 4294967296
end
local function rollCard(w)
    local max = rewardHP(w.taken)
    return {
        reward = math.floor(____exports.random(w) * (#ALLIES + #WEAPONS)),
        max = max,
        hp = max
    }
end
function ____exports.updateCardHP(card, max)
    card.hp = card.hp + (max - card.max)
    card.max = max
end
function ____exports.newWorld(seed)
    if seed == nil then
        seed = math.floor(math.random() * 4294967296)
    end
    local w = {
        seed = seed,
        time = 0,
        x = WIDTH / 2,
        hp = 100,
        kills = 0,
        taken = 0,
        nextId = 1,
        weapons = __TS__ArrayMap(
            WEAPONS,
            function() return 0 end
        ),
        allies = {},
        cards = {},
        enemies = {},
        shots = {},
        hostile = {},
        nextMob = FIRST_WAVE_AT,
        nextBoss = FIRST_BOSS_AT,
        guard = 0,
        fire = 0.1
    }
    w.cards = {
        rollCard(w),
        rollCard(w)
    }
    return w
end
local function grant(w, reward, slot, feedback)
    if reward < #ALLIES then
        local ____w_allies_0 = w.allies
        ____w_allies_0[#____w_allies_0 + 1] = {unit = reward, hp = ALLIES[reward + 1].hp, cool = 0.12}
    else
        local ____w_weapons_1, ____temp_2 = w.weapons, reward - #ALLIES + 1
        ____w_weapons_1[____temp_2] = ____w_weapons_1[____temp_2] + 1
    end
    w.taken = w.taken + 1
    local max = rewardHP(w.taken)
    __TS__ArrayForEach(
        w.cards,
        function(____, card, i)
            if i == slot then
                w.cards[i + 1] = rollCard(w)
            else
                ____exports.updateCardHP(card, max)
            end
        end
    )
    local copies = reward >= #ALLIES and w.weapons[reward - #ALLIES + 1] or nil
    feedback("upgrade", {key = slot == nil and "bossGain" or "gain", id = reward, copies = copies})
end
function ____exports.formation(w, index)
    local slot = index < 4 and ({1, 3, 0, 4})[index + 1] or (index - 4) % 5
    local row = index < 4 and 0 or 1 + math.floor((index - 4) / 5)
    local width = 58
    local anchor = math.min(
        WIDTH - width - 20,
        math.max(width + 20, w.x)
    )
    local stepY = math.min(
        31,
        112 / math.max(
            1,
            math.ceil((#w.allies - 4) / 5)
        )
    )
    return {x = anchor + (slot - 2) * width / 2, y = FLOOR - row * stepY}
end
function ____exports.spawn(w, tribe)
    local pool = SPAWN_POOL[tribe]
    local unit = pool[math.floor(____exports.random(w) * #pool) + 1]
    local stats = enemyStats(tribe, w.time, unit)
    local ____w_enemies_6 = w.enemies
    local ____w_3, ____nextId_4 = w, "nextId"
    local ____w_nextId_5 = ____w_3[____nextId_4]
    ____w_3[____nextId_4] = ____w_nextId_5 + 1
    ____w_enemies_6[#____w_enemies_6 + 1] = __TS__ObjectAssign(
        {
            id = ____w_nextId_5,
            tribe = tribe,
            unit = unit,
            x = WIDTH / 2 + 32 + ____exports.random(w) * (WIDTH / 2 - 66),
            y = tribe == "boss" and 84 or 52,
            hp = stats.max,
            reload = 1.05 + ____exports.random(w) * 1.3
        },
        stats
    )
end
local function shoot(w, x, y, power, speed, size, pierce, friendly)
    local ____w_shots_7 = w.shots
    ____w_shots_7[#____w_shots_7 + 1] = {
        x = x,
        y = y,
        power = power,
        speed = speed,
        size = size,
        pierce = pierce,
        friendly = friendly,
        touched = {}
    }
end
local function fire(w, dt, stats, feedback)
    w.fire = w.fire - dt
    if w.fire <= 0 then
        local rate = math.min(15, stats.rate)
        local power = stats.damage * stats.rate / rate
        w.fire = w.fire + 1 / rate
        for ____, dx in ipairs(stats.double and ({-11, 11}) or ({0})) do
            shoot(
                w,
                w.x + dx,
                FLOOR - 27,
                power,
                stats.speed,
                stats.size,
                stats.pierce,
                false
            )
        end
        feedback("throw")
    end
    __TS__ArrayForEach(
        w.allies,
        function(____, a, i)
            a.cool = a.cool - dt
            if a.cool > 0 then
                return
            end
            local p = ____exports.formation(w, i)
            local ally = ALLIES[a.unit + 1]
            shoot(
                w,
                p.x,
                p.y - 19,
                ally.damage,
                ally.speed,
                ally.size,
                ally.pierce,
                true
            )
            a.cool = a.cool + ally.interval
        end
    )
end
local function resolveShots(w, dt, feedback)
    do
        local i = #w.shots - 1
        while i >= 0 do
            local shot = w.shots[i + 1]
            local oldY = shot.y
            shot.y = shot.y - shot.speed * dt
            local hits = {}
            for ____, mob in ipairs(w.enemies) do
                local r = mob.tribe == "boss" and 31 or (mob.tribe == "elite" and 23 or 16)
                if math.abs(mob.x - shot.x) <= r + shot.size and shot.y <= mob.y + r and oldY >= mob.y - r and not __TS__ArrayIncludes(shot.touched, mob.id) then
                    hits[#hits + 1] = {y = mob.y + r, mob = mob}
                end
            end
            do
                local c = 0
                while c < 2 do
                    if math.abs(shot.x - CARD_X[c + 1]) < 46 + shot.size and shot.y <= CARD_Y + 45 and oldY >= CARD_Y - 45 then
                        hits[#hits + 1] = {y = CARD_Y + 45, slot = c}
                    end
                    c = c + 1
                end
            end
            __TS__ArraySort(
                hits,
                function(____, a, b) return b.y - a.y end
            )
            local consumed = false
            for ____, hit in ipairs(hits) do
                if hit.slot ~= nil then
                    local card = w.cards[hit.slot + 1]
                    card.hp = card.hp - shot.power
                    if card.hp <= 0 then
                        grant(w, card.reward, hit.slot, feedback)
                    end
                    consumed = true
                    break
                end
                local mob = hit.mob
                mob.hp = mob.hp - shot.power
                local ____shot_touched_8 = shot.touched
                ____shot_touched_8[#____shot_touched_8 + 1] = mob.id
                if mob.hp <= 0 then
                    __TS__ArraySplice(
                        w.enemies,
                        __TS__ArrayIndexOf(w.enemies, mob),
                        1
                    )
                    w.kills = w.kills + 1
                    feedback("hit")
                    if mob.tribe == "boss" then
                        grant(
                            w,
                            math.floor(____exports.random(w) * (#ALLIES + #WEAPONS)),
                            nil,
                            feedback
                        )
                    end
                end
                if shot.pierce <= 0 then
                    consumed = true
                    break
                end
                shot.pierce = shot.pierce - 1
            end
            if consumed or shot.y < 0 then
                __TS__ArraySplice(w.shots, i, 1)
            end
            i = i - 1
        end
    end
end
local function damage(w, victim, amount, feedback)
    if w.guard > 0 then
        return
    end
    if victim >= 0 then
        local a = w.allies[victim + 1]
        a.hp = a.hp - amount
        if a.hp <= 0 then
            __TS__ArraySplice(w.allies, victim, 1)
            feedback("hurt", {key = "fallen", id = a.unit})
        else
            feedback("hurt", {key = "allyHit", id = a.unit, amount = amount})
        end
    else
        w.hp = math.max(0, w.hp - amount)
        local owned = __TS__ArrayReduce(
            w.weapons,
            function(____, sum, n) return sum + n end,
            0
        )
        local lost
        if owned > 0 then
            local ticket = math.floor(____exports.random(w) * owned)
            do
                local i = 0
                while i < #w.weapons do
                    if ticket < w.weapons[i + 1] then
                        local ____w_weapons_9, ____temp_10 = w.weapons, i + 1
                        ____w_weapons_9[____temp_10] = ____w_weapons_9[____temp_10] - 1
                        lost = #ALLIES + i
                        break
                    end
                    ticket = ticket - w.weapons[i + 1]
                    i = i + 1
                end
            end
        end
        feedback("hurt", {key = "heroHit", amount = amount, lost = lost})
    end
    w.guard = 0.48
end
local function frontTarget(w, from)
    local closest = math.huge
    local index = -1
    local point = {x = w.x, y = FLOOR}
    do
        local i = 0
        while i < #w.allies do
            local p = ____exports.formation(w, i)
            local d = (p.x - from.x) ^ 2 + (p.y - from.y) ^ 2
            if d < closest then
                closest = d
                point = p
                index = i
            end
            i = i + 1
        end
    end
    return __TS__ObjectAssign({}, point, {index = index})
end
local function rangedAttack(w, m, kind, dt)
    m.reload = m.reload - dt
    if m.reload > 0 then
        return
    end
    local target = frontTarget(w, m)
    local angle = math.atan(target.y - m.y, target.x - m.x)
    local spec = BALLISTICS[kind]
    for ____, offset in ipairs(spec.spread) do
        local ____w_hostile_11 = w.hostile
        ____w_hostile_11[#____w_hostile_11 + 1] = {
            x = m.x,
            y = m.y + 7,
            vx = math.cos(angle + offset) * spec.speed,
            vy = math.sin(angle + offset) * spec.speed,
            kind = kind,
            attack = math.ceil(m.attack * spec.damage)
        }
    end
    m.reload = spec.delay * (0.9 + 0.22 * ____exports.random(w))
end
local function march(w, dt, feedback)
    w.guard = math.max(0, w.guard - dt)
    for ____, mob in ipairs(w.enemies) do
        do
            local ranged = missileType(mob.tribe, mob.unit)
            if ranged and mob.y >= HEIGHT * 0.26 then
                rangedAttack(w, mob, ranged, dt)
                if mob.y >= HEIGHT * (0.38 + 0.035 * (mob.id % 8)) then
                    goto __continue60
                end
            end
            if mob.y < FLOOR - 160 then
                mob.y = mob.y + mob.speed * dt
                goto __continue60
            end
            local target = frontTarget(w, mob)
            local dx = target.x - mob.x
            local dy = target.y - mob.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist > 1 then
                local travel = math.min(dist, dt * mob.speed * 1.55)
                mob.x = mob.x + travel * dx / dist
                mob.y = mob.y + travel * dy / dist
            end
            if dist > 24 or w.guard > 0 then
                goto __continue60
            end
            damage(w, target.index, mob.attack, feedback)
            mob.y = mob.y - 55
            if w.hp == 0 then
                return
            end
        end
        ::__continue60::
    end
end
local function enemyBullets(w, dt, feedback)
    do
        local i = #w.hostile - 1
        while i >= 0 do
            local shot = w.hostile[i + 1]
            shot.x = shot.x + shot.vx * dt
            shot.y = shot.y + shot.vy * dt
            local spent = shot.x < 0 or shot.x > WIDTH or shot.y < 0 or shot.y > HEIGHT
            if not spent and shot.y > FLOOR - 155 then
                local target = frontTarget(w, shot)
                local radius = (target.index < 0 and 17 or 13) + BALLISTICS[shot.kind].radius
                if (target.x - shot.x) ^ 2 + (target.y - shot.y) ^ 2 <= radius ^ 2 then
                    damage(w, target.index, shot.attack, feedback)
                    spent = true
                end
            end
            if spent then
                __TS__ArraySplice(w.hostile, i, 1)
            end
            if w.hp == 0 then
                return
            end
            i = i - 1
        end
    end
end
function ____exports.advance(w, dt, aim, feedback, axis)
    if axis == nil then
        axis = 0
    end
    local stats = weaponStats(w.weapons)
    local travel = stats.move * dt
    local displacement = aim == nil and axis * travel or aim - w.x
    w.x = math.max(
        21,
        math.min(
            WIDTH - 21,
            w.x + math.max(
                -travel,
                math.min(travel, displacement)
            )
        )
    )
    w.time = w.time + dt
    if w.time >= w.nextMob then
        local wave = army(w.time)
        do
            local i = 0
            while i < wave.count do
                ____exports.spawn(
                    w,
                    ____exports.random(w) < wave.eliteChance and "elite" or "scout"
                )
                i = i + 1
            end
        end
        w.nextMob = w.nextMob + wave.interval
    end
    if w.time >= w.nextBoss then
        ____exports.spawn(w, "boss")
        w.nextBoss = w.nextBoss + 32
        feedback("hit", {key = "bossArrival"})
    end
    fire(w, dt, stats, feedback)
    resolveShots(w, dt, feedback)
    march(w, dt, feedback)
    if w.hp > 0 then
        enemyBullets(w, dt, feedback)
    end
end
return ____exports
 end,
["native"] = function(...) 
--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
do
    local ____world = require("src.world")
    ____exports.newWorld = ____world.newWorld
    ____exports.advance = ____world.advance
    ____exports.formation = ____world.formation
end
do
    local ____worldNotice = require("src.worldNotice")
    ____exports.formatNotice = ____worldNotice.formatNotice
end
do
    local ____rules = require("src.rules")
    ____exports.ALLIES = ____rules.ALLIES
    ____exports.WEAPONS = ____rules.WEAPONS
    ____exports.ENEMIES = ____rules.ENEMIES
    ____exports.HERO = ____rules.HERO
    ____exports.ALL_ART = ____rules.ALL_ART
    ____exports.rewardInfo = ____rules.rewardInfo
    ____exports.AD_SECONDS = ____rules.AD_SECONDS
end
return ____exports
 end,
}
local ____entry = require("native", ...)
return ____entry
