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

# Compress the data

To optimize further, we have to understand how data is represented in computers.

Bits are essentially switches, which live in our computers, and are used to represent all data. A boolean for example, can be stored with just a single bit. For more complex data, we have to use more bits, where each combination of the bits represent different data. It’s important to note that bits are stored in groups of 8, called bytes — for this reason, we can’t go below 8 bits per data element, and we are also forced to use increments of 8 — for example, a boolean, despite being just a single bit, will end up taking up 8 bits (1 full byte).

If we look closer at the bits, we often find unnecessary ones. For example, by default in Luau (Roblox’s programming language), numbers are usually stored as Float64s. `Float` meaning it can contain decimals, and `64` meaning it uses 64 bits to store the number. Since there’s no `U` in front, that means it’s signed, meaning it can store negative values too. The issue is that we don’t need negative values, decimals and 64 whole bits just to store the number `1`, for example.

A Float64 includes an insane range of numbers all the way down to `-1.7976931348623157 x 10^308` and all the way up to `1.7976931348623157 x 10^308`, with up to about 16 decimal digits. In many cases, that’s overkill. Therefore, we can lower the amount of bits used to represent the data.

One example of this optimization principle, is the Tween+ server tween identifiers, which are intentionally limited to the range 0-255, because that’s the range of a UInt8 (unsigned 8-bit integer). This means a maximum of 256 server tweens at once, but also means reduced network traffic.

And compression isn’t limited to numbers — it can be all sorts of data!



But there’s specific data that’s often overlooked.

For example, every time we send something over the network, we also send the identifier for the event, so that the client knows which event we’re talking about — for example, we might have to inform the client that we’re firing the `StartTween` event — that’s what happens behind the scenes when you fire a RemoteEvent in Roblox. Therefore, it’s best to minimize the amount of event fires.

If we just send everything through the same event, we can just fire that one event no more than 1 time a frame by combining all of the data, allowing us to store the event identifiers how we want, which can result in slightly reduced network usage if multiple events fire in the same frame.



These optimizations were made possible with Packet, the networking library Tween+ utilizes.\
Of course it’s a lot more complex behind the scenes — but these are the main principles.
