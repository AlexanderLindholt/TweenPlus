local Packet = require(script.PacketPlus)

return {
	CreateTween = Packet(Packet.NumberU8, Packet.Instance, Packet.Any, Packet.Any),
	StartTween = Packet(Packet.NumberU8, Packet.Any, Packet.Any),
	StopTween = Packet(Packet.NumberU8),
	ResetTween = Packet(Packet.NumberU8),
	DestroyTween = Packet(Packet.NumberU8)
}