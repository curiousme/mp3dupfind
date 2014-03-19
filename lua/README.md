# mp3dupfind/lua

A quick and simple duplicate mp3 file finder. 

## How to Use

Run mp3dupfind with luajit on a folder of music. It will return a list of path to duplicate files.

    luajit mp3dupfind.lua <folder>


## How Does it Work

The mp3finder iterates through folders and hashes first megabyte of mp3 frames. Each file's hash is compared to a list of existing hashes. If an existing hash already exists, both existing and new file are added to a list of duplicates. Otherwise, the file's hash is added to the lookup table.

### Skipping ID3 Tag

Since one might have changed the ID3 tag of a song, the fingerprint is calculated starting from the first frame of mp3 music, skipping the ID3 tag if it exists. One megabyte of music had proven to be enough to find duplicates; hashing less than 256k causes false positives if songs begin with silence, especially if encoded with LAME.

Skipping the ID3 tag requires only identifying the first three bytes as `ID3`, and then reading the length of the tag encoded as 32-bit [synchsafe integer](http://en.wikipedia.org/wiki/Synchsafe).

      local function id3_header_len(s)
        if string.sub(s, 1, 3) == "ID3" then
          return read_int(s:sub(7,10), 7)
        else
          return 0
        end
      end

All versions of ID3 tag use the same method to encode the tag length. The tag structure for ID3v2.4.0 is described at [id3.org](http://id3.org/id3v2.4.0-structure).

### Hash From The First Frame

Some songs might have junk data after the length of the ID3 tag. The algorithm seeks the start of an mp3 frame by looking for a valid four-byte frame start marker. This is almost always reliable, thought it might get tripped here and there by junk data. This is not a problem in practice, since we presume that all duplicates of the file will have the same junk after the ID3 tag, and the hashing will start at the same place in all copies of the file.

      local A = bit.band

      local function is_frame_sync(b, i)
        return b(i) == 0xff 
          and A(b(i+1), 0xe0) == 0xe0 -- sync must have first 11 bits set 
          and A(b(i+1), 0x18) ~= 0x08 -- version 01 is not valid
          and A(b(i+1), 0x06) ~= 0x00 -- layer 00 is reserved
          and A(b(i+2), 0xf0) ~= 0xf0 -- bitrate index 15 is invalid
          and A(b(i+2), 0x0c) ~= 0x0c -- sampling rate index 3 is reserved
          and (A(b(i+3), 0xc0)~=0x40 
              and A(b(i+3),0x30)==0 
              or A(b(i+3),0xc0) == 0x40) -- mode extension bits only apply if channel mode is joint stereo
          and A(b(i+3), 0x03) ~= 0x02 -- emphasis value 2 is reserved
      end
 
The header structure is described at [MPGEdit site](http://www.mpgedit.org/mpgedit/mpeg_format/mpeghdr.htm). 