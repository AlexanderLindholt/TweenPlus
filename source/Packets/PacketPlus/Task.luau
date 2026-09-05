--!optimize 2

local threads = {}
local function reusableThreadCall(callback, thread, ...)
	callback(...)
	table.insert(threads, thread)
end
local function reusableThread()
	while true do
		reusableThreadCall(coroutine.yield())
	end
end

return {
	Spawn = function(callback, ...)
		local length = #threads
		if length == 0 then
			local thread = coroutine.create(reusableThread)
			coroutine.resume(thread)
			return task.spawn(thread, callback, thread, ...)
		else
			local thread = threads[length]
			threads[length] = nil -- Remove from free threads list.
			return task.spawn(thread, callback, thread, ...)
		end
	end,
	Defer = function(callback, ...)
		local length = #threads
		if length == 0 then
			local thread = coroutine.create(reusableThread)
			coroutine.resume(thread)
			return task.defer(thread, callback, thread, ...)
		else
			local thread = threads[length]
			threads[length] = nil -- Remove from free threads list.
			return task.defer(thread, callback, thread, ...)
		end
	end,
	Delay = function(delay, callback, ...)
		local length = #threads
		if length == 0 then
			local thread = coroutine.create(reusableThread)
			coroutine.resume(thread)
			return task.delay(delay, thread, callback, thread, ...)
		else
			local thread = threads[length]
			threads[length] = nil -- Remove from free threads list.
			return task.delay(delay, thread, callback, thread, ...)
		end
	end
}