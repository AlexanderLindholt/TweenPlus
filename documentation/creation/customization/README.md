---
icon: ballot
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

# Options

The options are provided in a table. You may provide any amount of options you like.\
Those not provided will fallback to their respective defaults.

Example:

<pre class="language-lua"><code class="lang-lua">local tween = Tween(
	workspace.Part,
	{
		Position = Vector3.new(0, 10, 0),
		Color = Color3.fromRGB(255, 255, 0)
	},
<strong>	{ -- Options (optional).
</strong><strong>		Time = 10,
</strong><strong>		EasingStyle = "Sine",
</strong><strong>		EasingDirection = "InOut"
</strong><strong>	}
</strong>)
</code></pre>
