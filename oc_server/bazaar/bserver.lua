package.loaded.database=nil
package.loaded.itemManager=nil

local im=require("itemManager")
local db=require("database")
local se=require("serialization")
local component=require("component")
local event=require("event")
--preset tables
local items=db.makeTable("items","items.db")
--local items=db.makeTable("accounts","accounts.db")
local orders=db.makeTable("orders","orders.db")
local itemPrototype={id=0,meta=0,count=0}
local orderPrototype={owner="",cost=0,items=itemPrototype}

local modem=component.modem

local usingTerm={}

local term =require("term")
local _print=print
function print(...)
	term.clearLine()
	_print(...)
	term.write("#bserver>")
end



local function tableIterator(tab)
	local i = 1
	return function() local t=tab[i] if t then i=i+1 return i-1,t end end
end

local function serializeByPrototype(tab,prot)
	local str=""
	--local size=tab.size
	local i=1
	while true do
		if tab[i]==nil then
			break
		end
		str=str.."{"
		for k,v in pairs(prot) do
			if type(v)=="table" then
				str=str..k.."={"..serializeByPrototype(tab[i][k],v).."},"
			else
				str=str..k.."="..se.serialize(tab[i][k])..","
			end
		end
		str=str.."},"
		i=i+1
	end
	return str
end

local function getLocalStorage(name)
	if not items[name] then
		return "E01"
	end
	local str=serializeByPrototype(items[name],itemPrototype)
	items:freeMemory()
	return "{"..str.."}"
end

local function getSellOrders()
	local t=orders.sell
	local str="{"..serializeByPrototype(t,orderPrototype).."}"
	orders:freeMemory()
	return str
end

local function getBuyOrders()
	local t=orders.buy
	local str="{"..serializeByPrototype(t,orderPrototype).."}"
	orders:freeMemory()
	return str
end

local function findItem(tab1,val)
	for k,v in pairs(tab1) do
		if val.id == v.id and val.meta==v.meta then 
			return v
		end
	end
end

local function sendAndWait(to,port,msg,tout)
	local closeAfter=false
	if not modem.isOpen(port) then
		modem.open(port)
		closeAfter=true
	end
	modem.send(to,port,msg)
	local _,_,from,port,_,message=event.pull(tout or 10,"modem_message",nil,to,port,nil)
	if closeAfter then modem.close(port) end
	return message
end


orders.buy={}
orders.sell={}

local terminals={"9472b26e-c2cb-4cc2-b484-99fee958acff"}

local taskStack={}

local tid=0

local rotTerm=""

local function itemRotor()
	
end

tid=event.timer(1,itemRotor,math.huge)

local function getFromLocalStorage(name,itemz,termId)
	event.cancel(tid)
	modem.send(rotTerm,1,"s:out:0")
	local t=items[name]
	if not t then
		return "E01"
	end
	for k,v in tableIterator(t) do
		local ind=findItem(itemz,v)
		if ind then
			if ind.count>v.count then
				return "E02"
			end
			ind.db=k
		end
	end
	for k,v in pairs(itemz) do
		if not v.db then
			return "E02"
		end
	end
	modem.broadcast(2,"s:inp:0")
	sendAndWait(termId,2,"s:inp:15")
	for k,stack in pairs(itemz) do
		if not im.queryItems(stack) then
			sendAndWait(termId,2,"s:inp:0")
			return "E03"
		else 
			t[stack.db].count=t[stack.db].count-stack.count
			if t[stack.db].count<=0 then
				t[stack.db]=nil
			end
		end
	end
	sendAndWait(termId,2,"s:inp:0")
	return "ok"
end



function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end




local function processMessagePort1(from,port,msg)
	local args=split(msg,":")
	
	local cases={
		gls=function(args) return getLocalStorage(usingTerm[from]) end,
		gso=getSellOrders,
		gbo=getBuyOrders,
		gfls=function(args) local res=getFromLocalStorage(usingTerm[from],se.unserialize(args[3]),from) tid=event.timer(1,itemRotor,math.huge) return res end,
		ss=function(args) usingTerm[from]=args[2] modem.send(from,1,"ok") end,
		es=function() usingTerm[from]=nil modem.send(from,1,"ok") end
	}
	return cases[args[1]](args)
	
end


modem.open(1)
event.listen("modem_message",function(_, _, from, port, _, message) 
	print("Got a message from " .. from .. " on port " .. port .. ": " .. tostring(message))
	local response=nil
	if port==1 then
		response=processMessagePort1(from,port,message)
	end
	if response then
		modem.send(from,port,response)
	end
end)

event.onError=function(msg) print(tostring(msg)) end

local shell = require("shell")
term.clear()
term.write("#bserver>")
local history={}
while true do
	local str=term.read(history)
	local res=shell.execute(str)
	if res then
		table.insert(history,str)
	else 
		print("wrong command!")
	end
end
--[[
print(getLocalStorage("semoro"))
print(getFromLocalStorage("semoro",{{id=256,count=5,meta=0}}))
print(getLocalStorage("semoro"))
]]

--[[
modem.open(1)
while true do
	local _, _, from, port, _, message = event.pull("modem_message")
	print("Got a message from " .. from .. " on port " .. port .. ": " .. tostring(message))
	local response=nil
	if port==1 then
		response=processMessagePort1(from,port,message)
	end
	if response then
		modem.send(from,port,response)
	end
end
]]