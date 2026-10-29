---
icon: head-side-gear
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

# How it works

Tween+ shows quite remarkable performance with global tweens in comparison to the built-in TweenService and alternative community-made libraries (as seen in the [DevForum post](https://devforum.roblox.com/t/3599638)).

Achieving this required fundamentally changing how it works. The major architectural difference being that clients run tweens locally, while the server only provides strictly necessary information, rather than overwhelming both ends with constant uncompressed updates. This allows players to enjoy uncapped framerates while the server never breaks a sweat.

Additionally, there are a plethora of lower-level details and optimizations that we will be talking about. But let’s break it all down, one by one, on the next few pages.
