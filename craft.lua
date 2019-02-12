local r = require("robot")
local component = require("component")
local sides = require("sides")
local crafting = component.crafting
local inventory_controller = component.inventory_controller
local filesys = component.filesystem

function craftItem()
	r.select(4)
	r.drop()
	crafting.craft()
	r.drop()
end

function split(s, delimiter)
    result = {}
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

function craft(items, count)
	numOfRepeats = 1
	saveCount = count
	while (count > 64) do
		count = count - 64
		numOfRepeats = numOfRepeats + 1
	end
	numOfSlots = inventory_controller.getInventorySize(sides.front)
	wasTaken = false
	wasPassed = false
	hasError = false
	while (numOfRepeats ~= 0) do
		if(wasPassed == true and wasTaken == true) then
			craftItem()
			count = 64
		end
		for i = 1, #items, 1 do
			wasTaken = false
			slot = i
			if(items[slot] ~= "none") then
				itemLabel = items[slot]
				if(slot >= 4 and slot < 7) then
					slot = slot + 1
				elseif (slot >= 7) then
					slot = slot + 2
				end
				r.select(slot)
				for chestSlot = 1, numOfSlots, 1 do
					if(inventory_controller.getStackInSlot(sides.front, chestSlot) ~= nil) then
						if(itemLabel == inventory_controller.getStackInSlot(sides.front, chestSlot).label) then
							inventory_controller.suckFromSlot(sides.front, chestSlot, count)
							wasTaken = true
							itemCount = r.count()
							while(itemCount < count) do
								wasTaken = false
								misCount =  count - r.count()
								for chestSlot_2 = 1, numOfSlots, 1 do
									if(inventory_controller.getStackInSlot(sides.front, chestSlot_2) ~= nil) then
										if(itemLabel == inventory_controller.getStackInSlot(sides.front, chestSlot_2).label) then
											inventory_controller.suckFromSlot(sides.front, chestSlot_2, misCount)
											itemCount = r.count()
											wasTaken = true
											break
										end
									end
								end
							end
							break
						end
					end
				end
				if(wasTaken == false) then
					print("В сундуке нет или недостаточно\n необходимых компонентов!")
					for i = 1, 16, 1 do
						r.select(i)
						r.drop()
					end
					hasError = true
					break
				end
			end
		end
		numOfRepeats = numOfRepeats - 1
		wasPassed = true
	end
	if(hasError == false) then 
		craftItem()
		print("Создание завершено!")
	end
end

function recordCraft(list, name)
	list:close()
	list = io.open("/home/ListOfCrafts", "a")
	list:write(name.."\n")
	list:flush()
		for i = 1, 11, 1 do
			slot = i
			if(slot == 4) then
				slot = 5
			elseif (slot == 8) then
				slot = 9
			else
				r.select(slot)
				item = nil
				if(inventory_controller.getStackInInternalSlot() ~= nil) then
					item = inventory_controller.getStackInInternalSlot().label
				else
					item = "none"
				end
				if(slot ~= 11) then
					list:write(item..",")
				else 
					list:write(item.."\n")
				end
				list:flush()
			end
		end
		list:write("\n")
		list:flush()
end

confirm = true
while (confirm) do
	if(inventory_controller.getInventorySize(sides.front) == nil) then
		print("Не найден сундук перед роботом!")
		break
	end
	print("Выберите операцию:")
	print("1) Запустить крафт")
	print("2) Записать крафт")
	print("Введите цифру операции...")
	operation = tonumber(io.read())
	list = nil
	name = nil
	items = nil
	if(operation == 1) then
		if(io.open("/home/ListOfCrafts","r") == nil) then
			print("Не найден файл списка крафтов\nили вы не записали ещё ни один крафт!")
			break
		else
			list = io.open("/home/ListOfCrafts", "r")
		end
		print("Введите название крафта...")
		name = io.read()
		wasFound = false
		line = list:read()
		while(line ~= nil) do 
			if(wasFound == true) then
				print("Крафт был найден!")
				print("Введите желаемое количество предметов,\n которое хотите создать...")
				count = tonumber(io.read())
				craft(split(line, ","), count)
				break
			end
			if(line == name) then
				wasFound = true
			end
			line = list:read()
		end
		if(wasFound == false) then
			print("Крафт не найден!")
		end
	elseif(operation == 2) then
		canCreate = false
		if(io.open("/home/ListOfCrafts","r") == nil) then
			list = io.open("/home/ListOfCrafts", "w")
			canCreate = true
		else
			list = io.open("/home/ListOfCrafts", "r")
		end
		print("Расставьте компоненты по рецепту\n для записи крафта")
		print("Если вы расставили все компоненты,\n то напишите название крафта на КИРИЛЛИЦЕ!")
		print(" (иначе могут возникнуть ошибки!)")
		name = io.read()
		list:flush()
		if (canCreate == true) then
			recordCraft(list, name)
		else
			canCreate = true;
			list = io.open("/home/ListOfCrafts", "r")
			line = list:read()
			while(line ~= nil) do 
				if(line == name) then
					canCreate = false
				end
				line = list:read()
			end
			if(canCreate == true) then
				recordCraft(list, name)
			end
		end
		if(canCreate == false) then
			print("Крафт с таким именем существует!")
		end
	end
	print("Хотите создать что-то ещё?\nВведите + или -")
	strConfirm = io.read()
	if(strConfirm == "-") then
		confirm = false
	end
end
r.select(1)