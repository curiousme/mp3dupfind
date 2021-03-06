mp3dupfind
==========

Find duplicate mp3 files

Mr. Curious needed to merge iTunes libraries from a few computers, and was annoyed by the lack of a simple and quick tool to deduplicate a collection of mp3 files. He decided to use the task as a learning project to practice new programming languages, notably Lua.

The repository contains a lua implementation, tested only with luajit on OS X 10.9.

## How Does it Work

The mp3finder iterates through folders and hashes first megabyte of mp3 frames. Each file's hash is compared to a list of existing hashes. If an existing hash already exists, both existing and new file are added to a list of duplicates. Otherwise, the file's hash is added to the lookup table.

### Skipping ID3 Tag

Since one might have changed the ID3 tag of a song, the fingerprint is calculated starting from the first frame of mp3 music, skipping the ID3 tag if it exists. One megabyte of music had proven to be enough to find duplicates; hashing less than 256k causes false positives if songs begin with silence, especially if encoded with LAME.

Skipping the ID3 tag requires only identifying the first three bytes as `ID3`, and then reading the length of the tag encoded as 32-bit [synchsafe integer](http://en.wikipedia.org/wiki/Synchsafe).

All versions of ID3 tag use the same method to encode the tag length. The tag structure for ID3v2.4.0 is described at [id3.org](http://id3.org/id3v2.4.0-structure).

### Hash From The First Frame

Some songs might have junk data after the length of the ID3 tag. The algorithm seeks the start of an mp3 frame by looking for a valid four-byte frame start marker. This is almost always reliable, thought it might get tripped here and there by junk data. This is not a problem in practice, since we presume that all duplicates of the file will have the same junk after the ID3 tag, and the hashing will start at the same place in all copies of the file.
 
The header structure is described at [MPGEdit site](http://www.mpgedit.org/mpgedit/mpeg_format/mpeghdr.htm).