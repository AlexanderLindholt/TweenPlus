---
icon: wrench
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
  tags:
    visible: true
  actions:
    visible: true
  anchors:
    visible: true
---

# Custom easing

Instead of moving from 0 to 1 at a constant speed (linear), an easing function remaps time so the speed of the motion changes over the course of the tween.

Usually, easing styles have 4 "directions":

* **In**: slow → fast
* **Out**: fast → slow
* **In-Out**: slow → fast → slow
* **Out-In:** fast → slow → fast

Easing is crucial in animation and design to make it feel natural and smooth. The functions can be visualized as graphs, which you can check out at [easings.net](https://easings.net/).



***



To add your own easing functions alongside the built-in ones, simply create a new module in your game and [tag](https://create.roblox.com/docs/studio/properties#instance-tags) it `EasingFunctions`.

Here’s the required format:

```luau
-- You can add any code here obviously :D

return {
	-- You can either write a single direction style:
	CoolEasing = function(alpha)
		return alpha
	end,
	
	-- Or you can write an all directions style:
	SuperCoolEasing = {
		In = function(alpha)
			return alpha
		end,
		Out = function(alpha)
			return alpha
		end,
		InOut = function(alpha)
			return alpha
		end,
		OutIn = function(alpha)
			return alpha
		end
	}
}
```

{% hint style="success" %}
Tween+ will as always let you know if you do anything wrong!
{% endhint %}

{% hint style="info" %}
You can always look in `Tween->Utilities->EasingFunctions` to see how the built-in ones are made. However, they are ultra-optimized and not meant to be very readable.
{% endhint %}
