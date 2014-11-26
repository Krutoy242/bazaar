
local fs=require("filesystem")

local db={VERSION="1.0_a"}
db.tables={}
db.__debug=false

local _print=print
local function print(...)
	if db.__debug then
		_print(...)
	end
end



local ser=require("serialization")
local _resolve=require("shell").resolve
local fMem=require("computer").freeMemory

----------------------УТИЛИТЫ
function findfromback(arg,w)
	for n = 1,#arg do
		local a=#arg-n
		if string.sub (arg, a,a+#w-1)==w then
			return a
		end
	end
	return false
end

local function resolve(path)
	local p=findfromback(path,".")
	local pt=path
	local ext
	if p then
		ext=string.sub(pt,p+1)
		pt=string.sub(pt,1,p-1)
	end
	return _resolve(pt,ext)
end


local function nilify(tab)
	for k,v in pairs(tab) do
		if type(v)=="table" then
			nilify(v)
		end
		v=nil
	end
end

local function contains(tab,val)
	for k,v in pairs(tab) do
		if v==val then return true end
	end
	return false
end

local function getFromTable(tab,index)
	local pos=string.find(index,".",1,true)
	if not pos then
		return tab[index]
	else
		local key=string.sub(index,1,pos-1)
		return getFromTable(tab[key],string.sub(index,pos+1))
	end
end

local function getKeyFromStr( line)
	if line == nil then
		return
	end
	local p=string.find(line,"=")	
	return string.sub(line,1,p-1)
end

local function gkkey(gkey , key)
	return gkey.."."..key
end


-----------------------------Мета таблицы
local function makeIndexer(gkey,tab,res)
	local t={}
	local wF,rF= res.writer,res.reader
	local mt={__tab={}}
	local vals=mt.__tab
	mt.__index=function(self,key)
		local v=vals[key] 
		if v==nil then
			v=rF(gkkey(gkey,key))
			vals[key]=v
		end
		return v
	end
	mt.__newindex=function(self,key,val)
		if t[key]~=val then
			if type(val)=="table" then
				val=makeIndexer(gkkey(gkey,key),val,res)
			end
			wF(gkkey(gkey,key),val,type(val)=="table" and type(t[key])=="table")
			vals[key]=val
		end
	end
	
	t=setmetatable(t,mt)
	for k,v in pairs(tab) do
		t[k]=tab[k]
	end
	return t
end

-----------------------Генератор ввода вывода
local function databaseIO(file)
	local path=resolve(file)
	local res={wf=io.open(file,"a"),__tc=false,__todump={}}
	res.writer=function(key,val,rm)
				if rm then return end
				if res.__tc then
					res.__todump[key]=ser.serialize(val)
				else
					print("Writting data to "..key)
					res.wf:write(key.."="..ser.serialize(val).."\n")
					res.wf:flush()
				end
	end
	res.reader=function(key)
				local addr=key
				print("Getting key "..addr)
				local r=io.open(file,"r")
				local val=nil
				while true do
					local line=r:read()
					if not line then 
						break
					end
					local p=string.find(line,"=")
					if p and string.sub(line,1,p-1) == addr then
						val=ser.unserialize(string.sub(line,p+1))
					end
				end
				if type(val)=="table" then
					val=makeIndexer(addr,{},res)
				end
				print("Result - "..type(val))
				r:close()
				return val
	end
	res.keyloader=function(key)
		local addr=key
		print("Getting key "..addr)
		local r=io.open(file,"r")
		local vals={}
		while true do
			local line=r:read()
			if not line then 
				break
			end
			local p=string.find(line,"=")
			if p and string.find(line,addr)==1 then
				vals[string.sub(line,1,p-1)]=ser.unserialize(string.sub(line,p+1))
			end
		end
		
		if type(val)=="table" then
			vals=makeIndexer(addr,{},res)
		end
		print("Result - "..type(val))
		r:close()
	end
	return res
end

-------------------------Встраиваемые функции
local function cleanupHistory(self)
	self:setTimeCritical(false)
	local meta=getmetatable(self)
	meta.__io.wf:close()
	nilify(meta.__tab)
	local data={}
	local rfile=io.open(meta.__file,"r")
	while true do
		local line=rfile:read()
		if not line then break end 
		local p=string.find(line,"=")
		if p then
			data[string.sub(line,1,p-1)]=string.sub(line,p+1)
		end
	end
	rfile:close()
	local wfile=io.open(meta.__file,"w")
	for k,v in pairs(data) do
			wfile:write(k.."="..v.."\n")
	end
	wfile:close()
	meta.__io.wf=io.open(meta.__file,"a")
end

local function unloadTable(self)
	self:setTimeCritical(false)
	local meta=getmetatable(self)
	nilify(meta.__tab)
	meta.__io.wf:close()
	meta.__io.wf=io.open(meta.__file,"a")
end

local function setTimeCritical(self,isTC)
	local meta=getmetatable(self)
	
	if meta.__io.__tc and not isTC then
		local todump=meta.__io.__todump
		local f=meta.__io.wf
		for k,v in pairs(todump) do
			f:write(k.."="..v.."\n")
		end
		f:flush()
	end
	meta.__io.__tc=isTC
end

-----------------Экспорты библиотеки

db.makeTable=function(name,file)--Создать или получить таблицу с именем name и расположением file, возвращает таблицу
	local l =databaseIO(file)
	db.tables[name]=makeIndexer(name,{},l)
	local meta=getmetatable(db.tables[name])
	meta.__file=file
	meta.__io=l
	meta.__tab.cleanupHistory=cleanupHistory
	meta.__tab.freeMemory=unloadTable
	meta.__tab.setTimeCritical=setTimeCritical
	db.tables[name]=setmetatable(db.tables[name],meta)
	return db.tables[name]
end



db.cleanupHistory=function(name)--Очистить историю операций БД для таблицы name
	db.tables[name]:cleanupHistory()
end

db.unloadTable=function(name)--Выгрузить таблицу name из памяти
	db.tables[name]:freeMemory()
end

db.setTimeCritical=function(name,st)--Переключить таблицу name в режим критичный для времени(Запись на диск производится после его выключения st = false)
	db.tables[name]:setTimeCritical(st)
end

return db
