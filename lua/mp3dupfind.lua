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



local lfs = require"lfs"
local mp3 = require"mp3fingerprint"

local f = arg[1] or "."
if not f or lfs.attributes(f, 'mode') ~= 'directory' then
  print "usage: mp3dupfind directory"
  return
end

local function fname(path)
   return path:match("[^/]+$")
end  
  
local dupes = 0
local songs = 0
local function tabdir (path, t)
 
  for file in lfs.dir(path) do
    if file ~= "." and file ~= ".." and string.sub(file, 1, 1) ~= "." then
      local f = path..'/'..file
      local attr = lfs.attributes(f)
      
      if attr.mode == "directory" then
        tabdir(f, t)
      else
        if attr.size > 0 and f:sub(-3) == "mp3" then
          songs = songs + 1
          local fprint = mp3.fingerprint(f, 1024 * 1024)
          if t.files[fprint] then
            -- push both files to 'duplicates' list for second-pass check
            if not t.duplicates[fprint] then
              t.duplicates[fprint] = { t.files[fprint] }
            end
            table.insert(t.duplicates[fprint], f)
            dupes = dupes + 1
          else
            t.files[fprint] = f
          end
        end
      end
    end
  end
  return t
end

local function scan(path)
  local t = tabdir(path, { path = path, files = {}, duplicates = {} })
  return t
end

local res = scan(f)
for _, set in pairs(res.duplicates) do
    print("Duplicate found:")
    for i,f in pairs(set) do
      print('\t'..i,f)
    end
    print()
end
print(string.format("Found %d dupes out of %d songs (%f%%)", dupes, songs, dupes/songs*100))
