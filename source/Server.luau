--!optimize 2
--!native

-- Services.
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Get and verify network packets.
local packets = CollectionService:GetTagged("Packets")[1]
if packets then
	packets = require(packets)
	
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
	if #tweenPackets < #requiredPackets then
		packets = nil
		if #tweenPackets > 0 then
			for _, name in requiredPackets do
				if not tweenPackets[name] then packets = nil warn("Packet '"..name.."' is missing for global tweening to function.") end
			end
		end
	end
end

-- Signal library.
local Signal = CollectionService:GetTagged("Signal")[1]
if Signal then
	Signal = require(Signal)
	if type(Signal) == "table" and Signal.new then Signal = Signal.new end
end

-- Directories.
local root = script.Parent
local data = root.Data
local utilities = root.Utilities

-- Easing functions.
local easingFunctions = require(utilities.EasingFunctions)

-- Updation functions constructor.
local createUpdateFunctions = require(utilities.UpdateFunctions)

-- Option defaults.
local defaults = require(data.Defaults)

-- Types.
local types = require(data.Types)

type Signal = types.Signal
type InternalTween = types.InternalTween & {
	Identifier: number,
	
	PlayerConnection: Signal
}

-- Localize packets.
if packets then
	createTweenPacket = packets.CreateTween
	startTweenPacket = packets.StartTween
	stopTweenPacket = packets.StopTween
	resetTweenPacket = packets.ResetTween
	destroyTweenPacket = packets.DestroyTween
end

-- Store all possible global tween identifiers.
local globalIdentifiers = table.create(256)
for identifier = 0, 255 do
	globalIdentifiers[identifier] = true
end

-- Active tweens collection.
local tweens: {InternalTween} = table.create(script.Parent:GetAttribute("TweenPreallocations"))
local tweensAmount = 0

-- Tween functions.
local function stop(tween: InternalTween)
	-- Verify playback state.
	if not tween.Playing then return end
	
	-- Set playing state.
	tween.Playing = nil
	
	-- Update instance values.
	local alpha = tween.Alpha
	if alpha ~= 1 and alpha ~= 0 then alpha = tween.Ease(alpha) end
	for _, update in tween.UpdateFunctions do update(alpha) end
	
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
	tween.StopTime = time()
	
	-- Fire stopped signal.
	if Signal then tween.Stopped:Fire() end
end
local function destroy(tween: InternalTween)
	-- Disconnect new player connection.
	local playerConnection = tween.PlayerConnection
	if playerConnection then playerConnection:Disconnect() end
	-- Disconnect destroy connection.
	tween.DestroyConnection:Disconnect()
	
	-- Free up identifier.
	globalIdentifiers[tween.Identifier] = true
	
	-- Ensure no playback.
	if tween.Playing then
		-- Update instance values.
		local alpha = tween.Alpha
		if alpha ~= 1 and alpha ~= 0 then alpha = tween.Ease(alpha) end
		for _, update in tween.UpdateFunctions do
			update(alpha)
		end
		
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

-- Setup tween processing.
RunService.PreSimulation:Connect(function()
	if tweensAmount == 0 then return end
	
	local currentTime = time()
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
		
		if tween.Identifier then
			if phaseCompleted then
				alpha = if tween.Reverse then 0 else 1 -- Force the value to ensure it doesn't exceed the range 0-1.
			else
				if tween.Reverse then alpha = 1 - alpha end -- Reverse alpha to match if going in reverse.
			end
		else
			if phaseCompleted then
				if tween.Reverse then
					alpha = 0
					for _, update in tween.UpdateFunctions do update(0) end
				else
					alpha = 1
					for _, update in tween.UpdateFunctions do update(1) end
				end
			else
				if tween.Reverse then alpha = 1 - alpha end -- Reverse alpha to match if going in reverse.
				
				local easedAlpha = tween.Ease(alpha)
				for _, update in tween.UpdateFunctions do update(easedAlpha) end
			end
		end
		
		-- Save alpha.
		tween.Alpha = alpha
		
		-- Fire update signal.
		if Signal then
			tween.Alpha = alpha
			tween.Updated:Fire()
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
					if Signal then
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
						if Signal then
							tween.Stopped:Fire()
							tween.Completed:Fire()
						end
					end
				end
			end
		end
	end
end)

-- Tween class.
local Tween = {}
Tween.__index = Tween

Tween.Start = function(tween: InternalTween)
	-- Verify playback state.
	if tween.Playing then return tween end
	
	-- Notify clients.
	for _, player in Players:GetPlayers() do
		startTweenPacket:FireClient(player, tween.Identifier)
	end
	
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
					if otherTween.Playing then stop(otherTween) end
					break
				end
			end
		end
	end
	
	-- Set time markers.
	local currentTime = time()
	local stopDuration = currentTime - tween.StopTime
	tween.StartTime += stopDuration
	if tween.Interval then tween.LastUpdate = currentTime end
	if tween.WaitTime then tween.WaitTime += stopDuration end
	tween.StopTime = nil
	
	-- Add tween.
	tweensAmount += 1
	tweens[tweensAmount] = tween
	tween.Index = tweensAmount
	
	-- Fire started signal.
	if Signal then tween.Started:Fire() end
	
	-- Return self.
	return tween
end
Tween.Stop = function(tween: InternalTween)
	if tween.Playing then
		for _, player in Players:GetPlayers() do
			stopTweenPacket:FireClient(player, tween.Identifier)
		end
		
		stop(tween)
	end
	return tween
