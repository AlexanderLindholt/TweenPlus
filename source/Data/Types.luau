-- Signal types from Signal+.
export type Connection = {
	Connected: boolean,
	Disconnect: typeof(
		-- Removes the connection from the signal.
		-- <strong>The connection’s data remains.</strong>
		function(connection: Connection) end
	)
}
export type Signal<Parameters...> = {
	Connect: typeof(
		-- Connects a function.
		function(signal: Signal<Parameters...>, callback: (Parameters...) -> ()): Connection end
	),
	Once: typeof(
		-- Connects a function, then auto-disconnects after the first call.
		function(signal: Signal<Parameters...>, callback: (Parameters...) -> ()): Connection end
	),
	Wait: typeof(
		-- Yields the calling thread until the next fire.
		function(signal: Signal<Parameters...>): Parameters... end
	),
	
	Fire: typeof(
		-- Runs all connected functions, and resumes all waiting threads.
		function(signal: Signal<Parameters...>, ...: Parameters...) end
	),
	
	DisconnectAll: typeof(
		-- Erases all connections.
		-- <strong>Much faster than calling <code>Disconnect</code> on each.</strong>
		function(signal: Signal<Parameters...>) end
	),
	Destroy: typeof(
		-- Erases all connections and methods.
		-- <strong>To fully erase, also remove all references to the signal.</strong>
		function(signal: Signal<Parameters...>) end
	)
}

-- Internal server tween base.
export type InternalTween = {
	Index: number?,
	
	Playing: boolean,
	
	Updated: Signal?,
	Started: Signal?,
	Stopped: Signal?,
	Completed: Signal?,
	
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