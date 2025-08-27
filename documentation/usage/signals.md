# Signals

After creating a new tween, you can listen to the following signals:

* [**Updated**](#user-content-fn-1)[^1]
* [**Started**](#user-content-fn-2)[^2]
* [**Stopped**](#user-content-fn-3)[^3]
* [**Completed**](#user-content-fn-4)[^4]



Example:

```lua
local tween = Tween(workspace.Part, {Transparency = 1}, {Time = 2})
tween.Updated:Connect(function()
	-- Alpha is in the range 0-1, so we multiply by 100 to get the percentage.
	print("Progress: "..tween.Alpha*100.."%") -- For example "Progress: 50%".
end)
tween:Start()
```

[^1]: Fires every iteration of playback; every time the instance's values are updated.

[^2]: Fires when the playback is started or resumed.

[^3]: Fires when playback is stopped.

    Also fires when playback finishes.

[^4]: Fires when playback finishes.

    Does _**not**_ fire when playback is stopped.
