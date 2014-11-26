
local function wrapPeripheral(tname)
	for k,v in pairs(peripheral.getNames()) do
		if string.match(peripheral.getType(v),tname) then
			print(tname.." found at "..v)
			return peripheral.wrap(v)
		end
	end
end
local eB=peripheral.wrap("bottom")
local bufE=peripheral.wrap("top")
items=eB.getAvailableItems()




function sortItems(items)
	local res={}
	for i=1,#items do
		local index=items[i].id..":"..items[i].dmg
		res[index]=items[i]
	end
	return res
end

function compareItems(i1,i2)
	local res={}
	for k,v in pairs(i2) do
		if i1[k] ~= nil then
			local c=v.qty-i1[k].qty
			if c>0 then
				res[k]=v
				res[k].qty=c
			end
		else 
			res[k]=v
		end
	end
	return res
end

function getI(bus)
	return sortItems(bus.getAvailableItems())
end

function itemsToStr(i)
	local str="{"
	for k,v in pairs(i) do
	  str=str.."[\""..k.."\"] = "..textutils.serialize(v)..","
	end
	str=str.."}"
	return str
end

function loadItems(ss)
	return textutils.unserialize(ss)
end

function extractItems(id,q,dir,bus)
	local stack=getI(bus)[id]
  if stack.qty < q then
    return false
  end
  while( q > 0 ) do
    print(q)
    stack.qty=q
    bus.extractItem(stack,dir)
    q=q-stack.maxSize
  end
  return true
end


local modem=wrapPeripheral("modem")

modem.open(0)
modem.open(1)


function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local direct="east"


local function readAndFlush()
	local items=bufE.getAvailableItems()
	for k,v in pairs(items) do
		for i=1,math.ceil(v.qty/v.maxSize) do
			print(textutils.serialize(v))
			bufE.extractItem(v,"west")
		end
	end
	return items
end
--[[
while(true) do
	local e={os.pullEvent("modem_message")}
	local args=split(e[5],":")
	print(e[5])
	if args[1]=="1" then
		modem.transmit(1,0,itemsToStr(getI(eB)))
	elseif args[1]=="2" then
		local it=loadItems(args[2])
		modem.transmit(1,0,tostring(extractItems(it.id..":"..it.meta,it.count,direct,eB)))
	end
end
]]
os.pullEvent("key")
print(textutils.serialize(readAndFlush()))