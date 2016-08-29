#!/usr/bin/lua

-- https://developers.google.com/youtube/2.0/developers_guide_protocol#Retrieving_and_searching_for_videos

require "socket"

local P = {}
youtubesearch = P

function youtubesearch.get(song)
	request = 
[[GET /feeds/api/videos?q=%s&max-results=1&orderby=relevance&v=2 HTTP/1.0
Host: gdata.youtube.com

]]

	author = song

	author = string.gsub(author, ' ', '+')
	-- print(author)

	conn = socket.tcp()
	conn:settimeout(20)
	print("DEBUG: "..string.format(request, author))
	assert(conn:connect("gdata.youtube.com", 80), "Can't connect to the Google Server")
	assert(conn:send(string.format(request, author)), "Can't send the data to the Google Server")
	response = assert(conn:receive("*a"), "No data received from Google Server")
	conn:shutdown()
	if response:sub(10, 15) ~= "200 OK" then
	        print(response)
	        error("Error?!")
	        os.exit()
	end
	response = assert(response:sub(response:find("\r\n\r\n"), -1), "Invalid response from Google Server")

	--print(response)

	local s, e, ss, ee = string.find(response, "media:player url='()[^\']*()\'")

	url = string.sub(response, ss, ee-1)
	return url
end