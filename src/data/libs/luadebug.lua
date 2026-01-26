local version = "1.0d"

local orgDebug = _G.debug
local debug = {
	version = version,
	
	internal = {
		logPrefix = "",
		debugPrefix = "",
		internalPrefix = "",
		functionPrefixes = {},
	},

	silenceMode = false,

	currentLogStream = io.stdout,
	currentColors,
	
	conf = {
		dateFormat = "%X",
		
		logLevel = {
			
		},
		
		--[[ the colors are defined per log function.
		it uses ANSI escape sequences to achiev colors.
		8bit color codes can be found in the notes dir.

		more information about ANSI escape codes can be douns here: https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797
		]]
		terminalColors = {
			default = "\027[38;5;250m\027[40m",
			log = "\027[38;5;250m",
			dlog = "\027[38;5;68m",
			warn = "\027[38;5;178m",
			err = "\027[38;5;160m",
			crucial = "\027[48;5;52m",
			fatal = "\027[48;5;88m\027[38;5;196m",
		},
	}
}

--===== set basic log functions =====--
local function getCurrentLogStream()
	return debug.currentLogStream
end
local function setCurrentLogStream(stream)
	debug.currentLogStream = stream
end
local function getSilenceMode()
	return debug.silenceMode
end
local function setSilenceMode(silence)
	debug.silenceMode = silence
end

local function getDebugPrefix()
	return debug.internal.debugPrefix
end
local function setDebugPrefix(prefix)
	debug.internal.debugPrefix = tostring(prefix)
end

local function getFuncPrefix(stackLevel, fullPrefixStack)
	local prefix, exclusive = "", false
	local prefixTable
	if fullPrefixStack == nil then fullPrefixStack = true end
	
	if stackLevel == nil or type(stackLevel) == "number" then 
		prefix, exclusive, fullStack = getFuncPrefix(orgDebug.getinfo(stackLevel or 3).func)
	elseif type(stackLevel) == "function" then
		local prefixTable = debug.internal.functionPrefixes[stackLevel]
		if prefixTable == nil then
			return "", false
		else
			return tostring(prefixTable.prefix), prefixTable.exclusive, prefixTable.fullStack
		end	
	end
	
	if fullPrefixStack and fullStack or fullStack == nil then
		for stackLevel = stackLevel +1, math.huge do
			local stackInfo = orgDebug.getinfo(stackLevel)
			local stackPrefix = ""
			local stackExclusive, fullStack
		
			if stackInfo == nil then break end
		
			stackPrefix, stackExclusive, fullStack = getFuncPrefix(stackInfo.func)
			
			if stackExclusive then
				exclusive = true
			end
			
			prefix = stackPrefix .. prefix
			
			if fullStack == false then
				break
			end
		end
	end
	
	return tostring(prefix), exclusive
end
local function setFuncPrefix(prefix, exclusive, noFullStack, stackLevel) 
	local prefixTable = {}
	local func
	
	if stackLevel == nil then
		func = orgDebug.getinfo(2).func
	elseif type(stackLevel) == "number" then
		func = orgDebug.getinfo(stackLevel + 2).func
	elseif type(stackLevel) == "function" then
		func = stackLevel
	end
	
	if prefix ~= nil then
		prefixTable.prefix = prefix
		prefixTable.exclusive = exclusive
		if noFullStack == false or noFullStack == nil then
			prefixTable.fullStack = true
		else
			prefixTable.fullStack = false
		end
		debug.internal.functionPrefixes[func] = prefixTable
	else
		debug.internal.functionPrefixes[func] = nil
	end
end
local function setInternalPrefix(prefix)
	debug.internal.internalPrefix = prefix
end
local function getInternalPrefix(prefix)
	return debug.internal.internalPrefix
end

local function getLogPrefix()
	return tostring(debug.internal.logPrefix)
end
local function setLogPrefix(prefix, keepPrevious)
	if keepPrevious then
		debug.internal.logPrefix = getLogPrefix() .. prefix
	else
		debug.internal.logPrefix = prefix
	end
end