end
Tween.Reset = function(tween: InternalTween)
	for _, player in Players:GetPlayers() do
		resetTweenPacket:FireClient(player, tween.Identifier)
	end
	
	if tween.Playing then stop(tween) end
	tween.WaitTime = nil
	tween.StopTime = 0
	tween.StartTime = 0
	tween.Repetitions = 0
	tween.Reverse = nil
	for _, update in tween.UpdateFunctions do update(0) end
	
	return tween
end
Tween.Destroy = function(tween: InternalTween)
	for _, player in Players:GetPlayers() do
		destroyTweenPacket:FireClient(player, tween.Identifier)
	end
	
	destroy(tween)
end

-- Tween creation.
return function(instance, values, options)
	-- Argument validation.
	if typeof(instance) ~= "Instance" then error("Invalid instance.", 2) end
	if type(values) ~= "table" then error("Invalid values.", 2) end
	
	-- Handle networking stuff.
	local replicate = options.Replicate
	if replicate ~= true and replicate ~= false then replicate = defaults.Replicate end
	
	local globalIdentifier
	if packets then -- Valid networking setup.
		if replicate then
			globalIdentifier = next(globalIdentifiers)
			if not globalIdentifier then error("Maximum global tweens (256) exceeded. Destroy tweens to free up space.", 2) end
		end
	else -- Invalid networking setup.
		if replicate then
			error("Global tweening not available. Please set up necessary networking or disable replicate.")
		end
	end
	
	-- Handle values.
	local updateFunctions = createUpdateFunctions(instance, values)
	
	-- Set up tween.
	local tween
	
	if replicate then -- Global tween.
		-- Handle options.
		local optionsForClients = {}
		
		local tweenTime = options.Time
		if type(tweenTime) ~= "number" then
			tweenTime = defaults.InverseTime
		else
			if tweenTime <= 0 then
				tweenTime = 0
			else
				tweenTime = 1/tweenTime
			end
			if tweenTime ~= defaults.Time then optionsForClients[1] = tweenTime end
		end
		
		local easingFunction
		do
			local easingStyle = options.EasingStyle
			local easing = easingFunctions[easingStyle]
			if easing then
				if easingStyle ~= defaults.EasingStyle then optionsForClients[2] = easingStyle end
			else
				easing = easingFunctions[defaults.EasingStyle]
			end
			
			if type(easing) == "table" then
				local easingDirection = options.EasingDirection
				easingFunction = easing[easingDirection]
				if easingFunction then
					if easingDirection ~= defaults.EasingDirection then optionsForClients[3] = easingDirection end
				else
					easingFunction = easing[defaults.EasingDirection]
				end
			end
		end
		
		local delayTime = options.DelayTime
		if type(delayTime) ~= "number" or delayTime <= 0 then
			delayTime = defaults.DelayTime
		end
		if delayTime ~= defaults.DelayTime then optionsForClients[4] = delayTime end
		
		local reverses = options.Reverses
		if reverses == false then
			reverses = nil
			if defaults.Reverses then optionsForClients[5] = false end
		elseif reverses == true then
			if not defaults.Reverses then optionsForClients[5] = true end
		else
			reverses = defaults.Reverses
		end
		
		local repeatCount = options.RepeatCount
		if type(repeatCount) ~= "number" then
			repeatCount = defaults.RepeatCount
		else
			if repeatCount < 0 then repeatCount = -1 end
			if repeatCount ~= defaults.RepeatCount then optionsForClients[6] = repeatCount end
		end
		
		local interval = options.FPS
		if type(interval) == "number" then
			interval = 1/interval
			if interval ~= defaults.Interval then optionsForClients[7] = interval end
		else
			interval = defaults.Interval
		end
		
		-- Notify clients.
		for _, player in Players:GetPlayers() do
			createTweenPacket:FireClient(player, globalIdentifier, instance, values, optionsForClients)
		end
		
		-- Create tween.
		tween = setmetatable({
			-- Identifier.
			Identifier = globalIdentifier,
			
			-- New player handling.
			PlayerConnection = Players.PlayerAdded:Connect(function(player)
				createTweenPacket:FireClient(player, globalIdentifier, instance, values, optionsForClients)
				
				if tween.Playing then
					startTweenPacket:FireClient(
						player,
						globalIdentifier,
						
						workspace:GetServerTimeNow(),
						time() - tween.StartTime,
						tween.Repetitions
					)
				end
			end),
			
			-- Main arguments.
			Instance = instance,
			Values = values,
			
			-- Value functions.
			UpdateFunctions = updateFunctions,
			
			-- Options.
			InverseTweenTime = tweenTime,
			Ease = easingFunction,
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
	else -- Local tween.
		-- Handle options.
		local tweenTime = options.Time
		if type(tweenTime) ~= "number" then
			tweenTime = defaults.InverseTime
		elseif tweenTime <= 0 then
			tweenTime = 0
		else
			tweenTime = 1/tweenTime
		end
		
		local easingFunction = easingFunctions[options.EasingStyle] or easingFunctions[defaults.EasingStyle]
		if type(easingFunction) == "table" then
			easingFunction = easingFunction[options.EasingDirection] or easingFunction[defaults.EasingDirection]
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
		tween = setmetatable({
			-- Main arguments.
			Instance = instance,
			Values = values,
			
			-- Value functions.
			UpdateFunctions = updateFunctions,
			
			-- Options.
			InverseTweenTime = tweenTime,
			Ease = easingFunction,
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
	end
	
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