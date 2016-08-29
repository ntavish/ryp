#!/usr/bin/lua

--[[
		needs lpty http://www.tset.de/lpty/README.html, packaged
]]

package.path = package.path .. ";/root/web/www/cgi-bin/?.lua"

local lpty   = require "lpty"
require "posix"

function handler(signo)
	-- body
	print("handling")
	print(debug.traceback())
	posix._exit(0)
end

print("setting handler for ".. tostring(posix.SIGINT))
posix.signal(posix.SIGINT, handler)

mute_state = false

function __toggle_mute()
	if mute_state == false then
		os.execute("amixer -c 0 set Speaker mute")
		mute_state = true
	else
		os.execute("amixer -c 0 set Speaker unmute")
		mute_state = false
	end
end

function next_song()
	os.execute("killall ffmpeg")
end

function wps()
	print("wps")
	services.start("hostapd_cli -p /var/run/hostapd-phy0 wps_pbc")
end

function volume_down(presses)
	-- vol down
	if not presses.b3.pressed then
		print("voldown")
		os.execute("amixer -c 0 set Speaker 10%-")
		if mute_state == true then
			__toggle_mute()
		end
	end
end

function volume_up(presses)
	-- vol up
	if not presses.b2.pressed then
		print("volup")
		os.execute("amixer -c 0 set Speaker 10%+")
		if mute_state == true then
			__toggle_mute()
		end
	end
end

function mute(presses)
	-- mute
	if presses.b2.pressed and presses.b3.pressed then
		print("mute")
		__toggle_mute()
	end
end


presses ={
	["b1"] = {pressed = false, t1=0, t2=0, long_press_duration = 2, shortaction = next_song,	longaction = wps},
	["b3"] = {pressed = false, t1=0, t2=0, long_press_duration = 1, shortaction = volume_up, 	longaction = mute},
	["b2"] = {pressed = false, t1=0, t2=0, long_press_duration = 1, shortaction = volume_down,	longaction = mute},
}

buttons_list = { 
	['114'] = presses.b1,
	['115'] = presses.b2,
	['529'] = presses.b3,
}

p = lpty.new() 
p:startproc("event_test", "/dev/input/event0")

while true do
	print("buttons.lua waiting")
	if not p:hasproc() then
		p:startproc("event_test", "/dev/input/event0")
	end
	local r = p:read()
	if r then
		for code, name, value in string.gmatch(r,"code ([0-9]+) %((.[^,]*)%), value ([0-9]+)") do
			-- local val = string.match()
			print(r, code, name, value)
			if code ~= '0' and code ~= nil then
				-- print("code "..tostring(code)..' name '..name..' value '..tostring(value))
				if buttons_list[code] ~= nil then
					print("button "..tostring(code))
					if buttons_list[code].pressed == false then
						buttons_list[code].pressed = true
						buttons_list[code].t1 = posix.time()
					else
						buttons_list[code].t2 = posix.time()
						if (buttons_list[code].t2 - buttons_list[code].t1) > buttons_list[code].long_press_duration then
							buttons_list[code].longaction(presses)
						else
							buttons_list[code].shortaction(presses)
						end
						buttons_list[code].pressed = false
					end
				end
			end
		end
	end
end


