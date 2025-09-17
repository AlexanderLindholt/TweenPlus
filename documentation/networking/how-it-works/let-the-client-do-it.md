# Let the client do it

The Roblox server is limited to 60 FPS, and sending large amounts of data every frame is expensive, as not all clients have the bandwidth to handle it efficiently. To address this, we can transfer the hard work to the client. But how do we ensure the client knows what to do?

The solution is to synchronize tween data between the server and client. Instead of sending the tween's output, the server only shares the internal tween parameters — such as those provided via an API like Tween+. Whenever the server creates, plays, resets, stops, or destroys a tween, it notifies the client with the necessary details.

This approach minimizes what server's workload, and helps achieve smooth tweens on all clients.

But the server still has to keep track of tween states to handle cases like players joining mid-tween. Additionally, server code might expect the tween output to match the client's. Instead of actually tweening on the server, we can update the relevant values only when a tween stops or reaches the start/finish. This way, the server stays in sync enough for most cases, while avoiding constant updates. Unfortunately it's not optimal to fully tween on the server due to Roblox's automatic replication — _if Roblox ever decides to allow you to toggle their automatic replication, or if you're working in a different engine that already allows for this, you can safely tween properly on the server_.

While this method increases the client's workload, it also greatly reduces server and network usage, and keeps tweens smooth for the players.
