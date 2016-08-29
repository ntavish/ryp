#!/usr/bin/lua
-- package.path = package.path .. ";./?.lua"
require "posix"
require "BinDecHex"

local P = {}
youtubemp3 = P


local function _cc(a)
	local __AM = 65521
	local c = 1
	local b = 0
	local d, e

	e = 0
	while e < #a do
		e = e + 1
		d = string.byte(string.sub(a, e, e))
		c = (c + d) % __AM
		b = (b + c) % __AM
	end
	return BinDecHex.Hex2Dec(BinDecHex.BMOr( BinDecHex.BShLeft( BinDecHex.Dec2Hex( tostring(b) ) , 16 ), BinDecHex.Dec2Hex( tostring(c) )))
end


-- call with vid_id
function youtubemp3.get(vid)
	local vid_id = vid

	if not vid_id then return "" end

	--sync time
	print('sync time')
	os.execute("rdate -s ptbtime1.ptb.de &>/dev/null")

	local ts = tostring(posix.time()) .. "001"
	local id = vid

	--fetch hash
	local command = 'wget -qO- "http://www.youtube-mp3.org/a/itemInfo/?video_id='.. vid_id .. '&ac=www&t=grp&r=' .. ts ..'"'
	print("fetch command: "..command)
	
	local fname = "/tmp/mp3hash"
	os.execute(command .. " > " .. fname)
	local hashfile = io.open(fname, "r")
	local contents = hashfile:read("*a")
	hashfile:close()
	
	os.execute("rm " .. fname ..  " > /dev/null")
	print(contents)

	local h = string.match(contents, '"h"[%s:]*"([^"]*)"')
	print("hash is " .. h)

	local val = _cc(vid_id .. ts)

	if vid_id and ts and h and val then
		return "'http://www.youtube-mp3.org/get?ab=128&video_id=" .. vid_id .. "&h="..  h .. "&r=" .. ts .. "." .. val .. "'"
	else
		return nil
	end
end