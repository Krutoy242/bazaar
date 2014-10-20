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

local gml      = require("gml")
local component= require("component")
local canvas   = require("canvas")
local gfxbuffer   = require("gfxbuffer")
local servConnect = require("servConnect")


-- ********************************************************************************** --
-- **                                                                              ** --
-- **                                Utilities                                     ** --
-- **                                                                              ** --
-- ********************************************************************************** --

-- Получает информацию из банка
local function pollBank(query, playerName)
  --TODO: Работа с сервером воздуха
  
  if(query == "bill") then
    return math.random()*1000000000.01
  end
  
  return nil
end

-- Добавляет запятые к большим числам
local function parseCommas(num)
  --TODO: Правильно парсить цифры
  local n, m = math.modf(num)
  local str  = "."..math.floor(m*100)
  if m==0 then str=str.."0"
  
  if n> 0 then 
    str = n%1000 .. str
    n = math.floor(n/1000)
  else
    str = "0"..str
  end
  
  while n>=1 do
    str = n%1000 ..",".. str
    n = math.floor(n/1000)
  end
 
  return str
end

-- Выдает обработанное число денег
local function getAirCount()
  local rawAirCount = pollBank("bill", "PlayerName")
  return parseCommas(rawAirCount)
end

-- ********************************************************************************** --
-- **                                                                              ** --
-- **                                UI                                            ** --
-- **                                                                              ** --
-- ********************************************************************************** --


--===========================
-- Главное меню
--===========================
local uiW, uiH = 90, 40
local searchInputLen = 12
local sellProportion = 0.7
local sellersLength  = math.ceil((uiH-14)*   sellProportion)
local buyersLength   = math.floor((uiH-14)*(1-sellProportion))
local gpu = component.gpu
local gui=gml.create(1,1,uiW,uiH)
gpu.setResolution(uiW, uiH)
gui.style = gml.loadStyle("ui_styles")


local function drawBackground()
  local ln -- Текущая рабочая строка
  ln= 1; gpu.set (1,ln,"║ БАЗАР ║")
 
  ln=ln+2; gpu.set (1,ln,"Воздуха: ")
  ln=ln+1; gpu.fill(1,ln,uiW,1, "─")
  ln=ln+1; gpu.set(1,ln,"╔ Продается ╗"); gpu.set(uiW-14-searchInputLen,ln,"[Поиск по ID:"); gpu.set(uiW,ln, "]")
  ln=ln+1; gpu.set(1,ln,"╠═══════════╩"); gpu.fill(14,ln,uiW,1, "═"); gpu.set(uiW,ln, "╗")
  ln=ln+1; gpu.set(1,ln,"║     ID     | Количество |       Цена       |       Игрок       ║")

  ln=ln+1+sellersLength
  gpu.set(1,ln,"╚"); gpu.fill(1,ln,uiW,1, "═"); gpu.set(uiW,ln, "╝")
  ln=ln+1;
  ln=ln+1; gpu.set(1,ln,"╔ Покупается ╗")
  ln=ln+1; gpu.set(1,ln,"╠════════════╩");gpu.fill(15,ln,uiW,1, "═"); gpu.set(uiW,ln, "╗")
  ln=ln+1; gpu.set(1,ln,"║     ID     | Количество |       Цена       |       Игрок       ║")
  
  ln=ln+1+buyersLength
  gpu.set(1,ln,"╚"); gpu.fill(1,ln,uiW,1, "═"); gpu.set(uiW,ln, "╝")
end
gui.onRun = function() drawBackground() end




local ln -- Текущая рабочая строка

-- Информация по воздуху
ln= 2; local airCount = gui:addLabel(10,ln,30, getAirCount() .. "")
airCount["text-color"] = 0x22ff12

-- Поиск
ln= 4; local searchInput = gui:addTextField(uiW-searchInputLen-1,ln,searchInputLen)

-- Список продаж
local sellOrders = servConnect.getSellOrders()
local parsedTable = {}
for k,v in pairs(sellOrders) do
  table.insert(parsedTable, "["..k .. "] -  " .. v.qty)
end
ln= 7; local sellersList=gui:addListBox(1,ln,uiW-1,sellersLength,parsedTable)

-- Список покупок
local buyOrders = servConnect.getBuyOrders()
parsedTable = {}
for k,v in pairs(buyOrders) do
  table.insert(parsedTable, "["..k .. "] -  " .. v.qty)
end
ln= 9+sellersLength+3
local buyersList=gui:addListBox(1,ln,uiW-1,buyersLength,parsedTable)

--===========================
-- Диалог покупок
--===========================
local buyW, buyH = 30, 12
local buy_wnd = gml.create("center", "center", buyW, buyH)
buy_wnd.style = gui.style
buy_wnd.class = "dialog"

local buy_id    = buy_wnd:addLabel    (10,1,buyW-10, "0")
local buy_price = buy_wnd:addLabel    (10,2,buyW-10, "0")
local buy_count = buy_wnd:addTextField(10,3,buyW-10)
local buy_total = buy_wnd:addLabel    (10,5,buyW-10, "0")
buy_total["text-color"] = 0xff1122

local buy_no = buy_wnd:addButton(buyW-16,"bottom",10,1,"ОТМЕНА",toggleLabel)
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
  buy_count:addHandler("key_down", function(event,addy,char,key)
    newCount = tonumber(buy_count.text)
    numCount = ((umCount > count) ? count : numCount)
    total = price*newCount
    buy_total.text = parseCommas(total)
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

-- Нажали - купили
sellersList.onClick = function()
  local index = sellersList:getSelected()
  
  local buyedCunt = buyDialog(1, 299.99, 100)
  local total = buyedCunt*100
  
  -- TODO: Снятие денег
  -- TODO: Обновление денег
  -- TODO: Обновление товара
  
  
end

airCount.onClick = function()
  gui.close()
end

gui:run()
