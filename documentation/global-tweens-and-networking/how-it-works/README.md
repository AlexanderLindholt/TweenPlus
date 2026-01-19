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
---

# How it works

_How does Tween+ consistently outperform TweenService and other libraries by such a significant margin?_

It isn't magic — it’s a huge shift in how the Client-Server bridge is handled. Instead of overwhelming the network with constant property updates, Tween+ utilizes packed data payloads and distributed interpolation.

In plain English: Instead of sending the object’s position 60 times every second, it sends one compact instruction once. The clients then do the hard work of calculating the movement locally in sync.

Additionally, there are a plethora of lower-level optimizations that take the performance even further!

Let’s break down the engineering that makes this possible!
