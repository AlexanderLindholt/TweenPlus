---
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

# States

The following are properties representing the tween’s state:

* **Playing**: boolean
* **Repetitions**: number
* **Reverse**: boolean
* [**Alpha**](#user-content-fn-1)[^1]: number



Example:

{% code title="Script1" %}
```lua
local tween = Tween(workspace.Part, {Transparency = 1}, {Time = 2, Repetitions = 5, Reverses = true})
shared.MyTween = tween -- Share the tween with other scripts.
tween:Start()
```
{% endcode %}

{% code title="Script2" %}
```lua
task.wait(5)
if shared.MyTween.Playing then
	print("Tween is still playing, wow!")
	-- Let’s print some information about the progress!
	print("Tween is going "..(if shared.MyTween.Reverses then " in reverse" else "forward").."!")
	print("Tween has done "..shared.MyTween.Repetitions.." repetitions!")
	print("Tween is exactly "..shared.MyTween.Alpha*100.."% done with the current repetition.") -- Alpha is in the range 0-1, so we multiply by 100 to get the percentage.
else
	print("Tween is not playing anymore :(")
end
```
{% endcode %}

{% hint style="info" %}
Note that this is a rather useless example, simply to give an idea of what it does.\
There are actually good use cases for this of course!
{% endhint %}

[^1]: _`Alpha` is the linear progress from start to finish in the range 0-1. With reversing and repeats it will actually go back and forth._
