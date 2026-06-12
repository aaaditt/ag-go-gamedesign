--!strict
-- Tiny signal bus shared by client scripts (KartController, RaceFlow, HUD…).
-- Avoids Instance-based events for plain cross-script coordination.

export type Handler = (...any) -> ()

local Bus = {}
local handlers: { [string]: { Handler } } = {}

function Bus.on(event: string, fn: Handler)
	local list = handlers[event]
	if not list then
		list = {}
		handlers[event] = list
	end
	table.insert(list, fn)
end

function Bus.fire(event: string, ...: any)
	local list = handlers[event]
	if not list then
		return
	end
	for _, fn in list do
		task.spawn(fn, ...)
	end
end

return Bus
