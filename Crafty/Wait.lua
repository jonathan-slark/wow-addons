--
-- Wait Module
--
-- Wait's for a certain delay before running a function, that function can also
-- call to wait. The implementation isn't perfect, the delay could be called 
-- one frame early or late, but it's good enough!
--

Crafty_Wait = {}

-- Import
local Wait = Crafty_Wait
local Data = Crafty_Data
local CreateFrame = CreateFrame
local table = table
local type = type
local unpack = unpack

-- Make sure we don't polute the global environment
setfenv(1, {})

Wait.frame = CreateFrame("Frame")
Wait.frame.funcs = {}
Wait.running = false

-- Stop the wait subsystem
function Wait:Stop()
    --Data:Debug("Wait:Stop", "Stopping Wait")
    self.running = false
    self.frame:SetScript("OnUpdate", nil)
end

-- Start a function after the specified delay, in seconds
function Wait:Start(delay, func, ...)

    if self.running then
	-- NOOP
    else
	--Data:Debug("Wait:Start", "Starting Wait")
	self.running = true
	self.frame:SetScript("OnUpdate", function (self, elapse)

	    for i = 1, #self.funcs do
		-- If row removed we can end up falling off the end of the table
		if not self.funcs[i] then
		    break
		end
		if elapse > self.funcs[i].delay then
		    local f = self.funcs[i].func
		    local p = self.funcs[i].param
		    table.remove(self.funcs, i)
		    if #self.funcs == 0 then
			Wait:Stop()
			f(unpack(p))
			return
		    else
			f(unpack(p))
		    end
		else
		    self.funcs[i].delay = self.funcs[i].delay - elapse
		end
	    end
	end)
    end

    self.frame.funcs[#self.frame.funcs + 1] = {
	delay = delay, 
	func = func, 
	param = { ... }
    }
end
