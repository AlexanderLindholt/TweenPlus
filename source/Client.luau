--!optimize 2
--!native

-- Services.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

-- Attempt to find the plugin object.
local plugin = script:FindFirstAncestorOfClass("Plugin")

-- Network packets and API map.
local packets, apiMap
if plugin then
	for _, instance in plugin:GetDescendants() do
		if instance:HasTag("APIMap") then
			apiMap = require(instance)
			break
		end
	end
	if not apiMap then error("Could not find APIMap module.") end
else -- Game context.
	packets = CollectionService:GetTagged("Packets")[1]
	if not packets then error("Could not find packets module.") end
	packets = require(packets)
	
	apiMap = CollectionService:GetTagged("APIMap")[1]
	if not apiMap then error("Could not find APIMap module") end
	apiMap = require(apiMap)
end

-- Signal library.
local Signal
if plugin then
	for _, instance in plugin:GetDescendants() do
		if instance:HasTag("Signal") then
			Signal = require(instance)
			if type(Signal) == "table" and Signal.new then Signal = Signal.new end
			break
		end
	end
else
	Signal = CollectionService:GetTagged("Signal")[1]
	if Signal then
		Signal = require(Signal)
		if type(Signal) == "table" and Signal.new then Signal = Signal.new end
	end
end

-- Time function.
local getTime = if plugin then os.clock else time

-- Directories.
local root = script.Parent
local data = root.Data
local utilities = root.Utilities

-- Easing functions.
local easingFunctions = require(utilities.EasingFunctions)

-- Update functions constructor.
local createUpdateFunctions = require(utilities.UpdateFunctions)

-- Options defaults.
local defaults = require(data.Defaults)

-- Types.
local types = require(data.Types)
type InternalTween = types.InternalTween

-- Active tweens collection.
local tweens: {InternalTween} = table.create(script.Parent:GetAttribute("TweenPreallocations"))
local tweensAmount = 0

-- Tween functions.
local function stop(tween: InternalTween)
	-- Set playing state.
	tween.Playing = nil
	
	-- Tween removal.
	local index = tween.Index
	if index == tweensAmount then
		tweens[tweensAmount] = nil
	else
		local last = tweens[tweensAmount]
		last.Index = index
		tweens[index] = last
		tweens[tweensAmount] = nil
	end
	tweensAmount -= 1
	
	-- Set time markers.
	tween.StopTime = getTime()
end
local function destroy(tween: InternalTween)
	-- Ensure no playback.
	if tween.Playing then
		-- Tween removal.
		local index = tween.Index
		if index == tweensAmount then
			tweens[tweensAmount] = nil
		else
			local last = tweens[tweensAmount]
			last.Index = index
			tweens[index] = last
			tweens[tweensAmount] = nil
		end
		tweensAmount -= 1
		
		-- Fire stopped signal.
		if Signal then tween.Stopped:Fire() end
	end
	
	-- Destroy signals.
	if Signal then
		tween.Updated:Destroy()
		tween.Started:Destroy()
		tween.Stopped:Destroy()
		tween.Completed:Destroy()
	end
	-- Unlink methods.
	setmetatable(tween, nil)
end

local function start(tween: InternalTween, startOverride)
	-- Verify playback state.
	if tween.Playing then return end
	
	-- Set playing state.
	tween.Playing = true
	
	-- Handle cross tween conflicts.
	local instance = tween.Instance
	local values = tween.Values
	
	for _, otherTween in tweens do
		if otherTween.Instance == instance then
			local otherValues = otherTween.Values
			for value in values do
				if otherValues[value] ~= nil then
					if otherTween.Playing then
						stop(otherTween)
						if otherTween.Stopped then otherTween.Stopped:Fire() end
					end
					break
				end
			end
		end
	end
	
	-- Set time markers.
	local currentTime = getTime()
	local stopDuration = currentTime - tween.StopTime
	if not startOverride then tween.StartTime += stopDuration end
	if tween.Interval then tween.LastUpdate = currentTime end
	if tween.WaitTime then tween.WaitTime += stopDuration end
	tween.StopTime = nil
	
	-- Add tween.
	tweensAmount += 1
	tweens[tweensAmount] = tween
	tween.Index = tweensAmount
end

