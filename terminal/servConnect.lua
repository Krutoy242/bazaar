-- ������ ������� ���������
local function getLocalStorage()
  
  return {}
end

local function getSellOrders()

  return {}
end

local function getBuyOrders()

  return {}
end

-- ������� ����������� ��������� ����� ��������������
-- queryArray = { {bunchID, count}, [...] }
-- bunchID - ������������� ����� ��������� � �������
-- count   - ���������� ��������� �� �����
-- player  - ��� ������, ���� ��������� ��������
local function transfer(queryArray, player)

  return errorString
end

-- ������� ������ �� ���������� ��������� � ������ ���������
local function issue(queryArray)
  
  return errorString
end

return {getLocalStorage=getLocalStorage, getSellOrders=getSellOrders, getBuyOrders=getBuyOrders,transfer=transfer,issue=issue}