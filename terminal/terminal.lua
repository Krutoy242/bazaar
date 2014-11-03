-- ********************************************************************************** --
-- **                                                                              ** --
-- **   Базар                     Создатели: Krutoy, Totoro, Semoro                ** --
-- **                                                                              ** --
-- **   Специально для захвата сервера     http://computercraft.ru/                ** --
-- **                                                                              ** --
-- **   https://github.com/Krutoy242/bazaar                                        ** --
-- **                                                                              ** --
-- ********************************************************************************** --

--[[
 ,+---+
+---+'|
|^_^| +
+---+'
]]

--===========================================================
-- Globals
--===========================================================
package.loaded.gml=nil
package.loaded.gfxbuffer=nil
package.loaded.canvas=nil
package.loaded.servConnect=nil
package.loaded.bankConnect=nil

local gml      = require("gml")
local event    = require("event")
local component= require("component")
local canvas   = require("canvas")
local gfxbuffer   = require("gfxbuffer")
local servConnect = require("servConnect")
local bankConnect = require("bankConnect")

--===========================================================
-- Locals
--===========================================================
local currentUser = ""
local gpu = component.gpu


-- ********************************************************************************** --
-- **                                                                              ** --
-- **                                Utilities                                     ** --
-- **                                                                              ** --
-- ********************************************************************************** --

-- given a numeric value formats output with comma to separate thousands
-- and rounded to given decimal places
function format_num(amount, decimal, prefix, neg_prefix)
  local str_amount,  formatted, famount, remain

  decimal = decimal or 2  -- default 2 decimal places
  neg_prefix = neg_prefix or "-" -- default negative sign

  famount = math.abs(round(amount,decimal))
  famount = math.floor(famount)

  remain = round(math.abs(amount) - famount, decimal)

  -- comma to separate the thousands
  formatted = comma_value(famount)

  -- attach the decimal portion
  if (decimal > 0) then
    remain = string.sub(tostring(remain),3)
    formatted = formatted .. "." .. remain ..
                string.rep("0", decimal - string.len(remain))
  end

  -- attach prefix string e.g '$' 
  formatted = (prefix or "") .. formatted 

  -- if value is negative then format accordingly
  if (amount<0) then
    if (neg_prefix=="()") then
      formatted = "("..formatted ..")"
    else
      formatted = neg_prefix .. formatted 
    end
  end

  return formatted
end

-- Repeat string many as need times to make string
local function strMul(str, count)
  local returnString = ''
  for _=0, count-1 do
    returnString = returnString..str
  end
  return returnString
end

-- Выдает обработанное число денег
local function getAirCount()
  local rawAirCount = bankConnect.getAirCount("player")
  return format_num(rawAirCount)
end

-- Находится ли точка в квадрате
local function isInRect(x,y,u,v,w,h)
  return 
end

-- ********************************************************************************** --
-- **                                                                              ** --
-- **                                UI                                            ** --
-- **                                                                              ** --
-- ********************************************************************************** --

--======================================================
-- Класс таблицы
--======================================================
OffsettedList = {}
OffsettedList.__index = OffsettedList

function OffsettedList.new(x,y,w,h)
  local self = setmetatable({}, OffsettedList)
  x = x or 0
  y = y or 0
  w = w or 0
  h = h or 0
  self.x = x
  self.y = y
  self.w = w
  self.h = h
  self.lines = {}
  self.offset = 0
  self.hat = ""
  return self
end

function OffsettedList:Draw(x,y)
  x = x or self.x
  y = y or self.y
  gpu.set(x,y,self.hat)
  for i=self.offset+1;#self.lines do
    gpu.set(x,y+i,self.lines[i])
  end
end

function OffsettedList:SetLines(ln)
  self.lines = ln
  
end

function OffsettedList:SetPos(x,y)
  self.x = x
  self.y = y
  self:Draw()
end

function OffsettedList:SetOffset(n)
  self.offset = n
  self:Draw()
end


--======================================================
-- Режим ожидания
--======================================================
local idlW, idlH = 20, 9

local mobs = {"Spider", "Zombie", "Creeper", "Skeleton", "Enderman", "Sheep", "Cow", "Chicken", "Bat"}
local function isMob(name)
  for i=1, #mobs do
    if name == mobs[i] then return true end
  end
  return false
end

local function waitUser()
  gpu.setResolution(idlW, idlH)
  gpu.set(1,1,"ЖДЕМ")
  
  -- while true do
    -- local evt,_,_,mx,my,mz,name = event.pull()
    -- if evt == "motion"then
      -- if not isMob(name) then
        -- if math.sqrt(mx*mx + my*my + mz*mz) > 3.0 then
          
        -- else
          -- if currentUser ~= name then
            -- currentUser = name
            -- main_wnd:run()
          -- end
        -- end
      -- end
    -- end
  -- end
