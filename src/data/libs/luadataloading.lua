local version = "v1.1.1d" --bugfix

local utf8 = require("utf8")
local ut = require("UT")
local pleal = require("plealTranspilerAPI")
local fs = require("lfs")

local DL = {
	version = version,
	
	conf = {
		logDataLoading = false,
		logLowDataloading = false,
		logDataExecution = false,
		logLowDataExecution = false,
	}
}
local pa = ut.parseArgs

local defaultFileCode = [[]]
local replacePrefixBlacklist = "%\"'[]"

--===== init =====--
pleal.setLogFunctions({
	log = function() end, --disableing transpiler logs.
	--log = print, --debug
	dlog = print,
	warn = function(...)
		print("[PleaL transpiling warn]: ", ...)
	end,
	err = function(...)
		print("[PleaL transpiling error]: ", ...)
		os.exit(1)
	end,
})

--===== log functions =====--
local function err(...)
	io.stderr:write(...)
	io.stderr:flush()
end

local function dataLoadingLog(...)
	if DL.logDataLoading then
		print(...)
	end
end
local function lowDataLoadingLog(...)
	if DL.logLowDataloading then
		print(...)
	end
end
local function dataExecutionLog(...)
	if DL.logDataExecution then
		print(...)
	end
end
local function lowDataExecutionLog(...)
	if DL.logLowDataExecution then
		print(...)
	end
end

