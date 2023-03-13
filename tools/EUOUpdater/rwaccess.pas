unit RWAccess;
interface
uses Windows;

const
  Read  = 0;
  Write = 1;

  function RWVar(PHandle : Cardinal; RW : Cardinal; MemPos : Cardinal; Buf : PChar; Length : Cardinal) : Boolean;
  function NumStr(DW : Cardinal; Size : Integer; Intel : Boolean) : String;
  function SearchMem(PHandle : Cardinal; ScanStr : String; Joker : Char) : Cardinal;

implementation

var
  MyReadProcessMemory  : function(hProcess: THandle; const lpBaseAddress: Pointer; lpBuffer: Pointer; nSize: Cardinal; var lpNumberOfBytesRead: Cardinal): Boolean; stdcall;
  MyWriteProcessMemory : function(hProcess: THandle; const lpBaseAddress: Pointer; lpBuffer: Pointer; nSize: Cardinal; var lpNumberOfBytesRead: Cardinal): Boolean; stdcall;

////////////////////////////////////////////////////////////////////////////////

function RWVar(PHandle : Cardinal; RW : Cardinal; MemPos : Cardinal; Buf : PChar; Length : Cardinal) : Boolean;
var
  Code : Cardinal;
  A,
  E,
  I    : Cardinal;
begin
  Result:=False;
  E:=Length;
  A:=0;
  I:=Length;

  if RW=Read then
  begin
    ZeroMemory(Buf,Length);

    repeat
      MyReadProcessMemory(PHandle,Pointer(MemPos),Buf,I,Code);

      if Code=0 then E:=I
      else begin
        A:=I;
        Result:=True;
      end;

      if E-A<2 then Break;

      I:=A+((E-A)div 2);
    until False;
  end;

  if RW=Write then
    Result:=MyWriteProcessMemory(PHandle,Pointer(MemPos),Buf,Length,Code);

end;

////////////////////////////////////////////////////////////////////////////////

function NumStr(DW : Cardinal; Size : Integer; Intel : Boolean) : String;
var
  sBuf : String;
  sCh  : Char;
begin
  SetLength(sBuf,Size);
  Move(DW,sBuf[1],Size);

  if not Intel then
  case Size of
    4 : begin
          sCh:=sBuf[1];
          sBuf[1]:=sBuf[4];
          sBuf[4]:=sCh;
          sCh:=sBuf[2];
          sBuf[2]:=sBuf[3];
          sBuf[3]:=sCh;
        end;
    2 : begin
          sCh:=sBuf[1];
          sBuf[1]:=sBuf[2];
          sBuf[2]:=sCh;
        end;
  end;

  Result:=sBuf;
end;

////////////////////////////////////////////////////////////////////////////////

function FindPos(PBuf, PScanStr : Pointer; BufLen, ScanLen : Cardinal; Joker : Byte) : Integer;
var
  RetVal : Integer;
label N1,N2,W1,W2,W3;
begin
  asm
    push  edi
    push  esi
    push  ebp
    push  ebx

    mov   eax, -1
    mov   edi, PBuf
    mov   ecx, 0

    mov   edx, edi
    add   edx, BufLen
    sub   edx, ScanLen

    N1:
    mov   esi, PScanStr
    sub   edi, ecx
    mov   ecx, 0

    cmp   edi, edx
    jg    W1

    N2:
    mov   bl, Joker
    cmp   [esi], bl
    jne   W3
    cmpsb
    jmp   W2
    W3:

    cmpsb
    jne   N1

    W2:
    inc   ecx
    cmp   ecx, ScanLen
    jne   N2

    sub   edi, ScanLen
    mov   eax, edi
    sub   eax, PBuf
    W1:
    mov   RetVal, eax

    pop   ebx
    pop   ebp
    pop   esi
    pop   edi
  end;
  FindPos:=RetVal;
end;

////////////////////////////////////////////////////////////////////////////////

function SearchMem(PHandle : Cardinal; ScanStr : String; Joker : Char) : Cardinal;
var
  Cnt  : Integer;
  Cnt2 : Integer;
  Buf  : Array[0..$3FFF] of Byte;
begin
  Cnt:=$00400000;
  Cnt2:=-1;
  repeat
    if not RWVar(PHandle,Read,Cnt,@Buf,$4000) then Break;
    Cnt2:=FindPos(@Buf,@ScanStr[1],$4000,Length(ScanStr),Byte(Joker));
    if Cnt2>-1 then Break;
    Cnt:=Cnt+$4000-Length(ScanStr)+1;
  until Cnt>$600000;
  Cnt:=Cnt+Cnt2;

  if Cnt2>-1 then Result:=Cnt
  else Result:=0;
end;

////////////////////////////////////////////////////////////////////////////////

var
  HMod    : Cardinal;
initialization
  HMod:=LoadLibrary('kernel32');
  MyReadProcessMemory:=GetProcAddress(HMod,'ReadProcessMemory');
  MyWriteProcessMemory:=GetProcAddress(HMod,'WriteProcessMemory');
finalization
  FreeLibrary(HMod);
end.
