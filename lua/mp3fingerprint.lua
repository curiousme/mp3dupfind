--[[
   Copyright (C) 2014 Mr. Curious <hello mrcurious.me>
   
   Permission is hereby granted, free of charge, to any person obtaining a copy
   of  this  software  and  associated documentation files (the "Software"), to
   deal  in  the Software without restriction, including without limitation the
   rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or
   sell  copies  of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:
  
   The  above  copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.
  
   THE  SOFTWARE  IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED,  INCLUDING  BUT  NOT  LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS  OR  COPYRIGHT  HOLDERS  BE  LIABLE  FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY,  WHETHER  IN  AN  ACTION  OF CONTRACT, TORT OR OTHERWISE, ARISING
   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
   IN THE SOFTWARE. 
--]]

--[[
  MP3 Fingerprint
  
  Creates a hash of the first megabyte of music. Skips ID3 tag and looks
  for the beginning of the first mp3 frame.
    
  Hashing less than 256k might cause false positives. Hashing 1MB has proven
  to work okay on a sample of several tens of thousands of files.
--]]

local function fingerprint(path, fplength)
  require"vendor.sha1"
  
  local FINGERPRINT_LEN = 1024 * 1024
  local sb = string.byte
  local A = bit.band
  
  fplength = fplength or FINGERPRINT_LEN

  local function read_int(inp, shift)
    local mul = shift and 2 ^ shift or 256
    
    local out = sb(inp, 1)
    for i = 2,#inp do
      out = out * mul + sb(inp, i)
    end
    return out 
  end
  
  local function id3_header_len(s)
    if string.sub(s, 1, 3) == "ID3" then
      return read_int(s:sub(7,10), 7)
    else
      return 0
    end
  end
  
  local function head(path, length)
    local file = assert(io.open(path, "rb"))
    local h = file:read(length)
    local start = id3_header_len(h)
    if start > 0 then start = start + 10 end
    if start >= length then
      -- HACK: It would possibly be more efficient to read the next chunk and somehow append it 
      -- to what was already read, but I don't know how to do that efficiently
      file:seek('set', 0)
      h = file:read(start + length)
    end
    file:close()
    return string.sub(h, start, -1)
  end
    
  -- Look for the first frame sync
  local function byte_reader(str)
    return function (i)
      return sb(str, i)
    end
  end
  
  -- header structure described at http://www.mpgedit.org/mpgedit/mpeg_format/mpeghdr.htm
  local function is_frame_sync(b, i)
    return b(i) == 0xff 
      and A(b(i+1), 0xe0) == 0xe0 -- sync must have first 11 bits set 
      and A(b(i+1), 0x18) ~= 0x08 -- version 01 is not valid
      and A(b(i+1), 0x06) ~= 0x00 -- layer 00 is reserved
      and A(b(i+2), 0xf0) ~= 0xf0 -- bitrate index 15 is invalid
      and A(b(i+2), 0x0c) ~= 0x0c -- sampling rate index 3 is reserved
      and (A(b(i+3), 0xc0)~=0x40 and A(b(i+3),0x30)==0 or A(b(i+3),0xc0) == 0x40) -- mode extension bits only apply if channel mode is joint stereo
      and A(b(i+3), 0x03) ~= 0x02 -- emphasis value 2 is reserved
  end
  
  local function frame_chunk(s, start, ln)
    return string.sub(s, start, start + ln)
  end
  
  local rest = head(path, fplength)
  local b = byte_reader(rest)
  local id = 0
    
  for i = 1,#rest-4 do
    if is_frame_sync(b, i) then
      id = sha1.hash(frame_chunk(rest, i, fplength), true)
      break
    end
  end  
  
  return id
end

local function hex_string(bytes)
  for i = 1,#bytes do
    io.write(string.format("%02x ", (bytes[i])))
    if i %  8 == 0 then io.write("  ") end
    if i % 64 == 0 then print() end
  end
end

local function hex(s, l)
  l = l or -1
  return hex_string{string.byte(s, 1, l)}
end


if not _G.package.loaded[...] then
  -- When running standalone
  -- When running standalone
  local lfs = require"lfs"
  local f = arg[1] or "."
  if not f or lfs.attributes(f, 'mode') ~= 'file' then
    print "usage: mp3fingerprint file"
    return
  end
  print(fingerprint(f))
else
  -- When required
  return  {
    fingerprint = fingerprint,
    hex = hex
  }
end