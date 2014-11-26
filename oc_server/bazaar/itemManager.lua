
local component=require("component")
local se=require("serialization")
local modem = component.item_ccwiredmodem
local event=require("event")
local counter={VERSION="0.1dev"}
modem.open(1)
counter.getItems=function()
	if not modem.isOpen(1) then
		modem.open(1)
	end
	modem.transmit(0,1,"1")
	local r={event.pull(10,"modem_message")}
	if r[5] then
		return se.unserialize(r[5])
	end
end
counter.queryItems=function(items)
	if not modem.isOpen(1) then
		modem.open(1)
	end
	modem.transmit(0,1,"2:"..se.serialize(items))
	local r={event.pull(10,"modem_message")}
	if r[5] then
		return se.unserialize(r[5])
	end
end

return counter