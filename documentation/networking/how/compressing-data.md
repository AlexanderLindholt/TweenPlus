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
  tags:
    visible: true
  actions:
    visible: true
  anchors:
    visible: true
---

# Compressing data

To optimize further, we have to understand how data is represented in computers.<br>

Bits are essentially switches inside computers used to represent all data. A boolean, for example, can be stored with just a single bit, as it is by definition just an on/off switch. For more complex data, we have to use more bits, where each combination of bits represents a different value. Computers allocate memory in groups of 8 bits, called bytes. Because of this, a standalone boolean ends up occupying a full 8-bit byte of memory. However, when sending data over the network, we can use bit-packing to squeeze multiple pieces of data together across bytes to maximize efficiency.​

If we look closer at standard network payloads, we often find unnecessary bits. By default in Luau, numbers are stored as `Float64`s – meaning they contain decimals, use 64 bits of data, and are signed (they can store negative values). The issue is that we don't need negative values, decimals, or 64 whole bits just to store a number like 1.

A `Float64` includes a massive range of numbers from $$-1.79 \times 10^{308}$$ all the way up to $$1.79 \times 10^{308}$$, with up to 16 digits of decimal precision. In many cases, that’s extreme overkill. Therefore, we can drastically lower the amount of bits used to represent our data.

One example of this optimization in Tween+ is our global tween identifiers. They are intentionally limited to a range of 0–255 because that fits perfectly into a `UInt8` (an unsigned 8-bit integer). While this caps the maximum number of active global tweens at 256 at any given moment, it saves us a. Keep in mind that this type of compression isn't limited to numbers or tweens – it can be applied to all sorts of data in many different contexts!<br>

But in game networking, there is specific data that is often overlooked.

Every time we send something over the network, we have to send an identifier for the remote event so the client knows exactly which event is being triggered – for example, informing the client we're firing a `StartTween` event. This is exactly what happens behind the scenes when you fire a `RemoteEvent` in Roblox.

Instead of firing separate remotes, we can funnel everything through a single event. By batching all of our data together, we can fire that single event no more than once per frame. This allows us to pack and structure event identifiers however we want, and send packets in groups, saving us a ton when multiple events fire in the same frame.<br>

Those are the main principles behind the networking library Packet, which Tween+ relies on for its global tween capabilities – even if it’s a bit more complex behind the scenes.
