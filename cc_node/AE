eB=peripheral.wrap("right")
items=eB.getAvailableItems()


function extractItems(stack,q,dir)
  if stack.qty < q then
    return false
  end
  while( q > 0 ) do
    print(q)
    stack.qty=q
    eB.extractItem(stack,dir)
    q=q-stack.maxSize
  end
  return true
end

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

function getI()
	return sortItems(eB.getAvailableItems())
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

local modem=peripheral.wrap("top")

while(true) do
	local e={os.pullEvent("modem_message")}
	if e[5]=="1" then
		modem.transmit(1,0,itemsToStr(getI()))
	end
end
