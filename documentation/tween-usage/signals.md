---
layout:
  width: default
  title:
    visible: true
  description:
    visible: false
  tableOfContents:
    visible: false
  outline:
    visible: true
  pagination:
    visible: true
  metadata:
    visible: true
---

# Signals

You can enable signals by installing a signal library.

{% hint style="info" %}
[Signal+](https://devforum.roblox.com/t/3552231) is highly recommended for performance.
{% endhint %}

Makes sure to [tag](https://create.roblox.com/docs/studio/properties#instance-tags) the module `Signal`.

***



Each tween will have the following signals:

* [**Updated**](#user-content-fn-1)[^1]
* [**Started**](#user-content-fn-2)[^2]
* [**Stopped**](#user-content-fn-3)[^3]
* [**Completed**](#user-content-fn-4)[^4]



Example usage:

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
