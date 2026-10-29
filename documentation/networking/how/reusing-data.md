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

# Reusing data

Sometimes we can avoid sending certain data, as we may use other data to calculate it locally.<br>

For example, when a player joins mid-tween, we want to inform them of how many repetitions we’ve done already. If reverse is enabled, you might think we should also inform the client of whether or not we’re going in reverse at the moment. But we can actually utilize some simple math in this case:

Since we already have the repetition count, we can use that to calculate the direction we’re moving in. It’s merely a simple check to see if the repetition count is odd or even – if it’s odd, we’re going in reverse, otherwise we’re not.<br>

This is made possible by the sheer speed of modern processors compared to networks. Running even complex math locally is thousands of times faster than sending a single byte of data over the network. That’s exactly why we want to reduce network traffic as much as possible.

This simple principle of re-using data can be applied in many other cases as well. Small optimizations like these add up, and can together result in significantly smaller packets.

