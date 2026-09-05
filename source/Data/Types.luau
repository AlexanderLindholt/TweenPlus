-- Signal types from Signal+.
local SignalPlus = require(script.Parent.Parent.Packages.signalplus)
export type Signal<T> = SignalPlus.Signal<T>

-- Internal server tween base.
export type InternalTween = {
	Index: number?,
	
	Playing: boolean,
	
	Updated: Signal<nil>?,
	Started: Signal<nil>?,
	Stopped: Signal<nil>?,
	Completed: Signal<nil>?,
	
	Instance: Instance,
	Values: Values,
	
	UpdateFunctions: {(alpha: number) -> ()},
	ResetFunctions: {() -> ()},
	
	InverseTweenTime: number,
	Ease: (alpha: number) -> (),
	RepeatCount: number,
	Reverses: boolean,
	Interval: number?,
	Table: {},
	
	StartTime: number,
	StopTime: number?,
	WaitTime: number?,
	LastUpdate: number?,
	
	Repetitions: number,
	Reverse: boolean,
	Alpha: number
}

-- Obligatory module return.
return nil
