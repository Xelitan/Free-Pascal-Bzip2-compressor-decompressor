# Free Pascal port of Bzip2

Original C code:
bzip2 / libbzip2 1.1.0 (Julian Seward)
https://sourceware.org/bzip2/

Pascal port: 
https://github.com/joaopauloschuler/pas-bzip2

# What's new?

This repo includes additional pascal classes.

# License 
BSD-style. See LICENSE

# High level classes

```
procedure BZ2CompressStream(InStream, OutStream: TStream; BlockSize100k: Integer = 9; WorkFactor: Integer = 0);
procedure BZ2DecompressStream(InStream, OutStream: TStream);
```
