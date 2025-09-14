--!optimize 2
--!native

-- Services.
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Network packets.
local packets = CollectionService:GetTagged("Packets")[1]
if not packets then error("Could not find packets module.") end
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
if #tweenPackets ~= #requiredPackets then
	if #tweenPackets > 0 and RunService:IsStudio() then
		for _, name in requiredPackets do
			if not tweenPackets[name] then warn("Packet '"..name.."' is missing for server tweening to function.") end
		end
	end
	error("Missing packets for server tweening to work.")
end

-- Ready players table.
local players = CollectionService:GetTagged("PlayerList")[1]
if not players then error("Could not find a player-list module.") end
players = require(players)()

-- Roblox API map.
local apiMap = CollectionService:GetTagged("APIMap")[1]
if not apiMap then error("Could not find APIMap module.") end
apiMap = require(apiMap)

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
	
	PlayerConnection: Signal,
	DestroyConnection: Signal,
}

-- Localize packets.
local loadedPacket = packets.Loaded
local createTweenPacket = packets.CreateTween
local startTweenPacket = packets.StartTween
local stopTweenPacket = packets.StopTween
local resetTweenPacket = packets.ResetTween
local destroyTweenPacket = packets.DestroyTween

-- Store all possible tween identifiers.
local identifiers = {}
for identifier = 0, 255, 1 do
	identifiers[identifier] = true
end

-- Active tweens collection.
local tweens: {InternalTween} = table.create(256)

-- Tween functions.
local function stop(tween: InternalTween)
	-- Verify playback state.
	if not tween.Playing then return end
	
	-- Set playing state.
	tween.Playing = nil
	
	-- Update instance values.
	local alpha = tween.Ease(tween.Alpha)
	for _, update in tween.UpdateFunctions do update(alpha) end
	
	-- Tween removal.
	local lastIndex = #tweens
	local index = tween.Index
	if index == lastIndex then
		tweens[lastIndex] = nil
	else
		local last = tweens[lastIndex]
		last.Index = index
		tweens[index] = last
		tweens[lastIndex] = nil
	end
	
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
	identifiers[tween.Identifier] = true
	
	-- Ensure no playback.
	if tween.Playing then
		-- Update instance values.
		local alpha = tween.Ease(tween.Alpha)
		for _, update in tween.UpdateFunctions do
			update(alpha)
		end
		
		-- Tween removal.
		local lastIndex = #tweens
		local index = tween.Index
		if index == lastIndex then
			tweens[lastIndex] = nil
		else
			local last = tweens[lastIndex]
			last.Index = index
			tweens[index] = last
			tweens[lastIndex] = nil
		end
		
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
RunService.PostSimulation:Connect(function()
	if #tweens == 0 then return end
	
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
		
		-- Calculate alpha.
		local alpha = (currentTime - tween.StartTime)*tween.InverseTweenTime
		
		local phaseCompleted = alpha >= 1
		
		if phaseCompleted then
			alpha = if tween.Reverse then 0 else 1 -- Force the value to ensure it doesn't exceed the range 0-1.
		else
			if tween.Reverse then alpha = 1 - alpha end -- Reverse alpha to match, if going in reverse.
		end
		
		-- Save alpha.
		tween.Alpha = alpha
		
		-- Fire update signal.
		if Signal then
			-- Rest assured it's a local tween because it has signals.
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
					if not tween.StopTime then
						stop(tween)
						if Signal then
							tween.Stopped:Fire()
							tween.Completed:Fire()
						end
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
						if not tween.StopTime then
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
	end
end)

-- Tween class.
local Tween = {}
Tween.__index = Tween

Tween.Start = function(tween: InternalTween)
	-- Verify playback state.
	if tween.Playing then return tween end
	
	-- Notify clients.
	for _, player in players do
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
					if otherTween.Playing then
						stop(otherTween)
					end
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
	local tweensAmount = #tweens
	tweens[tweensAmount] = tween
	tween.Index = tweensAmount
	
	-- Fire started signal.
	if Signal then tween.Started:Fire() end
	
	-- Return self.
	return tween
end
Tween.Stop = function(tween: InternalTween)
	if tween.Playing then
		for _, player in players do
			stopTweenPacket:FireClient(player, tween.Identifier)
		end
		
		stop(tween)
	end
	return tween
end
Tween.Reset = function(tween: InternalTween)
	for _, player in players do
		resetTweenPacket:FireClient(player, tween.Identifier)
	end
	
	if tween.Playing then stop(tween) end
	tween.WaitTime = nil
	tween.StopTime = 0
	tween.StartTime = 0
	tween.Repetitions = 0
	tween.Reverse = nil
	for _, reset in tween.ResetFunctions do reset() end
	
	return tween
end
Tween.Destroy = function(tween: InternalTween)
	for _, player in players do
		destroyTweenPacket:FireClient(player, tween.Identifier)
	end
	
	destroy(tween)
end

-- Tween creation.
return function(instance, values, options)
	-- Argument errors.
	if typeof(instance) ~= "Instance" then error("No instance provided.", 2) end
	if type(values) ~= "table" or not next(values) then error("No values provided.", 2) end
	if type(options) ~= "table" or not next(options) then error("Invalid options.", 2) end
	
	-- Get and verify identifier.
	local identifier = next(identifiers)
	if not identifier then error("Maximum server tweens (256) exceeded. Destroy tweens to free up space.", 2) end
	
	-- Handle values.
	local updateFunctions, resetFunctions = createUpdateFunctions(apiMap, instance, values)
	
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
			
			optionsForClients[2] = easingStyle
			optionsForClients[3] = easingDirection
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
	local replicate = options.Replicate
	if replicate ~= false then 
		for _, player in players do
			createTweenPacket:FireClient(player, identifier, instance, values, optionsForClients)
		end
	end
	
	-- Create tween.
	local tween
	tween = setmetatable({
		-- Identifier.
		Identifier = identifier,
		
		-- Handle instance destroy.
		DestroyConnection = instance.Destroying:Connect(function()
			destroy(tween)
		end),
		
		-- New player handling.
		PlayerConnection = if replicate ~= false then loadedPacket.OnServerEvent:Connect(function(player)
			createTweenPacket:FireClient(player, identifier, instance, values, optionsForClients)
			if not tween.StopTime then
				startTweenPacket:FireClient(player, identifier, time() - tween.StartTime, tween.Repetitions)
			end
		end) else nil,
		
		-- Signals.
		Updated = Signal(),
		Started = Signal(),
		Stopped = Signal(),
		Completed = Signal(),
		
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
	
	-- Handle instance destroy.
	instance.Destroying:Connect(function()
		destroy(tween)
	end)
	
	-- Return tween.
	return tween
end