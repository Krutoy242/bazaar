package.loaded.database=nil
local db=require("database")

local t=db.makeTable("TEST","t.f")


t.tb={k="nos",kjf=1}
t.ko=3113113
t.str="String"

t:setTimeCritical(true)

for i=1,10000 do
 t.number=i
end

t:setTimeCritical(false)
--db.cleanupHistory("TEST")