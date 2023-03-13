unit uoxloader;
interface
uses Registry, Windows, SysUtils, ExtCtrls, uoselector, rwaccess;

type
  TUOXL         = class(TObject)
  private
    PID         : Cardinal;
    Timer       : TTimer;
    TSel        : TUOSel;
    TOut        : Cardinal;
    TCnt        : Cardinal;
    procedure   PIDCheck(Sender : TObject);
  public
    constructor Create;
    procedure   Free;
    function    GetUOClient : String;
    function    GetUOPath : String;
    function    LoadReg  : Boolean;
    function    LoadPath(Path : String) : Boolean;
    procedure   SwitchToLoaded(UOSel : TUOSel; SecTimeout : Cardinal);
  end;

implementation

////////////////////////////////////////////////////////////////////////////////

type
  TScanStr = record
    Str      : String;
    Offs     : Integer;
    Joker    : Char;
  end;

const
  Check1Pos : TScanStr =
    (Str: #255#21#1#1#1#1#133#192#116#21#106#64; Offs: 6; Joker: #1);
    //Position of "test eax, eax" near the first <"FindWindowA">
  Check2_1Pos : TScanStr =
    (Str: #255#21#1#1#1#1#61#183#0#0#0#117#1+#83#104; Offs: 7; Joker: #1);
    //Position of "cmp eax, B7" below GetLastError <"UoClientApp">
  Check2_2Pos : TScanStr =
    (Str: #255#21#1#1#1#1#61#183#0#0#0#117#1+#139; Offs: 7; Joker: #1);
    //Position of "cmp eax, B7" below GetLastError <"UoClientApp">
  CacheFixPos : TScanStr =
    (Str: #3#243#164#232#1#1#1#1#133#192#117; Offs: 3; Joker: #1);
    // About 30 lines above ">2 god" (at the 1st call [which is identical with the 2nd call])
  DeleteFileCall : TScanStr =
    (Str: #195#255#116#36#4#255#21#1#1#1#1#133#192#117; Offs: 7; Joker: #1);
    // Vector on DeleteFile API
  GetLastErrorCall : TScanStr =
    (Str: #255#21#1#1#1#1#133#192#116#1#255#21#1#1#1#1#61#183; Offs: 12; Joker: #1);
    // Vector on GetLastError API
  CreateFileMappingACall : TScanStr =
    (Str: #106#0#106#0#106#0#106#2#106#0#80#255#21; Offs: 13; Joker: #1);
    // Vector on CreateFileMappingA API

////////////////////////////////////////////////////////////////////////////////

constructor TUOXL.Create;
begin
  inherited Create;
  Timer:=nil;
  PID:=0;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TUOXL.Free;
begin
  if Timer<>nil then Timer.Free;
  inherited Free;
end;

////////////////////////////////////////////////////////////////////////////////

function TUOXL.GetUOClient;
const
  UOKey   = '\Software\Origin Worlds Online\Ultima Online\1.0';
  UOEntry = 'ExePath';
var
  MyReg : TRegistry;
begin
  Result:='';

  MyReg:=TRegistry.Create;
  MyReg.RootKey:=HKEY_LOCAL_MACHINE;

  repeat
    if not MyReg.OpenKey(UOKey,False) then Break;
    if MyReg.GetDataType(UOEntry)<>rdString then Break;
    Result:=MyReg.ReadString(UOEntry);
  until True;

  MyReg.CloseKey;
  MyReg.Free;
end;

////////////////////////////////////////////////////////////////////////////////

function TUOXL.GetUOPath;
var
  sBuf : String;
  cBuf : Cardinal;
  Cnt  : Cardinal;
begin
  sBuf:=GetUOClient;

  cBuf:=1;
  for Cnt:=1 to Length(sBuf) do
    if sBuf[Cnt]='\' then cBuf:=Cnt;
  SetLength(sBuf,cBuf-1);

  Result:=sBuf;
end;

////////////////////////////////////////////////////////////////////////////////

function TUOXL.LoadReg : Boolean;
begin
  Result:=LoadPath(GetUOClient);
end;

////////////////////////////////////////////////////////////////////////////////

function TUOXL.LoadPath(Path : String) : Boolean;
var
  StartInf : TStartupInfo;
  ProcInf  : TProcessInformation;
  HProc    : Cardinal;
  cBuf     : Cardinal;
  cBuf2    : Cardinal;
  sBuf     : String;
  sBuf2    : String;
begin
  PID:=0;
  Result:=False;
  if not FileExists(Path) then Exit;

  ZeroMemory(@StartInf, sizeof(TStartupInfo));
  ZeroMemory(@ProcInf, sizeof(TProcessInformation));
  StartInf.cb         := sizeof(TStartupInfo);
  StartInf.dwFlags    := STARTF_USESHOWWINDOW ;
  StartInf.wShowWindow:= SW_SHOW;

  CreateProcess(
  {executable } @Path[1],
  {cmdline    } nil,
  {secuattrib } nil,
  {threadattr } nil,
  {inherhandle} False,
  {creatflags } CREATE_SUSPENDED,
  {environment} nil,
  {currentdir } @Copy(Path,1,Length(Path)-
                Length(StrPas(StrRScan(@Path[1],'\'))))[1],
  {startupinfo} StartInf,
  {processinfo} ProcInf );

  HProc:=ProcInf.HProcess;
  PID:=ProcInf.dwProcessId;

  /// Error Message Killer ////////////////////////////
  with Check1Pos do cBuf:=SearchMem(HProc,Str,Joker)+Offs;
  if cBuf>$FF then RWVar(HProc,Write,cBuf,#57,1);

  with Check2_1Pos do cBuf:=SearchMem(HProc,Str,Joker)+Offs;
  if cBuf>$FF then RWVar(HProc,Write,cBuf,#193,1)
  else begin
    with Check2_2Pos do cBuf:=SearchMem(HProc,Str,Joker)+Offs;
    if cBuf>$FF then RWVar(HProc,Write,cBuf,#193,1);
  end;

  /// Cache Fixer /////////////////////////////////////
  repeat
    with DeleteFileCall do cBuf:=SearchMem(HProc,Str,Joker)+Offs;
    if cBuf<$FF then Break;
    RWVar(HProc,Read,cBuf,@cBuf,4);
    sBuf:=#199#71#255#99#97#99#104#137#254#41#214#131#199#4+
      #199#71#255#101#48#46#117#199#71#3#111#0#0#0#86#255#21+
      NumStr(cBuf,4,True);

    with GetLastErrorCall do cBuf:=SearchMem(HProc,Str,Joker)+Offs;
    if cBuf<$FF then Break;
    RWVar(HProc,Read,cBuf,@cBuf,4);
    sBuf:=sBuf+#131#248#1#116#25#255#21+NumStr(cBuf,4,True)+
      #131#248#2#116#14#255#7#102#128#63#58#117#225#102#198+
      #7#97#235#219; //without pop+ret

    //GetTargetArea!
    with CacheFixPos do cBuf:=SearchMem(HProc,Str,Joker)+Offs;
    if cBuf<$FF then Break;

    //adding pop+ret
    SetLength(sBuf2,1000);
    RWVar(HProc,Read,cBuf,@sBuf2[1],Length(sBuf2));
    cBuf2:=Pos(#3#243#164,sBuf2);
    if cBuf2=0 then Break;
    Delete(sBuf2,1,cBuf2+2);
    cBuf2:=Pos(#195,sBuf2);
    if cBuf2=0 then Break;
    sBuf:=sBuf+Copy(sBuf2,1,cBuf2);

    //write!
    RWVar(HProc,Write,cBuf,@sBuf[1],Length(sBuf));
  until True;

  /// Windows 95/98/ME Filemap Sharer /////////////////
  {repeat
    with CreateFileMappingACall do cBuf:=SearchMem(HProc,Str,Joker)+Offs;
    if cBuf<$FF then Break;
    RWVar(HProc,Read,cBuf,@cBuf,4);         // cBuf = 5511DC
    RWVar(HProc,Read,cBuf,@cBuf2,4);        // Save vector
    RWVar(HProc,Write,$008000F8,@cBuf2,4);
    RWVar(HProc,Write,cBuf,#0#0#128#0,4);   // Overwrite vector
    sBuf:='AAUO'#0;                         // Store mapname counter
    RWVar(HProc,Write,$00800100,@sBuf[1],Length(sBuf));
    sBuf:=#184#0#1#128#0+          //mov eax, 00800100
          #137#68#36#24+           //mov [esp+18], eax
          #255#0+                  //inc [eax]
          #102#128#56#91+          //cmp byte ptr [eax], 5B
          #117#7+                  //jne 00800018
          #254#64#1+               //inc [eax+01]
          #102#198#0#65+           //mov byte ptr [eax], 41
          #88+                     //pop eax
          #163#252#0#128#0+        //mov [008000FC], eax
          #255#21#248#0#128#0+     //call [008000F8]
          #255#53#252#0#128#0+     //push [008000FC]
          #195;                    //ret
    RWVar(HProc,Write,$00800000,@sBuf[1],Length(sBuf));
  until True;}

  ResumeThread(ProcInf.hThread);
  Result:=True;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TUOXL.SwitchToLoaded(UOSel : TUOSel; SecTimeout : Cardinal);
begin
  if PID=0 then Exit;
  if Timer<>nil then
  begin
    Timer.Free;
    Timer:=nil;
  end;

  TCnt:=0;
  TSel:=UOSel;
  TOut:=SecTimeout*4;

  Timer:=TTimer.Create(nil);
  Timer.OnTimer:=PIDCheck;
  Timer.Interval:=250;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TUOXL.PIDCheck(Sender : TObject);
var
  Cnt : Integer;
begin
  TSel.Update;
  Inc(TCnt);

  for Cnt:=1 to TSel.Cnt do
    if TSel.GetPID(Cnt)=PID then
  begin
    TSel.SelectClient(Cnt);
    TCnt:=10000;
  end;

  if TCnt>TOut then
  begin
    Timer.Free;
    Timer:=nil;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
end.
