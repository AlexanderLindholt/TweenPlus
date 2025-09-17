# Let the client do it

The Roblox server is limited to 60 FPS, and sending large amounts of data every frame is expensive, as not all clients have the bandwidth to handle it efficiently. To address this, we can transfer the hard work to the client. But how do we ensure the client knows what to do?

The solution is to synchronize tween data between the server and client. Instead of sending the tween's output, the server only shares the internal tween parameters — such as those provided via an API like Tween+. Whenever the server creates, plays, resets, stops, or destroys a tween, it notifies the client with the necessary details.

While this method increases the client's workload, it also greatly reduces network traffic, and keeps tweens smooth for the players.

On Roblox unfortunately, due to the lack of ability to toggle the automatic replication, it's unoptimal to tween like usual on the server. Here's the workaround: we simply update the values only when a tween stops or reaches the start/finish. This way, the server stays in sync enough for most cases, while avoiding constant updates.
