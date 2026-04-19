{$I pasbzip2.inc}
unit bzip2streams;

{
  TStream-based compress / decompress wrappers over the pure-Pascal bzip2 port.

  BZ2CompressStream   — reads plain data from InStream, writes bzip2 to OutStream
  BZ2DecompressStream — reads bzip2 from InStream, writes plain data to OutStream

  Both functions raise EBzip2Error on any library or I/O error.
}

interface

uses
  Classes, SysUtils, pasbzip2types, pasbzip2;

type
  EBzip2Error = class(Exception);

// Compress all bytes from InStream into bzip2 format, writing to OutStream.
// BlockSize100k : compression block size 1..9  (9 = best compression, default)
// WorkFactor    : fallback sort heuristic 1..250 (0 = library default = 30)
procedure BZ2CompressStream(InStream, OutStream: TStream;
  BlockSize100k: Integer = 9; WorkFactor: Integer = 0);

// Decompress a complete bzip2 stream from InStream, writing plain data to OutStream.
procedure BZ2DecompressStream(InStream, OutStream: TStream);

implementation

const
  BUF_SIZE = 65536;

// ---------------------------------------------------------------------------
// BZ2CompressStream
// ---------------------------------------------------------------------------
procedure BZ2CompressStream(InStream, OutStream: TStream;
  BlockSize100k: Integer = 9; WorkFactor: Integer = 0);
var
  strm   : Tbz_stream;
  ret    : Int32;
  inBuf  : array[0..BUF_SIZE - 1] of Byte;
  outBuf : array[0..BUF_SIZE - 1] of Byte;
  nRead  : Integer;
  nOut   : Integer;
begin
  FillChar(strm, SizeOf(strm), 0);

  ret := BZ2_bzCompressInit(@strm, BlockSize100k, 0, WorkFactor);
  if ret <> BZ_OK then
    raise EBzip2Error.CreateFmt('BZ2CompressStream: init failed (code %d)', [ret]);

  try
    // --- BZ_RUN phase: feed all input ---
    nRead := InStream.Read(inBuf[0], BUF_SIZE);
    while nRead > 0 do
    begin
      strm.next_in  := PChar(@inBuf[0]);
      strm.avail_in := UInt32(nRead);

      // Drain this chunk completely before reading more input.
      while strm.avail_in > 0 do
      begin
        strm.next_out  := PChar(@outBuf[0]);
        strm.avail_out := BUF_SIZE;

        ret := BZ2_bzCompress(@strm, BZ_RUN);
        if ret <> BZ_RUN_OK then
          raise EBzip2Error.CreateFmt(
            'BZ2CompressStream: BZ2_bzCompress(BZ_RUN) failed (code %d)', [ret]);

        nOut := BUF_SIZE - Int32(strm.avail_out);
        if nOut > 0 then
          OutStream.Write(outBuf[0], nOut);
      end;

      nRead := InStream.Read(inBuf[0], BUF_SIZE);
    end;

    // --- BZ_FINISH phase: flush internal buffers ---
    strm.next_in  := nil;
    strm.avail_in := 0;
    repeat
      strm.next_out  := PChar(@outBuf[0]);
      strm.avail_out := BUF_SIZE;

      ret := BZ2_bzCompress(@strm, BZ_FINISH);
      if (ret <> BZ_FINISH_OK) and (ret <> BZ_STREAM_END) then
        raise EBzip2Error.CreateFmt(
          'BZ2CompressStream: BZ2_bzCompress(BZ_FINISH) failed (code %d)', [ret]);

      nOut := BUF_SIZE - Int32(strm.avail_out);
      if nOut > 0 then
        OutStream.Write(outBuf[0], nOut);
    until ret = BZ_STREAM_END;

  finally
    BZ2_bzCompressEnd(@strm);
  end;
end;

// ---------------------------------------------------------------------------
// BZ2DecompressStream
// ---------------------------------------------------------------------------
procedure BZ2DecompressStream(InStream, OutStream: TStream);
var
  strm   : Tbz_stream;
  ret    : Int32;
  inBuf  : array[0..BUF_SIZE - 1] of Byte;
  outBuf : array[0..BUF_SIZE - 1] of Byte;
  nRead  : Integer;
  nOut   : Integer;
begin
  FillChar(strm, SizeOf(strm), 0);

  ret := BZ2_bzDecompressInit(@strm, 0, 0);
  if ret <> BZ_OK then
    raise EBzip2Error.CreateFmt('BZ2DecompressStream: init failed (code %d)', [ret]);

  try
    ret := BZ_OK;
    while ret <> BZ_STREAM_END do
    begin
      // Refill input buffer only when the library has consumed everything.
      if strm.avail_in = 0 then
      begin
        nRead := InStream.Read(inBuf[0], BUF_SIZE);
        if nRead = 0 then
          raise EBzip2Error.Create(
            'BZ2DecompressStream: unexpected end of compressed data');
        strm.next_in  := PChar(@inBuf[0]);
        strm.avail_in := UInt32(nRead);
      end;

      strm.next_out  := PChar(@outBuf[0]);
      strm.avail_out := BUF_SIZE;

      ret := BZ2_bzDecompress(@strm);
      if (ret <> BZ_OK) and (ret <> BZ_STREAM_END) then
        raise EBzip2Error.CreateFmt(
          'BZ2DecompressStream: BZ2_bzDecompress failed (code %d)', [ret]);

      nOut := BUF_SIZE - Int32(strm.avail_out);
      if nOut > 0 then
        OutStream.Write(outBuf[0], nOut);
    end;

  finally
    BZ2_bzDecompressEnd(@strm);
  end;
end;

end.
