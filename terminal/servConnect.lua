-- Запрос таблицы предметов
local function getLocalStorage()
  
  return {}
end

local function getSellOrders()

  return {}
end

local function getBuyOrders()

  return {}
end

-- Команда перемещения предметов между пользователями
-- queryArray = { {bunchID, count}, [...] }
-- bunchID - идентификатор кучки предметов в таблице
-- count   - количество предметов из кучки
-- player  - ник игрока, КОМУ переходят предметы
local function transfer(queryArray, player)

  return errorString
end

-- Команда выдачи из локального хранилища в сундук терминала
local function issue(queryArray)
  
  return errorString
end

return {getLocalStorage=getLocalStorage, getSellOrders=getSellOrders, getBuyOrders=getBuyOrders,transfer=transfer,issue=issue}