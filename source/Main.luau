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

v2.12.0

An open-source tweening library for Roblox, featuring advanced
datatypes, customization, interpolation, and optimization.


GitHub (repository):
https://github.com/AlexanderLindholt/TweenPlus

GitBook (documentation):
https://alexxander.gitbook.io/TweenPlus

DevForum (topic):
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

-- Types.
local types = require(script.Data.Types)
type Signal = types.Signal

export type Tween = {
	Start: typeof(
		-- Starts/resumes playback.
		function(tween: Tween): Tween end
	),
	Stop: typeof(
		-- Halts playback.
		function(tween: Tween): Tween end
	),
	Reset: typeof(
		-- Halts playback & resets to starting values.
		function(tween: Tween): Tween end
	),
	Destroy: typeof(
		-- Halts playback & erases the tween internally.
		-- <strong>To fully erase, also remove all references to the tween.</strong>
		-- <br><em>Destroying the instance will automatically call this method.</em> 
		function(tween: Tween) end
	),
	
	Playing: boolean,
	Repetitions: number,
	Reverses: boolean,
	Alpha: number,
	
	Updated: Signal,
	Started: Signal,
	Stopped: Signal,
	Completed: Signal
}
export type Options = {
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
	
	Replicate: boolean?
}
type Values = {[string]: any}
type CreateTween = typeof(
	-- Creates a new tween.
	function(instance: Instance, values: Values, options: Options): Tween end
)

-- Continue depending on context.
return if RunService:IsClient() then
	require(script.Client) :: CreateTween
else -- Server.
	require(script.Server) :: CreateTween