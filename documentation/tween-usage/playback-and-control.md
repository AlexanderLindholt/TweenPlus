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

# Playback and control

After creating a new tween, you can use the following methods:

* [**Start**](#user-content-fn-1)[^1]
* [**Stop**](#user-content-fn-2)[^2]
* [**Reset**](#user-content-fn-3)[^3]
* [**Destroy**](#user-content-fn-4)[^4]



Example usage:

```luau
local tween = Tween(workspace.Part, {Transparency = 1}, {Time = 2})
tween:Start() -- Initial playback start.
task.wait(1)
tween:Stop() -- Stop after 1 second of playback.
task.wait(1)
tween:Start() -- Resume after a 1 second pause.
```

```luau
local tween = Tween(workspace.Part, {Transparency = 1}, {Time = 2})
tween:Start() -- Initial playback start.
task.wait(1)
tween:Reset() -- Reset after 1 second of playback.
tween:Start() -- Start playback from the beginning again.
task.wait(1)
tween:Destroy() -- Throw the tween in the trash!
```

[^1]: Starts or resumes playback of the tween.

[^2]: Stops playback of the tween.\
    Can be resumed with `Start()`.

[^3]: Stops playback of the tween, and resets to starting values.

[^4]: Makes the tween unusable, and ensures it’s stopped.
