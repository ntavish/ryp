#!/usr/bin/lua

package.path = package.path .. ";./?.lua"
local goog_speech = require "goog_speech"
local goog_speech_parse = require "goog_speech_parse"
require "youtubesearch"
require "youtubemp3"

function listen(vars)
	--timeout to 15
	--debugging
	-- do	return "youtube" end
	os.execute('echo 0 > /sys/class/leds/slave_mode/brightness')
	os.execute('echo 0 > /sys/class/leds/master_mode/brightness')
	print(type(vars).." "..tostring(vars["cur_state"]))
	local res=goog_speech.listen(15)
	if res == nil then
		return ""
	else
		print(res.utterance)
		return res.utterance
	end
end

function get_song(vars)
	os.execute('echo 0 > /sys/class/leds/slave_mode/brightness')
	os.execute('echo 255 > /sys/class/leds/master_mode/brightness')
	local max_retry = 3
	print(type(vars).." "..tostring(vars.cur_state))
	while max_retry > 0 do
		local res = listen(vars)
		if res ~= "" then
			vars["song"] = res
			print("Song is : " .. tostring(vars.song).." ".."res is : "..res)
			return 'play'
		end
		max_retry = max_retry -1
	end
	return "back"
end

function play_youtube(vars)
	os.execute('echo 255 > /sys/class/leds/slave_mode/brightness')
	os.execute('echo 0 > /sys/class/leds/master_mode/brightness')
	print(type(vars).." "..tostring(vars.cur_state))
	print("Now playing: " .. vars["song"])
	local video_url = youtubesearch.get(vars["song"])
	local vid = string.match(video_url, "v=([^%s\"\'&]+)")
	print("Vid url:" .. video_url .. " vid : " .. vid)
	local mp3url = youtubemp3.get(vid)
	if mp3url then
		os.execute("ffmpeg -i " .. mp3url .. " -f oss /dev/dsp")
	end
	-- os.execute("vlc " .. mp3url)
	return ""
end

local state_variables = { ["cur_state"] = "idle", ["song"] = "asdasd"}

local states = {
	["idle"]				= listen,
	["active"]				= get_song,
	["playing"]				= play_youtube
}

local transitions = {
	["idle"]	= {
				["youtube"]	= "active",
			},
	["active"]	= {
				["back"]	= "idle",
				["play"]	= "playing"
			},
	["playing"]	= {
				[""]		= "idle"
			}
}


local vars = state_variables
while true do
	print("Current state: "..state_variables["cur_state"])
	local res = states[state_variables["cur_state"]](vars)
	local next_state = transitions[state_variables["cur_state"]][res]
	if next_state ~= nil then
		state_variables.cur_state = next_state
	end
end