end

local function sensorListener(_,_,mx,my,mz,name)
  if not isMob(name) then
    if math.sqrt(mx*mx + my*my + mz*mz) > 3.0 then
      showIdle()
    else
      if currentUser ~= name then
        currentUser = name
        main_wnd:run()
      end
    end
  end
end
event.listen("motion", sensorListener)

--======================================================
-- Главное меню
--======================================================


local uiW, uiH = 90, 40   -- Ширина всего интерфейса


local searchInputLen = 12 
local sellProportion = 0.7
local sellersLength  = math.ceil((uiH-14)*   sellProportion)
local buyersLength   = math.floor((uiH-14)*(1-sellProportion))
local main_wnd       = gml.create(1,1,uiW,uiH)
local sellOrders, buyOrders -- Сырые таблицы, полученные с сервера

main_wnd.style = gml.loadStyle("style")

-- Расчет всех позиций элементов
local posArr = {}
posArr["sell"]    = {x:1,y:7}
posArr["sellEnd"] = {x:1,y:posArr["sell"].y   +1+sellersLength}
posArr["buy"]     = {x:1,y:posArr["sellEnd"].y+4}
posArr["buyEnd"]  = {x:1,y:posArr["buy"].y    +1+buyersLength }

-- Создание элементов на основе расчета
local sellSheet = OffsettedList.new(posArr["sell"].x, posArr["sell"].y, uiW-3, sellersLength)
local buySheet  = OffsettedList.new(posArr["buy"].x,  posArr["buy"].y , uiW-3, buyersLength)
local airCount = main_wnd:addLabel(10,2,30, "*загружается*"); airCount["text-color"] = 0x22ff12
local searchInput = main_wnd:addTextField(uiW-searchInputLen-1,4,searchInputLen)
local barSell = main_wnd:addScrollBarV(uiW-1,sellSheet.y+1,sellersLength,sellersLength,
 function() sellSheet:SetOffset(barSell.scrollPos) end)
local barBuy  = main_wnd:addScrollBarV(uiW-1,buySheet.y +1, buyersLength, buyersLength,
 function() sellSheet:SetOffset( barBuy.scrollPos) end)

 
-- Рисует фон главного меню
local function drawBackground()
  local ln -- Текущая рабочая строка
  ln= 1; gpu.set (1,ln,"║ БАЗАР ║")
 
  ln=ln+2; gpu.set (1,ln,"Воздуха: ")
  ln=ln+1; gpu.fill(1,ln,uiW,1, "─")
  ln=ln+1; gpu.set(1,ln,"╔ Продается ╗"); gpu.set(uiW-14-searchInputLen,ln,"[Поиск по ID:"); gpu.set(uiW,ln, "]")
  ln=ln+1; gpu.set(1,ln,"╠═══════════╩"); gpu.fill(14,ln,uiW,1, "═"); gpu.set(uiW,ln, "╗")

  ln=posArr["sellEnd"].y
  gpu.set(1,ln,"╚"); gpu.fill(1,ln,uiW,1, "═"); gpu.set(uiW,ln, "╝")
  ln=ln+1;
  ln=ln+1; gpu.set(1,ln,"╔ Покупается ╗")
  ln=ln+1; gpu.set(1,ln,"╠════════════╩");gpu.fill(15,ln,uiW,1, "═"); gpu.set(uiW,ln, "╗")
  ln=ln+1;
  
  ln=posArr["buyEnd"].y
  gpu.set(1,ln,"╚"); gpu.fill(1,ln,uiW,1, "═"); gpu.set(uiW,ln, "╝")
end

-- При запуске главного окна
main_wnd.onRun = function()
  gpu.setResolution(uiW, uiH)
  drawBackground()
end

-- Какой то обработчик, без которого не воркает
main_wnd:addHandler("key_down",
  function(event,addy,char,key)
  
  end)
  
local function onSellerClick(n)

  local index = sellersList:getSelected()
  
  local buyedCunt = buyDialog(1, 299.99, 100)
  local total = buyedCunt*100
  
  
  -- TODO: Снятие денег
  -- TODO: Обновление денег
  -- TODO: Обновление товара
  
  updateMainMenu()

end
  
main_wnd:addHandler("touch",
  function(screenAddress, x, y, button, playerName)
    if isInRect(x,y,sellSheet.x,sellSheet.y,sellSheet.w,sellSheet.h) then
      onSellerClick(y - sellSheet.y + sellSheet.offset + 1)
    end
end)

--======================================================

