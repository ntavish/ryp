#!/usr/bin/lua

package.path = package.path .. ";./?.lua"

local posix = require "posix"
local launcher = require "launcher"
local goog_speech_parse = require "goog_speech_parse"

local P={}

goog_speech=P

-- launching with shell, this is not meant for 
sox_proc = 'sox.sh'
sox_output = '/tmp/recording.flac'
wget_proc = 'wget.sh'

function goog_speech.recording_length()
	local recfile=posix.open(sox_output, posix.O_RDONLY)
	if recfile then
		local reclen = posix.lseek(recfile, 0, posix.SEEK_END)
		posix.close(recfile)
		return reclen
	end
	return nil
end


function goog_speech.listen(timeout)
	--[[ starts sox and sends to google for recognition
		 timeout is in seconds, minimum 5
	]]
	-- clear old files, kill sox

	if timeout < 5 then
		timeout = 5
	end
	os.remove(sox_output)
	os.execute('killall -s 9 sox >/dev/null 2>&1')
	
	local start_time=posix.time()

	local sr,sw,sp = launcher.launch_child(sox_proc, {params=sox_output})
	posix.wait(sp)
	local sox_pid, err = posix.read(sr, 1000)
	if sox_pid ~= nil then
		print('Sox proces pid = '..sox_pid)
	else
		print("ERROR: sox process pid not read. "..err) --probably nothing to read
	end

	while true do
		local is_sox_running = posix.kill(sox_pid,0)
		-- 0 means is running, nil otherwise
		if is_sox_running == 0 then
			print('Sox is running')
		end
		if  is_sox_running ~= 0 then
			print('Sox exited')
			break
		end
		if (posix.time()-start_time > 5) and is_sox_running == 0 then
			if goog_speech.recording_length() == 114 then
				print('No sound for much time, exit')
				posix.kill(sox_pid)
				break
			else
				print('Sox is still recording')
				if (posix.time()-start_time > timeout) then
					print('taking too long, exit')
					posix.kill(sox_pid)
					break
				end
			end
		end
		os.execute('sleep 1')
	end

	local r,w, ch_pid = launcher.launch_child(wget_proc)
	posix.fcntl(r, posix.F_SETFL, posix.O_NONBLOCK)

	local speech_result = ''
	while true do
		local buf=launcher.read(r, 100)
		if buf ~=nil and #buf >0 then
			speech_result = speech_result..buf
		end
		local pid,status,code = posix.wait(ch_pid, posix.WNOHANG)
		if pid==ch_pid then
			while true do
				buf=posix.read(r, 2048)
				if buf ~= nil then
					speech_result = speech_result..buf
				else
					break
				end
			end
			break
		end
	end
	
	-- {"status":0,"id":"","hypotheses":[{"utterance":"youtube","confidence":0.52547479}]}
	return goog_speech_parse.get(speech_result)
end

--[[while true do 
	local res = goog_speech.listen(10)
	if res ~= nil then
		print(res.utterance)
	end
end
--]]

return goog_speech