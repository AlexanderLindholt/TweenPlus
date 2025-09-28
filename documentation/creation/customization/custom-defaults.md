---
icon: gear
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

# Custom defaults

You can actually replace the default defaults with your own defaults of choice.

Simply create a new module and name it whatever you want — `TweenDefaults` is recommended.\
It's crucial that you give it the [tag](https://create.roblox.com/docs/studio/properties#instance-tags) `TweenDefaults`, so that Tween+ can identify it.

The module has to return a table, like this:

```lua
return {
	
}
```

{% hint style="success" %}
You don't need to list all options. Those not provided will stay at the default default.
{% endhint %}

Here's the default defaults:

```lua
return {
	Time = 1,
	
	EasingDirection = "In",
	
	DelayTime = 0,
	Reverses = false,
	RepeatCount = 0,
	
	FPS = nil
}
```
