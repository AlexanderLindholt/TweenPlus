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

# Introduction

When you require the module, it’ll return a function, which you can use to create tweens:

```lua
local Tween = require(script.TweenPlus)

local tween = Tween(
	workspace.Part, -- Instance to tween.
	{} -- Values to tween.
)
```

You simply input all the values you would like to tween:

<pre class="language-lua"><code class="lang-lua">local tween = Tween(
	workspace.Part,
	{
<strong>		Position = Vector3.new(0, 10, 0),
</strong><strong>		Color = Color3.fromRGB(255, 255, 0)
</strong><strong>		-- And as many more as you’d like.
</strong>	}
)
</code></pre>
