#!/usr/bin/lua

local P={}
goog_speech_parse=P

function goog_speech_parse.parse(response)
	-- sample result
	-- {"status":0,"id":"","hypotheses":[{"utterance":"youtube","confidence":0.52547479}]}
	if type(response) ~= "string" then
		return nil
	end
	local hypotheses={}
	local num = 0
	local tempa, tempb, hypotheses_start, hypotheses_end=string.find(response, "hypotheses\":()%[.*()]")
	if hypotheses_start ~= nil then
		local begin = hypotheses_start
		while true do
			local a, b, c = string.find(response, "(){.", begin)
			if c ~= nil then
				local a, b, d = string.find(response, "()}[,%]]", c)
				if d ~= nil then
					--print(string.sub(response, c, d))
					begin = d

					local aa, bb, cc= string.find(response, "()\"", c)
					local aa, bb, dd, ee = string.find(response, "(),()", cc)
					local utterance = string.sub(response, cc, dd-1)
					local confidence = string.sub(response, ee, d-1)
					aa, bb, cc = string.find(utterance, ":\"()")
					utterance = string.sub(utterance, cc, -2)

					aa, bb, cc = string.find(confidence, ":()")
					confidence = string.sub(confidence, cc, -2)
					
					num = num+1
					hypotheses[num] = {}
					hypotheses[num].utterance = utterance
					hypotheses[num].confidence = tonumber(confidence)
				else
					break
				end
			else
				break
			end
		end
	else
		hypotheses = nil
	end

	return num, hypotheses
end

function goog_speech_parse.get(response)
	local n,r = goog_speech_parse.parse(response)
	if n == 0 then
		return nil
	end
	
	local best = {utterance=nil, confidence=nil}

	local i=n
	while i>0 do
		--print("Uttered "..r[i].utterance.." with confidence ".. r[i].confidence)
		if best.confidence == nil or best.confidence < r[i].confidence then
			best.utterance  = r[i].utterance
			best.confidence = r[i].confidence
		end
		i=i-1
	end

	if best.utterance ~= nil then
		return best
	else
		return nil
	end
end

--[[
local a= '{"status":0,"id":"","hypotheses":[{"utterance":"youtube","confidence":0.52547479},{"utterance":"google","confidence":0.12547479}]}'

local n,r = goog_speech_parse.parse(a)
print(n)
local i = n
while  i > 0 do
	print("Uttered "..r[i].utterance.." with confidence ".. (r[i].confidence*100)..'%')
	i=i-1
end
print('')

a= '{"status":0,"id":"","hypotheses":[{"utterance":"youtube","confidence":0.52547479}]}'
local n,r = goog_speech_parse.parse(a)
print(n)
local i=n
while i>0 do
	print("Uttered "..r[i].utterance.." with confidence ".. (r[i].confidence*100)..'%')
	i=i-1
end
--]]

return goog_speech_parse