--===== lib functions =====--
local function loadDir(target, dir, logFuncs, overwrite, subDirs, structured, priorityOrder, loadFunc, executeFiles)
	local path = dir .. "/" --= _I.shell.getWorkingDirectory() .. "/" .. dir .. "/"
	logFuncs = logFuncs or {}
	--local print = logFuncs.log or dlog
	local print = logFuncs.log or dataLoadingLog
	--local warn = logFuncs.warn or warn
	local warn = logFuncs.warn or print
	local onError = logFuncs.error or err
	local loadedFiles = 0
	local failedFiles = 0
	
	subDirs = ut.parseArgs(subDirs, true)
	
	for file in fs.dir(path) do
		local p, name, ending = ut.seperatePath(path .. file)		
		if file ~= "." and file ~= ".." and name ~= "gitignore" and name ~= "gitkeep" then
			if fs.attributes(path .. file).mode == "directory" and subDirs then
				if structured then
					if target[string.sub(file, 0, #file)] == nil or overwrite then
						target[string.sub(file, 0, #file)] = {}
						local s, f = loadDir(target[string.sub(file, 0, #file)], dir .. "/" .. file, logFuncs, overwrite, subDirs, structured, priorityOrder, loadFunc, executeFiles)
						loadedFiles = loadedFiles + s
						failedFiles = failedFiles + f
					else
						onError("[DLF]: Target already existing!: " .. file .. " :" .. tostring(target))
					end
				else
					local s, f = loadDir(target, path .. file, logFuncs, overwrite, subDirs, structured, priorityOrder, loadFunc, executeFiles)
					loadedFiles = loadedFiles + s
					failedFiles = failedFiles + f
				end
			elseif target[name] == nil or overwrite then
				local debugString = ""
				if target[name] == nil then
					debugString = "Loading file: " .. dir .. "/" .. file .. ending .. ": "
				else
					debugString = "Reloading file: " .. dir .. "/" .. file .. enging .. ": "
				end
				
				local suc, conf, err 
				if loadFunc ~= nil then
					suc, err = loadFunc(path .. file)
				else
					--suc, err = loadfile(path .. file)
					--local filePath = "core/" .. path .. file
					local filePath = path .. file
					local fileCode, fileErr = ut.readFile(filePath)
					local tracebackPathNote = filePath
					--print(path .. file)
					if fileCode == nil then
						suc, err = nil, fileErr
					else
						local cutPoint
						cutPoint = select(2, string.find(tracebackPathNote, "/env/"))
						if not cutPoint then
							cutPoint = select(2, string.find(tracebackPathNote, "/api/"))
						end
						if cutPoint then
							tracebackPathNote = string.sub(tracebackPathNote, cutPoint + 1)
						end

						if ending == ".lua" then
							suc, err = load("--[[" .. tracebackPathNote .. "]] " .. defaultFileCode .. fileCode)
						elseif ending == ".pleal" then
							suc, err = load(select(3, pleal.transpile("--[[" .. tracebackPathNote .. "]] " .. defaultFileCode .. fileCode)))
						end
					end
				end
				
				if priorityOrder then
					local order = 50
					for fileOrder in string.gmatch(name, "([^_]+)") do
						order = tonumber(fileOrder)
						break
					end
					if order == nil then
						order = 50
					end
					if target[order] == nil then
						target[order] = {}
					end
					target[order][name] = suc
				else
					target[name] = suc
					if executeFiles then
						if type(suc) == "function" then
							local suc, returnValue = xpcall(suc, debug.traceback)
							if suc == false then
								onError("Failed to execute: " .. name)
								onError(returnValue)
							else
								target[name] = returnValue
							end
						end
					end
				end
				
				if suc == nil then 
					failedFiles = failedFiles +1
					onError("Failed to load file: " .. dir .. "/" .. file .. ": " .. tostring(err))
				else
					loadedFiles = loadedFiles +1
					lowDataLoadingLog(debugString .. tostring(suc))
				end
			end
		end
	end
	return loadedFiles, failedFiles
end

local function load(args)
	local target = pa(args.t, args.target, {})
	local dir = pa(args.d, args.dir)
	local name = pa(args.n, args.name, args.dir)
	local structured = pa(args.s, args.structured, true)
	local priorityOrder = pa(args.po, args.priorityOrder, false)
	local overwrite = pa(args.o, args.overwrite, false)
	local loadFunc = pa(args.lf, args.loadFunc)
	local executeFiles = pa(args.e, args.execute, args.executeFiles, args.executeDir, false)
	
	local loadedFiles, failedFiles = 0, 0
	
	dataLoadingLog("Loading dir: " .. dir .. " (" .. name .. ")")
	loadedFiles, failedFiles = loadDir(target, dir, nil, overwrite, nil, structured, priorityOrder, loadFunc, executeFiles)
	dataLoadingLog("Successfully loaded files: " .. tostring(loadedFiles) .. " (" .. name .. ")")
	if failedFiles > 0 then
		err("Failed to load " .. tostring(failedFiles) .. " (" .. name .. ")")
	end
	dataLoadingLog("Loading dir done: " .. dir .. " (" .. name .. ")")
	return target
end

local function execute(t, dir, name, callback, callbackArgs)
	local executedFiles, failedFiles = 0, 0
	
	dataExecutionLog("Execute: " .. dir .. " (" .. name .. ")")
	
	for order = 0, 100 do
		local scripts = t[order]
		if scripts ~= nil then
			for name, func in pairs(scripts) do
				lowDataExecutionLog("Execute: " .. name .. " (" .. tostring(func) .. ")")
				local suc, err = xpcall(func, debug.traceback)
				
				if suc == false then
					err("Failed to execute: " .. name)
					err(err)
					failedFiles = failedFiles +1
				else
					if callback ~= nil then 
						callback(err, name, callbackArgs)
					end
					executedFiles = executedFiles +1
				end
			end
		end
	end
	
	return executedFiles, failedFiles
end

local function loadDir_Disabled(dir, target, name) --is this used or even done? edit1: what the frick is that and why? renamed it to loadDir_Disabled
	name = name or ""
	dataLoadingLog("Prepare loadDir execution: " .. name .. " (" .. dir .. ")")
	local scripts = load({
		target = {}, 
		dir = dir, 
		name = name, 
		priorityOrder = true,
		structured = true,
	})
	print("################################")
	print(ut.tostring(scripts))
	
	local function sortIn(value, orgName, args)
		local index = args.index
		local name = orgName
		local order = string.gmatch(name, "([^_]+)")()
		local target = args.target
		
		if tonumber(order) ~= nil then
			name = string.sub(name, #order +2)
		end
		
		--print("F", orgName, name, index, value, args)
		
		
		target[name] = value
	end
	
	execute(scripts, dir, name, sortIn, {target = target})
	
	local function iterate(toIterate)
		if type(toIterate) ~= "table" then return end
		
		for i, t in pairs(toIterate) do
			print(i, type(tonumber(i)))
			if tonumber(i) == nil and type(t) == "table" then
				print(i, t)
				
				if toIterate[i] == nil then
					toIterate[i] = {}
				end
				
				execute(t, dir, name, sortIn, {target = t})
			end
			iterate(t)
		end
	end
	iterate(scripts)
	
	print(ut.tostring(target))
end

local function executeDir(dir, name)
	name = name or ""
	dataExecutionLog("Prepare execute execution: " .. name .. " (" .. dir .. ")")
	local scripts = load({
		target = {}, 
		dir = dir, 
		name = name, 
		priorityOrder = true,
	})
	
	local executedFiles, failedFiles = execute(scripts, dir, name)

	dataExecutionLog("Successfully executed: " .. tostring(executedFiles) .. " files (" .. name .. ")")
	if failedFiles > 0 then
		warn("Failed to executed: " .. tostring(failedFiles) .. " (" .. name .. ")")
	end
	dataExecutionLog("Executing done: " .. name .. " (" .. dir .. ")")
end

--===== set functions =====--
--DL.loadData = loadData
DL.load = load
DL.loadDir = loadDir
DL.executeDir = executeDir
DL.setEnv = setEnv

return DL