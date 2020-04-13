local bit = require "bit"
local byte = string.byte
local char = string.char
local sub = string.sub
local band = bit.band
local bor = bit.bor 
local lshift = bit.lshift
local rshift = bit.rshift 

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 3)
 
_M._VERSION = '0.07'

local _PutInt32 = function (t_num)
    local blue = band(t_num, 0x000000ff) 
    local num = rshift(t_num, 8)
    local green = band(num, 0x000000ff) 
    local num = rshift(t_num, 16)
    local red = band(num, 0x000000ff) 
    local num = rshift(t_num, 24)
    local alpha = band(num, 0x000000ff)
 
    return char(alpha ,red, green, blue)
end

local _PutInt16 = function (t_num)
    local blue = band(t_num, 0xffff) 
    local num = rshift(t_num, 16)
    local green = band(num, 0xffff) 
    return char(green, blue)
end 

function _M:encode(op, body)
    local _packSize      = 4
	local _headerSize    = 2
	local _verSize       = 2
	local _opSize        = 4
	local _seqSize       = 4
	local _rawHeaderSize = _packSize + _headerSize + _verSize + _opSize + _seqSize
    local packLen = _rawHeaderSize + string.len(body)
     
    local p1 = _PutInt32(packLen)
    local p2 = _PutInt16(_rawHeaderSize)
    local p3 = _PutInt16(1)   --Ver
    local p4 = _PutInt32(op) --Op
    local p5 = _PutInt32(1) --Seq
    local buffer = p1 .. p2 .. p3 .. p4 .. p5 .. body 
    return buffer
end 


local int32 = function (alpha,red, green, blue) 
    local la = bor(0X00FFFFFF, lshift(alpha, 24))
    local lb = bor(0XFF00FFFF, lshift(red, 16)) 
    local lc = bor(0XFFFF00FF, lshift(green, 8))
    local ld = bor(0XFFFFFF00, blue) 
    local res = band(band(band(la, lb), lc),ld) 
    return res
end

local int16 = function (green, blue) 
    local la = bor(0X0000FFFF, lshift(green, 16))
    local lb = bor(0xFFFF0000, blue)
    local res = band(la, lb) 
    return res
end

function _M:decode(data)
    local alpha, red, green, blue

    local r1 = sub(data, 1, 4) 
    alpha, red, green, blue = byte(r1, 1, 4)
    local packLen = int32(alpha, red, green, blue)
 
    local r2 = sub(data, 5, 6)
    green, blue = byte(r2, 1, 2)
    local rawheadersize = int16(green, blue)
    
    local r3 = sub(data, 7, 8)
    green, blue = byte(r3, 1, 2)
    local ver = int16(green, blue)
      
    local r4 = sub(data, 9, 12)
    alpha, red, green, blue = byte(r4, 1, 4)
    local op = int32(alpha, red, green, blue)
    
    local r5 = sub(data, 13, 16)
    alpha, red, green, blue = byte(r5, 1, 4)
    local seq = int32(alpha, red, green, blue) 
    
    local body = sub(data, 17, -1)
    
    return packLen, rawheadersize, ver, op, seq, body
end


return _M