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

# Let the client do it

The Roblox server is limited to 60 frames per second, and sending large amounts of data every frame is expensive, as not all clients have the bandwidth to handle it efficiently. To address this, we can transfer the hard work to the client.

But how do we ensure the client knows what to do? One solution is to synchronize tween data between the server and client. Instead of sending the tween’s output, the server only shares the internal tween parameters — such as those provided via an API like Tween+. Whenever the server creates, plays, resets, stops, or destroys a tween, it notifies the client with the necessary details.

Although there are a plethora of solutions, this one works well because it avoids sending the same data over and over again. And while this method increases the client’s workload, it also drastically reduces network traffic, and keeps tweens smooth for the players.

On Roblox unfortunately, due to the lack of ability to toggle the automatic replication, it’s unoptimal to tween like usual on the server. Here’s the workaround: we simply update the values only when a tween stops or reaches the start/finish. That way, the server stays in sync enough for most cases, while avoiding constant updates.
