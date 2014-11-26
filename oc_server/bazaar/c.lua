local f=io.open("components.list","w")
local component=require("component")

for k,v in component.list() do
	f:write(k.." "..v.."\n")
end
f:close()