-- Setup tween processing.
do
	local connection = (if plugin then RunService.Heartbeat else RunService.PreSimulation):Connect(function()
		if tweensAmount == 0 then return end
		
		local currentTime = getTime()
		for _, tween in tweens do
			-- Ensure desired interval (specified in FPS).
			if tween.Interval then
				if currentTime - tween.LastUpdate < tween.Interval then continue end
				tween.LastUpdate = currentTime
			end
			
			-- Account for wait.
			if tween.WaitTime then
				if currentTime - tween.WaitTime < tween.DelayTime then continue end
				tween.WaitTime = nil
				tween.StartTime = currentTime
			end
			
			-- Calculate progress and update values.
			local alpha = (currentTime - tween.StartTime)*tween.InverseTweenTime
			
			local phaseCompleted = alpha >= 1
			
			if phaseCompleted then
				if tween.Reverse then
					alpha = 0
					for _, reset in tween.ResetFunctions do reset() end -- Reset is equivelant to updating to alpha 0, but faster due to lack of interpolation.
				else
					alpha = 1
					for _, update in tween.UpdateFunctions do update(1) end
				end
			else
				if tween.Reverse then alpha = 1 - alpha end -- Reverse alpha to match, if going in reverse.
				
				local easedAlpha = tween.Ease(alpha)
				for _, update in tween.UpdateFunctions do update(easedAlpha) end
			end
			
			-- Save alpha and fire update signal.
			local updateSignal = tween.Updated
			if updateSignal then
				-- Rest assured it's a local tween because it has signals.
				tween.Alpha = alpha
				updateSignal:Fire()
			else
				tween.Alpha = alpha
			end
			
			-- Phase completion stuff.
			if phaseCompleted then
				if tween.Reverse then -- Already going in reverse. Means reversing is enabled, so no need to check for that.
					tween.Repetitions += 1
					if tween.RepeatCount == -1 or tween.Repetitions < tween.RepeatCount then
						if tween.DelayTime then tween.WaitTime = currentTime end
						tween.StartTime = currentTime
						tween.Reverse = nil
					else
						stop(tween)
						if updateSignal then -- If there's one signal, we know there are all of them.
							tween.Stopped:Fire()
							tween.Completed:Fire()
						end
					end
				else -- Not going in reverse.
					tween.Repetitions += 1
					if tween.Reverses then
						-- Reversing enabled.
						if tween.DelayTime then tween.WaitTime = currentTime end
						tween.Reverse = true
						tween.StartTime = currentTime
					else
						-- Reversing disabled.
						if tween.RepeatCount == -1 or tween.Repetitions < tween.RepeatCount then
							if tween.DelayTime then tween.WaitTime = currentTime end
							tween.StartTime = currentTime
						else
							stop(tween)
							if updateSignal then -- If there's one signal, we know there are all of them.
								tween.Stopped:Fire()
								tween.Completed:Fire()
							end
						end
					end
				end
			end
		end
	end)
	
	if plugin then
		-- On plugin unload, connections stay, unlike in games.
		-- Therefore, we manually erase connections.
		plugin.Unloading:Connect(function()
			connection:Disconnect()
		end)
	end
end

-- Tween class.
local Tween = {}
Tween.__index = Tween

Tween.Start = function(tween: InternalTween)
	if not tween.Playing then
		start(tween)
		if Signal then tween.Started:Fire() end
	end
	return tween
end
Tween.Stop = function(tween: InternalTween)
	if tween.Playing then
		stop(tween)
		if Signal then tween.Stopped:Fire() end
	end
	return tween
end
Tween.Reset = function(tween: InternalTween)
	if tween.Playing then
		stop(tween)
		if Signal then tween.Stopped:Fire() end
	end
	tween.WaitTime = nil
	tween.StopTime = 0
	tween.StartTime = 0
	tween.Repetitions = 0
	tween.Reverse = nil
	for _, reset in tween.ResetFunctions do reset() end
	return tween
end
Tween.Destroy = destroy

