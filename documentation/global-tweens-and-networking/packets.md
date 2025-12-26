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

# Packets

Create a new ModuleScript and name it `Packets`.\
Make sure to [tag](https://create.roblox.com/docs/studio/properties#instance-tags) it `Packets` as well.

Then drag the `Packet` module (the networking library) inside of this new module.

The `Packets` module shall contain all of the packet definitions.\
It’s crucial that you include these exact packets in the module for Tween+ networking to function:

```luau
local Packet = require(script.Packet)

return {
	CreateTween = Packet(Packet.NumberU8, Packet.Instance, Packet.Any, Packet.Any),
	StartTween = Packet(Packet.NumberU8, Packet.Any, Packet.Any),
	StopTween = Packet(Packet.NumberU8),
	ResetTween = Packet(Packet.NumberU8),
	DestroyTween = Packet(Packet.NumberU8)
}
```

{% hint style="success" %}
You can of course add any additional packets at any time for your own use in your game!
{% endhint %}
