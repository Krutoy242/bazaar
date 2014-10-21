
local component=require("component")
local se=require("serialization")
local modem = component.item_ccwiredmodem
local event=require("event")
local counter={VERSION="0.1dev"}
modem.open(1)
counter.getItems=function()
	modem.transmit(0,1,"1")
	local r={event.pull("modem_message")}
	return se.unserialize(r[5])
end

return counter