program bzip2tool;

{
  bzip2tool — pack / unpack bzip2 files using pure-Pascal bzip2 library.

  Usage:
    bzip2tool -c <input>  <output>   compress input -> bzip2 output
    bzip2tool -d <input>  <output>   decompress bzip2 input -> output

  Both input and output are opened as TFileStream; all I/O goes through
  BZ2CompressStream / BZ2DecompressStream from the bzip2streams unit.
}

{$APPTYPE CONSOLE}
{$I pasbzip2.inc}

uses
  SysUtils,
  Classes,
  bzip2streams;

// ---------------------------------------------------------------------------
procedure ShowUsage;
begin
  WriteLn('bzip2tool — compress / decompress bzip2 files');
  WriteLn;
  WriteLn('  bzip2tool -c <input> <output>   compress');
  WriteLn('  bzip2tool -d <input> <output>   decompress');
  Halt(1);
end;

// ---------------------------------------------------------------------------
var
  Mode       : string;
  InputFile  : string;
  OutputFile : string;
  InStream   : TFileStream;
  OutStream  : TFileStream;
  SizeIn     : Int64;
  SizeOut    : Int64;
begin
  if ParamCount <> 3 then
    ShowUsage;

  Mode       := ParamStr(1);
  InputFile  := ParamStr(2);
  OutputFile := ParamStr(3);

  if (Mode <> '-c') and (Mode <> '-d') then
    ShowUsage;

  InStream  := nil;
  OutStream := nil;
  try
    try
      InStream  := TFileStream.Create(InputFile,  fmOpenRead  or fmShareDenyWrite);
      OutStream := TFileStream.Create(OutputFile, fmCreate);
    except
      on E: Exception do
      begin
        WriteLn('Error opening files: ', E.Message);
        Halt(2);
      end;
    end;

    SizeIn := InStream.Size;

    try
      if Mode = '-c' then
      begin
        Write('Compressing  ', InputFile, '  ->  ', OutputFile, ' ... ');
        BZ2CompressStream(InStream, OutStream);
      end
      else
      begin
        Write('Decompressing  ', InputFile, '  ->  ', OutputFile, ' ... ');
        BZ2DecompressStream(InStream, OutStream);
      end;
    except
      on E: EBzip2Error do
      begin
        WriteLn;
        WriteLn('bzip2 error: ', E.Message);
        Halt(3);
      end;
    end;

    SizeOut := OutStream.Size;
    WriteLn('done.');
    WriteLn('  Input  : ', SizeIn,  ' bytes');
    WriteLn('  Output : ', SizeOut, ' bytes');
    if (Mode = '-c') and (SizeIn > 0) then
      WriteLn(Format('  Ratio  : %.1f%%', [SizeOut / SizeIn * 100.0]));

  finally
    FreeAndNil(OutStream);
    FreeAndNil(InStream);
  end;
end.
