--!optimize 2

--[[

=============== ====      ====      ====  ========================   ====       ====                
=============== =====    ======    =====  ========================   ======     ====        :::     
     ====        ====    ======    ====   ====                       =======    ====        :::     
     ====         ====  ========  ====    ====                       ========   ====        :::     
     ====         ====  ===  ===  ====    =======================    ==== ===== ====   :::::::::::::
     ====          ========  ========     ====                       ====   ========        :::     
     ====          =======    =======     ====                       ====    =======        :::     
     ====           ======    ======      ========================   ====     ======        :::     
     ====            ====      ====       ========================   ====       ====                

v2.0.2

An open-source tweening library for Roblox, featuring advanced
datatypes, customization, interpolation, and optimization.


GitHub:
https://github.com/AlexanderLindholt/TweenPlus

DevForum:
https://devforum.roblox.com/t/3599638


--------------------------------------------------------------------------------
MIT License

Copyright (c) 2025 Alexander Lindholt

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--------------------------------------------------------------------------------

]]--

-- Services.
local RunService = game:GetService("RunService")

-- Shared types.
local types = require(script.Data.Types)

-- Signal type.
type Signal = types.Signal

-- Tween types.
export type Tween = {
	Start: typeof(
		-- Starts or resumes playback of the tween.
		function(tween: Tween) end
	),
	Stop: typeof(
		-- Stops playback of the tween.
		-- Can be resumed with <code>Start()</code>.
		function(tween: Tween) end
	),
	Reset: typeof(
		-- Stops playback of the tween, and resets to starting values.
		function(tween: Tween) end
	),
	Destroy: typeof(
		-- Makes the tween unusable, and ensures it's stopped.
		function(tween: Tween) end
	),
	
	Updated: Signal<number>,
	Started: Signal,
	Stopped: Signal,
	Completed: Signal
}
export type Customization = {
	Time: number?,
	
	EasingStyle:
		"Linear" |
		"Quad" |
		"Cubic" |
		"Quart" |
		"Quint" |
		"Sine" |
		"Exponential" |
		"Circular" |
		"Elastic" |
		"Back" |
		"Bounce"?,
	EasingDirection:
		"In" |
		"Out" |
		"InOut" |
		"OutIn"?,
	
	RepeatCount: number?,
	Reverses: boolean?,
	DelayTime: number?,
	
	FPS: number?,
	
	Update: "PostSimulation" | "PreSimulation"?
}
type Values = {[string]: any}
type CreateTween = typeof(
	-- Creates a new tween.
	function(instance: Instance, values: Values, customization: Customization): Tween end
)

-- Run and return depending on run context.
return if RunService:IsClient() then
	require(script.Client) :: CreateTween
else -- Server.
	require(script.Server) :: CreateTween