-- Global tweens setup.
if packets then
	local requiredPackets = {
		"CreateTween",
		"StartTween",
		"StopTween",
		"ResetTween",
		"DestroyTween"
	}
	local tweenPackets = {}
	for _, name in requiredPackets do
		if packets[name] then table.insert(tweenPackets, name) end
	end
	if #tweenPackets == #requiredPackets then
		requiredPackets, tweenPackets = nil -- Erase unnecessary data.
		
		local globalTweens = table.create(256) -- Preallocate the maximum amount of global tweens.
		
		local function serverDestroy(tween: InternalTween)
			-- Remove from collection.
			globalTweens[tween.Identifier] = nil
			
			-- Ensure no playback.
			if tween.Playing then
				-- Tween removal.
				local index = tween.Index
				if index == tweensAmount then
					tweens[tweensAmount] = nil
				else
					local last = tweens[tweensAmount]
					last.Index = index
					tweens[index] = last
					tweens[tweensAmount] = nil
				end
				tweensAmount -= 1
			end
			
			-- Unlink methods.
			setmetatable(tween, nil)
		end
		
		packets.CreateTween.OnClientEvent:Connect(function(identifier, instance, values, options)
			-- Argument errors.
			if not instance then error("Could not find instance on client.") end
			
			-- Handle values.
			local updateFunctions, resetFunctions = createUpdateFunctions(apiMap, instance, values)
			
			-- Create tween.
			local easingStyle = options[2]
			local tween = {
				-- Identifier.
				Identifier = identifier,
				
				-- Main arguments.
				Instance = instance,
				Values = values,
				
				-- Value functions.
				UpdateFunctions = updateFunctions,
				ResetFunctions = resetFunctions,
				
				-- Options.
				InverseTweenTime = options[1] or defaults.InverseTime,
				Ease = if easingStyle then
					if easingStyle == "Linear" then easingFunctions.Linear else easingFunctions[easingStyle][options[3]]
				else
					easingFunctions.Linear,
				DelayTime = options[4] or defaults.DelayTime,
				Reverses = options[5] or defaults.Reverses,
				RepeatCount = options[6] or defaults.RepeatCount,
				Interval = options[7] or defaults.Interval,
				
				-- Time markers.
				StartTime = 0,
				StopTime = 0,
				
				-- Trackers.
				Repetitions = 0
			}
			
			-- Store the tween with its given identifier.
			globalTweens[identifier] = tween
			
			-- Handle instance destroy.
			instance.Destroying:Once(function()
				serverDestroy(tween)
			end)
		end)
		
		packets.StartTween.OnClientEvent:Connect(function(identifier, runTime, repetitions)
			local tween = globalTweens[identifier]
			if not tween then return end
			
			if repetitions then
				tween.Repetitions = repetitions
				if tween.Reverses then
					tween.Reverse = if repetitions%2 == 1 then true else nil
				end
			end
			if tween.StopTime then
				if runTime then
					tween.StartTime = getTime() - runTime
					start(tween, true)
				else
					start(tween)
				end
			end
		end)
		packets.StopTween.OnClientEvent:Connect(function(identifier)
			local tween = globalTweens[identifier]
			if not tween then return end
			
			if tween.Playing then stop(tween) end
		end)
		packets.ResetTween.OnClientEvent:Connect(function(identifier)
			local tween = globalTweens[identifier]
			if not tween then return end
			
			if tween.Playing then stop(tween) end
			for _, reset in tween.ResetFunctions do reset() end
		end)
		packets.DestroyTween.OnClientEvent:Connect(function(identifier)
			local tween = globalTweens[identifier]
			if not tween then return end
			
			serverDestroy(tween)
		end)
	end
end

-- Local tween creation.
return function(instance, values, options)
	-- Argument errors.
	if typeof(instance) ~= "Instance" then error("Invalid instance.", 2) end
	if type(values) ~= "table" then error("Invalid values.", 2) end
	if type(options) ~= "table" then error("Invalid options.", 2) end
	
	-- Handle values.
	local updateFunctions, resetFunctions = createUpdateFunctions(apiMap, instance, values)
	
	-- Handle options.
	local tweenTime = options.Time
	if type(tweenTime) ~= "number" then
		tweenTime = defaults.InverseTime
	elseif tweenTime <= 0 then
		tweenTime = 0
	else
		tweenTime = 1/tweenTime
	end
	
	local ease
	do
		local easingStyle = options.EasingStyle
		local easing = easingFunctions[easingStyle]
		if not easing then
			easingStyle = "Linear"
			easing = easingFunctions.Linear
		end
		if easingStyle == "Linear" then
			ease = easing
		else
			local easingDirection = options.EasingDirection
			ease = easing[easingDirection]
			if not ease then
				easingDirection = defaults.EasingDirection
				ease = easing[easingDirection]
			end
		end
	end
	
	
	local delayTime = options.DelayTime
	if type(delayTime) ~= "number" or delayTime <= 0 then
		delayTime = defaults.DelayTime
	end
	
	local reverses = options.Reverses
	if reverses == false then
		reverses = nil
	elseif reverses ~= true then
		reverses = defaults.Reverses
	end
	
	local repeatCount = options.RepeatCount
	if type(repeatCount) ~= "number" then
		repeatCount = defaults.RepeatCount
	elseif repeatCount < 0 then
		repeatCount = -1
	end
	
	
	local interval = options.FPS
	if type(interval) == "number" then
		interval = 1/interval
	end
	
	-- Create tween.
	local tween = setmetatable({
		-- Main arguments.
		Instance = instance,
		Values = values,
		
		-- Value functions.
		UpdateFunctions = updateFunctions,
		ResetFunctions = resetFunctions,
		
		-- Options.
		InverseTweenTime = tweenTime,
		Ease = ease,
		DelayTime = delayTime,
		Reverses = reverses,
		RepeatCount = repeatCount,
		Interval = interval,
		
		-- Time markers.
		StartTime = 0,
		StopTime = 0,
		
		-- Trackers.
		Repetitions = 0,
		Alpha = 0
	}, Tween)
	
	-- Signals.
	if Signal then
		tween.Updated = Signal()
		tween.Started = Signal()
		tween.Stopped = Signal()
		tween.Completed = Signal()
	end
	
	-- Handle instance destroy.
	instance.Destroying:Once(function()
		destroy(tween)
	end)
	
	-- Return tween object.
	return tween
end