local function setColors(colors)
	local firstRun = true
	if not colors then
		colors = debug.conf.terminalColors.default
	end
	debug.currentColors = colors
end

local function clog(...) --clean log
	local msgs, msgString = "", ""
	
	for _, msg in pairs({...}) do
		msgs = msgs .. tostring(msg) .. "  "
	end
	msgs = msgs:sub(0, -3)

	msgString = debug.currentColors .. "[" .. os.date(debug.conf.dateFormat) .. "]" .. getInternalPrefix() .. msgs .. "\027[0m\n"

	if not debug.silenceMode then
		debug.currentLogStream:write(msgString)
		debug.currentLogStream:flush()
	end
	setInternalPrefix("")
	return ...
end
local function plog(...)
	local prefix = ""
	local funcPrefix, allowLogPrefix = getFuncPrefix(0)
	
	if allowLogPrefix then
		prefix = funcPrefix .. prefix
	else
		prefix = getLogPrefix() .. funcPrefix .. prefix
	end	
	prefix = prefix .. ":"
	
	setInternalPrefix(getDebugPrefix() .. prefix .. " ")
	clog(...)
	
	setDebugPrefix("")
	return ...
end
local function err(...)
	local silenceMode = debug.getSilenceMode()
	debug.setSilenceMode(false)
	setDebugPrefix("[ERROR]")
	setColors(debug.conf.terminalColors.err)
	plog(...)
	if silenceMode then
		debug.setSilenceMode(true)
	end
	return ...
end
local function crucial(...)
	local silenceMode = debug.getSilenceMode()
	debug.setSilenceMode(false)
	setDebugPrefix("[CRUCIAL]")
	setColors(debug.conf.terminalColors.crucial)
	plog(...)
	if silenceMode then
		debug.setSilenceMode(true)
	end
	return ...
end
local function fatal(...)
	debug.setSilenceMode(false)
	setDebugPrefix("[FATAL]")
	setColors(debug.conf.terminalColors.fatal)
	plog(...)
	io.stdout:write("\027[0m")
	io.stdout:flush()
	os.exit(1)
	return ...
end

--===== add advanced log levels =====--
local function addDebugLogLevel(name, prefix, confLevelIndex)
	local func = function(...) return ... end
	local logLevelEnabled = debug.conf.logLevel[confLevelIndex]
	
	if logLevel or logLevel == nil then
		func = function(...)
			setColors(debug.conf.terminalColors[name])
			setDebugPrefix(prefix)
			plog(...)
			return ...
		end
	end
	
	debug[name] = func
end

addDebugLogLevel("log", "[INFO]", "log")
addDebugLogLevel("warn", "[WARN]", "warn")
addDebugLogLevel("dlog", "[DEBUG]", "debug")

--===== merge debug into _G.debug =====--
local function init(forceMerge)
	for i, v in pairs(debug) do
		if forceMerge or _G.debug[i] == nil then
			_G.debug[i] = v
		else
			debug.warn("_G.debug and debug.lua has common variable '" .. i .. "'. Skipping merge.")
		end
	end
	return debug
end

--===== set debug function =====--
--setLogPrefix(defaultPrefix)

debug.clog = clog
debug.plog = plog
debug.err = err
debug.crucial = crucial
debug.fatal = fatal

debug.getCurrentLogStream = getCurrentLogStream
debug.setCurrentLogStream = setCurrentLogStream

debug.setSilenceMode = setSilenceMode
debug.getSilenceMode = getSilenceMode

debug.setLogPrefix = setLogPrefix
debug.getLogPrefix = getLogPrefix

debug.setFuncPrefix = setFuncPrefix
debug.getFuncPrefix = getFuncPrefix

debug.setDebugPrefix = setDebugPrefix
debug.getDebugPrefix = getDebugPrefix

debug.setColors = setColors

debug.init = init

--=== set global metatables ===--
--[[
_G.debug = setmetatable(orgDebug, {__index = function(t, i)
	if debug[i] ~= nil then
		return debug[i]
	else
		return nil
	end
end})

_G = setmetatable(_G, {__index = function(t, i)
	return debug.global[i]
end})
]]

--=== init ===--
setColors()

return debug