--just hrere to force reloading the api so I don't have to reboot
package.loaded.gml=nil
package.loaded.gfxbuffer=nil
package.loaded.canvas=nil
package.loaded.servConnect=nil

local gml      = require("gml")
local component= require("component")
local canvas   = require("canvas")
local gfxbuffer   = require("gfxbuffer")
local servConnect = require("servConnect")


--------------------------------------------------
-- Утилиты
--------------------------------------------------

-- Запрос хранилища
local function pollStorage(query)
  --TODO: Опрос хранилища
  
  if(query.name == "list") then
    --local returnValue = cntr.getItems()
    --return returnValue
    return {["blabla"]={qty=100},["ololol"]={qty=12200}}
  elseif(query.name == "issue") then
    return true
  end
  
  return nil
end

-- Получает информацию из банка
local function pollBank(query, playerName)
  --TODO: Работа с сервером воздуха
  
  if(query == "bill") then
    return 1000000.01
  end
  
  return nil
end

-- 
local function parseCommas(n)
  --TODO: Правильно парсить цифры
  return n
end

-- Выдает обработанное число денег
local function getAirCount()
  local rawAirCount = pollBank("bill", "PlayerName")
  return parseCommas(rawAirCount)
end

--------------------------------------------------
-- Гуи
--------------------------------------------------

local uiW, uiH = 90, 40
local searchInputLen = 12
local sellProportion = 0.7
local sellersLength  = math.ceil((uiH-14)*   sellProportion)
local buyersLength   = math.floor((uiH-14)*(1-sellProportion))
local gpu = component.gpu

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

gpu.setResolution(uiW, uiH)

local gui=gml.create(1,1,uiW,uiH)
gui.style = gml.loadStyle("ui_styles")

--===========================
-- Главное меню
--===========================

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


--===========================
-- Действия
--===========================

-- Нажали - купили
sellersList.onClick = function()
  local index = sellersList:getSelected()
  
  local answer = pollStorage({name="issue", id=1, count=12})
  if answer ~= true then
    --TODO: Ошибка
  end
end

airCount.onClick = function()
  gui.close()
end

gui.onRun = function() drawBackground() end
gui:run()
