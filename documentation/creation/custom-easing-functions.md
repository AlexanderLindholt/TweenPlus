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
---

# Custom easing functions

Instead of moving from `0` to `1` at a constant rate (linear), an easing function remaps time so motion isn’t constant but changing.

Usually, easing styles have 4 directions:

* **In**: slow → fast
* **Out**: fast → slow
* **In-Out**: slow → fast → slow
* **Out-In:** fast → slow → fast

Easing is crucial in animations to make them feel natural, rather than robotic, and can usually be visualized with graphs, showing the motion from A to B. Check out examples [here](https://easings.net/).



***



To add your own easing functions alongside the built-in ones, simply create a new module in your game, then [tag](https://create.roblox.com/docs/studio/properties#instance-tags) it `EasingFunctions`.

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
Tween+ will let you know if you do anything wrong!
{% endhint %}

{% hint style="info" %}
You can always look in `Tween->Utilities->EasingFunctions` to see how the built-in ones are made. Just keep in mind they’re ultra-optimized.
{% endhint %}
