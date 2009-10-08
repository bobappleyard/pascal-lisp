unit LispGC;

interface

implementation

const
  LibName = 'libgc';

function GCMalloc(Size: PtrInt): Pointer; cdecl; external LibName name 'GC_malloc';

type
  TByteArray = array [0 .. MaxInt] of Byte;
  PPtrInt = ^PtrInt;
  PByteArray = ^TByteArray;

function CMemSize(P: Pointer): PtrInt;
begin
  if P = nil then
  begin
    Result := 0;
  end
  else
  begin
    Dec(P, SizeOf(PtrInt));
    Result := PPtrInt(P)^;
  end;
end;

function Min(A, B: PtrInt): PtrInt;
begin
  if A > B then
  begin
    Result := B;
  end
  else
  begin
    Result := A;
  end;
end;

function CGetMem(Size: PtrInt): Pointer;
begin
  Result := GCMalloc(Size + SizeOf(PtrInt));
  if Result <> nil then
  begin
    PPtrInt(Result)^ := Size;
    Inc(Result, SizeOf(PtrInt));
  end;
end;

function CFreeMem(P: Pointer): PtrInt;
begin
  Result := 0;
end;

function CFreeMemSize(P: Pointer; Size: PtrInt): PtrInt;
begin
  Result := CFreeMem(P);
end;

function CAllocMem(Size: PtrInt): Pointer;
begin
  Result := CGetMem(Size);
end;

function CReAllocMem(var P: Pointer; Size: PtrInt): Pointer;
var
  I, C: Integer;
  Src, Dst: PByteArray;
begin
  if Size <> 0 then
  begin
    Result := CGetMem(Size);
    C := Min(Size, CMemSize(P)) - 1;
    Src := PByteArray(P);
    Dst := PByteArray(Result);
    for I := 0 to C do
    begin
      Dst[I] := Src[I];
    end;
    P := Result;
  end
  else
  begin
    Result := nil;
  end;
end;

function CGetHeapStatus:THeapStatus;
var 
  Res: THeapStatus;
begin
  FillChar(Res, SizeOf(Res), 0);
  Result := Res;
end;

function CGetFPCHeapStatus:TFPCHeapStatus;
var 
  Res: TFPCHeapStatus;
begin
  FillChar(Res, SizeOf(Res), 0);
  Result := Res;
end;

const
 GCMemoryManager : TMemoryManager =
    (
      NeedLock : false;
      GetMem : @CGetmem;
      FreeMem : @CFreeMem;
      FreememSize : @CFreememSize;
      AllocMem : @CAllocMem;
      ReallocMem : @CReAllocMem;
      MemSize : @CMemSize;
      GetHeapStatus : @CGetHeapStatus;
      GetFPCHeapStatus: @CGetFPCHeapStatus;
    );
var
  OldMemoryManager: TMemoryManager;

initialization
  GetMemoryManager (OldMemoryManager);
  SetMemoryManager (GCmemoryManager);

finalization
  SetMemoryManager (OldMemoryManager);

end.











