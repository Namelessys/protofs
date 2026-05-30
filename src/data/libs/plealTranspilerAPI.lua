--[[
    PleaL (PleasantLua) is a custom version of lua. Implementing features like a more convinient way of embetting variables into strings as well as things like +=. 
    It works by comverting PleaL code unto native lua code. Wich means that pleal runs on ordinary lua interpreters.

    Requirements: 
        Interpreter: lua5.1+ or LuaJIT


    Copyright (C) 2023  MisterNoNameLP

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]

local version = "0.9.2"

local pleal = {}

--===== internal variables =====--
local log = print
local err = log
local warn = log
local dlog = function(...) end

local globalConfig = {
	replacementPrefix = "$",
	removeConfLine = true,
	varNameCapsuleOpener = "{",
	varNameCapsuleFinisher = "}",
	execCapsuleOpener = "(",
	execCapsuleFinisher = ")",
	dumpScripts = false,
	dumpLineIndicators = false,
}

local originalCurrentlyTranspiledScript


local replacePrefixBlacklist = "%\"'[]{}()"
local allowedVarNameSymbols = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_.()" --string pattern

--===== internal functions =====--
--=== basic functions ===--
function readFile(path)
	local file, err = io.open(path, "rb")
	
	if file == nil then 
		return nil, err 
	else
		local fileContent = file:read("*all")
		file:close()
		return fileContent
	end
end
function pa(...) --returns the first non nil parameter.
	for _, a in pairs({...}) do
		if a ~= nil then
			return a
		end
	end
end
function len(string) --may gets replaces with utf8 support if needed.
    if type(string) == "string" then
        return #string
    else
        return 0
    end
end
local function keepCalling(func, maxTries, ...) --Call the given function until it returns true or 1.
	local done 
	local tries = 0
	if not maxTries then
		maxTries = math.huge
	end
	while done ~= 1 and done ~= true do
		tries = tries + 1
		if tries > maxTries then
			err("keepCalling failed: Max tries reached")
			return false, "max calling tries reached"
		end
		done = func(...)
	end
end
local function executeLuaCode(luaCode, ...)
	local unpackFunction, loadFunction
	local loadingError, loadedFunction, executionResults 

	-- lua backwards compatibility
	if unpack then
		unpackFunction = unpack
	else
		unpackFunction = table.unpack
	end
	if loadstring then
		loadFunction = loadstring
	else
		loadFunction = load
	end

	loadedFunction, loadingError = loadFunction(luaCode)
	if type(loadedFunction) ~= "function" then
		err("Could not load script: " .. tostring(loadingError))
		return false, "Could not load script", loadingError
	end
	executionResults = {xpcall(loadedFunction, debug.traceback, ...)}
	if not executionResults[1] then
		err("Could not execute script: " .. executionResults[2])
	end
	return unpackFunction(executionResults)
end

--=== conversion functions ===--
local function loadConf(input) --removes the conf line from the input and return it.
	local conf = {}
	local _, scriptConf
	for i, c in pairs(globalConfig) do
		conf[i] = c
	end
	for line in input:gmatch("[^\n]+") do
		if line:sub(0, 2) == "#?" then 
			local confLine = line:sub(3)
			local confInterpreterString = [[
				local conf = {}
				local globalMetatable = getmetatable(_G)
				_G = setmetatable(_G, {__newindex = function(_, index, value) conf[index] = value end})
			]] .. confLine .. [[
				_G = setmetatable(_G, globalMetatable)
				return conf
			]]
			local confInterpreterFunc = loadstring(confInterpreterString)
			if not confInterpreterFunc then
				return false, "Invalid file conf line"
			end
			_, scriptConf = pcall(confInterpreterFunc)
			input = input:sub(len(line) + 1) --cut out conf line
		elseif line:sub(0, 2) == "#!" then
			input = input:sub(len(line) + 1)
		end
		break
	end
	if type(scriptConf) ~= "table" then
		return conf, input
	else
		for i, c in pairs(scriptConf) do
			conf[i] = c
		end
	end
	return conf, input
end
local function embedVariables(input, conf)
	local output = ""

	local function cut(pos)
		output = output .. input:sub(0, pos)
		input = input:sub(pos + 1)
	end

	local function embed(finisher)
		local symbolPos
		local symbol
		local prevSymbol, nextSymbol
		local opener
	
		--getting for relevant symbols
		local function setSymbol()
			symbolPos = input:find("[%[%]\"'"..replacePrefix.."]")
			if not symbolPos then
				cut(len(input))
				return true
			end
			symbol = input:sub(symbolPos, symbolPos)
			prevSymbol = input:sub(symbolPos - 1, symbolPos - 1)
			nextSymbol = input:sub(symbolPos + 1, symbolPos + 1)
		end
		if setSymbol() then
			return true
		end

		--preparing opener to handle [[]] strings
		if finisher == "]]" then
			opener = "[["
			if symbol == "]" and nextSymbol == "]" then
				symbol = "]]"
			end
		else
			opener = finisher
		end

		--process symbol
		--finisher exists only if the parser in in a string.
		if symbol == finisher then
			cut(symbolPos)
			if prevSymbol ~= "\\" then
				return 1
			end
		elseif finisher and symbol == replacePrefix and finisher ~= "]" then
			local varNameCapsuleIsUsed = false
			local varFinishingPos
			local varFinishingSymbol

			if prevSymbol == "\\" then
				cut(symbolPos - 2)
				input = input:sub(2)
				cut(1)
				return 
			end
			cut(symbolPos)
			if nextSymbol == conf.varNameCapsuleOpener then
				input = input:sub(2)
				varNameCapsuleIsUsed = true
				varFinishingPos = input:find(conf.varNameCapsuleFinisher)
			else
				varFinishingPos = input:find("[^" .. allowedVarNameSymbols .. "]")
			end
			if varNameCapsuleIsUsed and not varFinishingPos then
				err("Opened var name capsule is not closed at line: " .. tostring(select(2, output:gsub("\n", "\n")) + 1) .. "\n" .. originalCurrentlyTranspiledScript:match("[^\n]+") .. "\n ...")
			end
			
			varFinishingSymbol = input:sub(varFinishingPos, varFinishingPos) --to handle table embedding

			--cut out the var name
			local varName = input:sub(0, varFinishingPos - 1)
			input = input:sub(varFinishingPos)
			--remove var name cabsule closer
			if varNameCapsuleIsUsed and input:sub(0, 1) == conf.varNameCapsuleFinisher then
				input = input:sub(2)
			end 
			--remove replacePrefix
			output = output:sub(0, -2)

			if varFinishingSymbol == "[" then
				local insertingSuc, insertingErr
				local anotherIndex = true

				output = output .. finisher .. "..tostring(" .. varName
				cut(1)
				while anotherIndex do
					insertingSuc, insertingErr = keepCalling(embed, nil, "]")
					if insertingSuc == false then
						return insertingErr
					elseif setSymbol() then
						return true
					end
					if symbol ~= "[" then
						anotherIndex = false
					end
				end
				output = output .. ").." .. opener
			else
				output = output .. finisher .. "..tostring(" .. varName .. ").." .. opener
			end
		else
			cut(symbolPos)
			--if 
			--	(symbol == "\"" or symbol == "'") and 
			--	not finisher and 
			--	not (finisher == "]" or finisher == "]]") 
			--then
			if (symbol == "\"" or symbol == "'") and (not finisher or finisher == "]") then
				return keepCalling(embed, nil, symbol)
			elseif symbol == "[" and nextSymbol == "[" and not finisher then
				return keepCalling(embed, nil, "]]")
			elseif symbol == "[" then

			end
		end
	end

	local suc, err = keepCalling(embed, nil)
	if suc == false then 
		return false, err
	end

	return true, output
end


--===== main functions =====--
--=== basic functions ===--
local function getVersion()
	return version
end
local function getLogFunctions()
	return log, err, dlog
end
local function setLogFunctions(logFunctions)
	log = pa(logFunctions.log, log, function() end)
	warn = pa(logFunctions.warn, warn, function() end)
	err = pa(logFunctions.err, err, function() end)
	dlog = pa(logFunctions.dlog, dlog, function() end)
end
local function getConfig()
	return globalConfig
end
local function setConfig(conf)
	for i, c in pairs(conf) do
		globalConfig[i] = c
	end
end

--=== conversion functions ===--
local function transpile(input, note)
	local lineCount = 0	
	local _, conf

	--load conf line
	do
		local err
		log("Load conf line")
		conf, err = loadConf(input)
		if not conf then
			err("Could conf line")
			return false, "Could not load conf line", err
		else 
			input = err
		end
	end

	if note then
		input = "--[[" .. tostring(note) .. "]] " .. input
	end
	originalCurrentlyTranspiledScript = input --for debugging purpose / better error msgs

	--process conf 
	if conf.removeConfLine and input:sub(0, 2) == "#!" or input:sub(0, 2) == "#?" then
		log("Remove conf line")
		local confLineEnd = input:find("\n") + 0
		input = input:sub(confLineEnd)
	end
	
	--error checks
	replacePrefix = pa(conf.replacePrefix, "$")
	if type(replacePrefix) ~= "string" then
		err("Invalid replacePrefix")
		return false, "Invalid replacePrefix."
	end
	if len(replacePrefix) > 1 then
		err("replacePrefix is too long. Only a 1 char long prefix is allowed")
		return false, "replacePrefix is too long. Only a 1 char long prefix is allowed."
	end
	for c = 0, len(replacePrefixBlacklist) do
		local blacklistedSymbol = replacePrefixBlacklist:sub(c, c)
		if replacePrefix == blacklistedSymbol then
			err("replacePrefix (" .. replacePrefix .. ") is not allowed")
			return false, "replacePrefix (" .. replacePrefix .. ") is not allowed"
		end
	end

	--embed variables
	if conf.variableEmbedding ~= false then
		local suc 
		log("Embed variables")
		--embed variables
		suc, input = embedVariables(input, conf)
		if not suc then
			err("Variable embedding failed")
			return false, "Variable embedding failed", input
		end
	else
		log("Variable embedding disabled per conf line")
	end

	--finishing up
	log("Finishing up")

	if globalConfig.dumpScripts then
		local toDump
		if globalConfig.dumpLineIndicators then
			toDump = ""
			local lineCounter = 1
			for line in input:gmatch("[^\n]*") do
				toDump = toDump .. "# " .. tostring(lineCounter) .. " | " .. line .. "\n"
				lineCounter = lineCounter + 1
			end
			toDump = toDump:sub(0, -2)
		else
			toDump = input
		end

		dlog("    vvvvvvv PLEAL DUMP BEGINNING vvvvvvv \n" .. toDump .. "\n       ^^^^^^^ PLEAL DUMP END ^^^^^^^\n")
	end
	originalCurrentlyTranspiledScript = nil

	return true, conf, input
end
local function transpileFile(path) 
    local fileContent = readFile(path)
    if not fileContent then
		err("Tried to transpile non existing file")
        return false, "File not found"
    else
		log("transpile: " .. path)
        return transpile(fileContent, path)
    end
end
local function execute(script, ...)
	if type(script) ~= "string" then
		err("Invalid script given")
		return false, "Invalid script"
	else
		local transpileSuccess, conf, luaCode
		-- transpiling and loading the script
		transpileSuccess, conf, luaCode = transpile(script)
		if not transpileSuccess then
			err("Could not transpile script")
			return false, "Could not transpile", conf, luaCode
		end
		--executing the script
		log("Exec script")
		return executeLuaCode(luaCode, ...)
	end
end
local function executeFile(path, ...)
	local suc, conf, luaCode = transpileFile(path)
	if not suc then
		err("Could not execute file: " .. tostring(path) .. " (" .. tostring(luaCode) .. ")")
		return false, "Could not execute file: " .. tostring(luaCode)
	else
		return executeLuaCode(luaCode, ...)
	end
end


--===== linking main functions to pleal table =====--
pleal.version = version
pleal.getVersion = getVersion

pleal.getLogFunctions = getLogFunctions
pleal.setLogFunctions = setLogFunctions

pleal.getConfig = getConfig
pleal.setConfig = setConfig

pleal.transpile = transpile
pleal.transpileFile = transpileFile

pleal.execute = execute
pleal.executeFile = executeFile


return pleal