-- Константы
local fieldNames = {"id","count","price","player"}
local tblNames   = {"ID","Количество","Цена","Игрок"}
local tblParts   = {4, 5, 5, 6}

-- Просчитать ширину частей таблицы
local tblPartsLen=0; for _,v in pairs(tblParts) do tblPartsLen = tblPartsLen+v end
local tblActiveField = uiW - 3 - (#tblParts + 1)
local tblMult = tblActiveField/tblPartsLen
for k,v in pairs(tblParts) do tblParts[k] = math.floor(v*tblMult) end
local tblTail=0
for _,v in pairs(tblParts) do tblTail = tblTail+v end
tblTail = tblActiveField - tblTail
tblParts[#tblParts] = tblParts[#tblParts] + tblTail

-- Сформировать первую строку заголовка
local tblHat = "║"
for k,v in pairs(tblNames) do
  local lSpace, rSpace = math.ceil ((tblParts[k]-#v)/2), math.floor((tblParts[k]-#v)/2))
  tblHat = tblHat .. strMul(" ",lSpace) .. v .. strMul(" ", rSpace) .. "|"
end
tblHat = tblHat .. "║"
sellSheet.hat = tblHat
buySheet.hat  = tblHat


local function updateMainMenu()
  airCount.text = getAirCount()..""
  
  -- Продаем
  sellOrders = servConnect.getSellOrders()
  sellSheet.lines = parseRawOrders(sellOrders)
  sellSheet:Draw()

  -- Покупаем
  buyOrders = servConnect.getBuyOrders()
  buySheet.lines = parseRawOrders(buyOrders)
  buySheet:Draw()
  
  main_wnd:draw()
end

-- Парсит полученную таблицу для создания массива строк
local function parseRawOrders(source, x,y, maxLineCount)
  local tableString = {tblHat}
  local lineCount = 0
  for k,v in pairs(source) do
    local line = "║"
    for m,n in pairs(fieldNames) do
      local val = v[n] .."" -- значение ячейки
      val = string.sub(val, 1, tblParts[m]) -- Обрезать по длинне
      local space = tblParts[m] - #val
      line = line .. strMul(" ",space) .. val .. " "
    end
    
    table.insert(tableString, line)
    
    lineCount = lineCount + 1
    if lineCount >= maxLineCount then break end
  end
  
  return tableString
end


--======================================================
-- Диалог покупок
--======================================================
local buyW, buyH = 40, 10
local buy_wnd = gml.create("center", "center", buyW, buyH)
buy_wnd.style = main_wnd.style
buy_wnd.class = "dialog"

local buy_id    = buy_wnd:addLabel    (10,1,buyW-10, "0")
local buy_price = buy_wnd:addLabel    (10,2,buyW-10, "0")
local buy_count = buy_wnd:addTextField(10,3,buyW-10)
local buy_total = buy_wnd:addLabel    (10,5,buyW-10, "0")
buy_total["text-color"] = 0xff1122

local buy_no = buy_wnd:addButton(buyW-22,"bottom",10,1,"ОТМЕНА",toggleLabel)
local buy_ok = buy_wnd:addButton("right","bottom",10,1,"КУПИТЬ",toggleLabel)

local function buy_drawBackground()
  gpu.set(buy_wnd.posX+1,buy_wnd.posY+1,"ID")
  gpu.set(buy_wnd.posX+1,buy_wnd.posY+2,"Цена:")
  gpu.set(buy_wnd.posX+1,buy_wnd.posY+3,"Кол-во:")
  gpu.set(buy_wnd.posX+1,buy_wnd.posY+5,"Всего:")
end
buy_wnd.onRun = function() buy_drawBackground() end

-- Показывает диалог и возвращает количество купленных предметов
local function buyDialog(id, price, count)
  local newCount = count
  local total = price*newCount
  
  buy_id.text    = id   ..""
  buy_price.text = parseCommas(price)
  buy_count.text = count..""
  buy_total.text = total .. ""
  
  -- Пользователь что то пишет. Сразу считать сумму
  main_wnd:addHandler("key_down", function(event,addy,char,key)
    newCount = tonumber(buy_count.text)
    numCount = ((umCount > count) and count or numCount)
    total = price*newCount
    buy_total.text = format_num(total)
    buy_total:draw()
  end)
  
  buy_no.onClick = function()
    buy_wnd.close()
    return 0
  end
  buy_no.onClick = function()
    buy_wnd.close()
    return newCount
  end
  
  buy_wnd:run()
  
  return 0
end

--======================================================
-- Главное
--======================================================

-- Временная функция
airCount.onClick = function()
  main_wnd.close()
end

waitUser()
