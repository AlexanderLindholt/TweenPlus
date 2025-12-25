---
icon: gear
layout:
  width: default
  title:
    visible: true
  description:
    visible: false
  tableOfContents:
    visible: true
  outline:
    visible: true
  pagination:
    visible: true
  metadata:
    visible: true
---

# Custom defaults

You can actually replace the default defaults with your own defaults of choice.

Simply create a new module in your game, then [tag](https://create.roblox.com/docs/studio/properties#instance-tags) it `TweenDefaults`.

All you do is return a list of options whose defaults you want to modify.\
Here are the default defaults:

```lua
return {
	Time = 1,
	
	EasingStyle = "Linear",
	EasingDirection = "In",
	
	DelayTime = 0,
	Reverses = false,
	RepeatCount = 0,
	
	FPS = nil
}
```

{% hint style="success" %}
You don’t need to list all options. Those not provided will stay at the default default.
{% endhint %}

{% hint style="warning" %}
Custom defaults are not verified. Therefore, be cautious of what you set them to, as they might cause errors if set incorrectly.
{% endhint %}
