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

# Client-side prediction

The Roblox server is limited to 60 frames per second, and sending large amounts of data every frame is incredibly expensive.

Fortunately, there’s a solution: We can transfer the hard work to the client.

Specifically, we synchronize the tween parameters between the server and client, rather than sending the actual tween output. Whenever the server creates, plays, resets, stops, or destroys a tween, it notifies the client with the necessary details required to execute it locally. We also make sure to handle players joining in the middle of a tween, sending the progress details to let them catch up and see the same thing.

On Roblox unfortunately, due to the lack of ability to toggle the built-in automatic replication, it’s incredibly inefficient to tween like usual on the server, where you update every frame. As a compromise we can simply update the values only when a tween stops or reaches the start/finish. That way, the server stays in sync enough for most cases, while avoiding the constant, expensive updates that Roblox’s forced built-in replication yields.

