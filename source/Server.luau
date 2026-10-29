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
	local missingPackets = {}
	for _, name in requiredPackets do
		if not packets[name] then table.insert(missingPackets, name) end
	end
	if #missingPackets > 0 then
		packets = nil
		if #missingPackets ~= #requiredPackets then
			for _, name in missingPackets do
				warn("Packet '"..name.."' is missing for global tweening to function.")
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
	Identifier: number?,
	
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
local identifiers = table.create(256)
for identifier = 0, 255 do
	identifiers[identifier] = true
end

-- Active tweens collection.
local tweens: {InternalTween} = {}
local tweensAmount = 0

-- Instance ownership collection for conflict handling.
local owners = {}

-- Tween functions.
local function stop(tween: InternalTween)
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
	
	local entries = owners[tween.Instance]
	for value in tween.Values do
		if entries[value] == tween then entries[value] = nil end
	end
	
	-- Set time markers.
	tween.StopTime = time()
	
	-- Fire stopped signal.
	local signal = rawget(tween, "Stopped")
	if signal then signal:Fire() end
end
local function destroy(tween: InternalTween)
	-- Disconnect new player connection.
	local playerConnection = tween.PlayerConnection
	if playerConnection then playerConnection:Disconnect() end
	
	-- Free up identifier.
	local identifier = tween.Identifier
	if identifier then identifiers[identifier] = true end
	
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
		local signal = rawget(tween, "Stopped")
		if signal then signal:Fire() end
	end
	
	-- Destroy signals.
	local signal = rawget(tween, "Updated")
	if signal then signal:Destroy() end
	signal = rawget(tween, "Started")
	if signal then signal:Destroy() end
	signal = rawget(tween, "Stopped")
	if signal then signal:Destroy() end
	signal = rawget(tween, "Completed")
	if signal then signal:Destroy() end
	
	-- Unlink methods.
	setmetatable(tween, nil)
end

-- Setup tween processing.
RunService.PreSimulation:Connect(function(deltaTime)
	if tweensAmount == 0 then return end
	
	local currentTime = time()
	for index = tweensAmount, 1, -1 do -- Iterate backwards.
		local tween = tweens[index]
		
		-- Ensure desired interval (specified in FPS).
		if tween.Interval then
			if currentTime + deltaTime*0.5 - tween.LastUpdate < tween.Interval then continue end
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
		local signal = rawget(tween, "Updated")
		if signal then signal:Fire() end
		
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
					
					signal = rawget(tween, "Completed")
					if signal then signal:Fire() end
					
					if tween.Once then destroy(tween) end
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
						
						signal = rawget(tween, "Completed")
						if signal then signal:Fire() end
						
						if tween.Once then destroy(tween) end
					end
				end
			end
		end
	end
end)

-- Tween class.
local Tween = {}

local signalNames = {Updated = true, Started = true, Stopped = true, Completed = true}
Tween.__index = function(t, key)
	if signalNames[key] and Signal then
		local signal = Signal()
		rawset(t, key, signal)
		return signal
	end
	return rawget(Tween, key)
end

Tween.Start = function(tween: InternalTween)
	-- Verify playback state.
	if tween.Playing then return tween end
	
	-- Notify clients.
	local identifier = tween.Identifier
	if identifier then
		for _, player in Players:GetPlayers() do
			startTweenPacket:FireClient(player, identifier)
		end
	end
	
	-- Set playing state.
	tween.Playing = true
	
	-- Handle cross tween conflicts.
	local instance = tween.Instance
	
	local entries = owners[instance]
	if entries then
		for value in tween.Values do
			local otherTween = entries[value]
			if otherTween then
				stop(otherTween)
			end
			entries[value] = tween
		end
	else
		entries = {}
		for value in tween.Values do
			entries[value] = tween
		end
		owners[instance] = entries
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
	local signal = rawget(tween, "Started")
	if signal then signal:Fire() end
	
	-- Return self.
	return tween
end
Tween.Stop = function(tween: InternalTween)
	if tween.Playing then
		local identifier = tween.Identifier
		if identifier then
			for _, player in Players:GetPlayers() do
				stopTweenPacket:FireClient(player, identifier)
			end
		end
		
		stop(tween)
	end
	return tween
end
Tween.Reset = function(tween: InternalTween)
	local identifier = tween.Identifier
	if identifier then
		for _, player in Players:GetPlayers() do
			resetTweenPacket:FireClient(player, identifier)
		end
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
	local identifier = tween.Identifier
	if identifier then
		for _, player in Players:GetPlayers() do
			destroyTweenPacket:FireClient(player, identifier)
		end
	end
	
	destroy(tween)
end

-- Tween creation.
return function(instance, values, options)
	-- Argument validation.
	if typeof(instance) ~= "Instance" then error("Invalid instance.", 2) end
	if type(values) ~= "table" then error("Invalid values.", 2) end
	
	-- Ensure options table.
	if not options then options = {} end	

	-- Handle networking stuff.
	local replicate = options.Replicate
	if replicate ~= true and replicate ~= false then replicate = defaults.Replicate end
	
	local identifier
	if packets then -- Valid networking setup.
		if replicate then
			identifier = next(identifiers)
			if not identifier then error("Maximum global tweens (256) exceeded. Destroy tweens to free up space.", 2) end
			identifiers[identifier] = nil
		end
	else -- Invalid networking setup.
		if replicate then
			error("Global tweening not available. Please set up necessary networking or disable replicate.", 2)
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
				error("Tween time has to be more than 0.")
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
		
		local once = options.Once
		if once == false then
			once = nil
			if defaults.Once then optionsForClients[8] = false end
		elseif once == true then
			if not defaults.Once then optionsForClients[8] = true end
		else
			once = defaults.Once
		end
		
		-- Notify clients.
		for _, player in Players:GetPlayers() do
			createTweenPacket:FireClient(player, identifier, instance, values, optionsForClients)
		end
		
		-- Create tween.
		tween = setmetatable({
			-- Identifier.
			Identifier = identifier,
			
			-- New player handling.
			PlayerConnection = Players.PlayerAdded:Connect(function(player)
				createTweenPacket:FireClient(player, identifier, instance, values, optionsForClients)
				
				if tween.Playing then
					startTweenPacket:FireClient(
						player,
						identifier,
						
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
			error("Tween time has to be more than 0.")
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
		if type(interval) == "number" and interval > 0 then
			interval = 1/interval
		else
			interval = defaults.Interval
		end
		
		local once = options.Once
		if once == false then
			once = nil
		elseif once ~= true then
			once = defaults.Once
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
			Once = once,
			
			-- Time markers.
			StartTime = 0,
			StopTime = 0,
			
			-- Trackers.
			Repetitions = 0,
			Alpha = 0
		}, Tween)
	end
	
	-- Handle instance destroy.
	instance.Destroying:Once(function()
		destroy(tween)
	end)
	
	-- Return tween object.
	return tween
end
