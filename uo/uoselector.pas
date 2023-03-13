unit uoselector;
interface
uses Windows, SysUtils, Classes, uoclidata, uoscanver;

type
  TUOSel        = class(TObject)
  private
    CliHWnd     : Cardinal;
    PHandle     : Cardinal;
  public
    CstDB       : TCstDB;
    constructor Create;
    procedure   Free;
    function    GetTitle(Nr : Cardinal) : String;
    function    GetPID(Nr : Cardinal) : Cardinal;
    function    GetVer(Nr : Cardinal) : String;
    function    SelectClient(Nr : Cardinal; Version : String = '') : Boolean;
    function    Cnt : Cardinal;
    function    Nr : Cardinal;
    function    Ver : String;
    function    ExePath : String;
    property    HWnd : Cardinal read CliHWnd;
    property    HProc : Cardinal read PHandle;
  end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
implementation

var
  WndList     : TStringList;
  VerList     : TStringList;
  RCS         : TMultiReadExclusiveWriteSynchronizer;
  Insts       : TList;
  ThreadHnd   : Cardinal;

////////////////////////////////////////////////////////////////////////////////
procedure TimerProc;
var
  Cnt    : Integer;
  Cnt2   : Integer;
  Wnd    : Cardinal;
  wList  : TStringList;
  vList  : TStringList;
  sBuf   : String;
begin
  wList:=TStringList.Create;
  wList.Sorted:=True;
  EnumWindows(@EnumCliWnd,Cardinal(wList));

  vList:=TStringList.Create;
  RCS.BeginWrite;
  vList.Assign(VerList);       // CS in case of UOSelUpdate reentrance!
  RCS.EndWrite;

  // Add new entries to version list
  for Cnt:=0 to wList.Count-1 do
  begin
    Wnd:=Cardinal(wList.Objects[Cnt]);
    for Cnt2:=0 to vList.Count-1 do
      if Cardinal(vList.Objects[Cnt2])=Wnd then Break;
    if Cnt2>=vList.Count then
      vList.AddObject(ScanVer(Wnd),Pointer(Wnd));
  end;

  // Delete unused entries in version list
  for Cnt:=vList.Count-1 downto 0 do
  begin
    Wnd:=Cardinal(vList.Objects[Cnt]);
    if wList.IndexOf(IntToStr(Wnd))<0 then
      vList.Delete(Cnt);
  end;

  // Local window and version lists are synced now!

  // Delete unsupported clients in window list
  sBuf:=UpperCase(SupportedCli)+',';
  for Cnt:=0 to vList.Count-1 do
  begin
    if Pos(' '+UpperCase(vList[Cnt])+' ',sBuf)>0 then Continue;
    Wnd:=Cardinal(vList.Objects[Cnt]);
    if wList.Find(IntToStr(Wnd),Cnt2) then // Always successful
      wList.Delete(Cnt2);
  end;

  RCS.BeginWrite;
  VerList.Free;
  WndList.Free;
  VerList:=vList;
  WndList:=wList;
  for Cnt:=0 to Insts.Count-1 do // Refresh all UOSel objects!
    TUOSel(Insts[Cnt]).Nr; // CS recursion!
  RCS.EndWrite;
end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

constructor TUOSel.Create;
begin
  inherited Create;
  CstDB:=TCstDB.Create;
  CliHWnd:=0;
  PHandle:=0;
  RCS.BeginWrite;
  Insts.Add(self);
  RCS.EndWrite;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TUOSel.Free;
begin
  RCS.BeginWrite;
  Insts.Delete(Insts.IndexOf(self));
  RCS.EndWrite;
  CstDB.Free;
  inherited Free;
end;

////////////////////////////////////////////////////////////////////////////////
function TUOSel.GetTitle(Nr : Cardinal) : String;
var
  Buf : array[0..255] of Char;
begin
  RCS.BeginRead;
  Result:='';
  if (Nr<=WndList.Count)and(Nr>0) then
  begin
    GetWindowText(StrToInt(WndList[Nr-1]),@Buf,255);
    Result:=PChar(@Buf);
  end;
  RCS.EndRead;
end;

////////////////////////////////////////////////////////////////////////////////
function TUOSel.GetPID(Nr : Cardinal) : Cardinal;
begin
  RCS.BeginRead;
  Result:=0;
  if (Nr<=WndList.Count)and(Nr>0) then
    GetWindowThreadProcessID(StrToInt(WndList[Nr-1]),@Result);
  RCS.EndRead;
end;

////////////////////////////////////////////////////////////////////////////////
function TUOSel.GetVer(Nr : Cardinal) : String;
var
  Cnt : Integer;
begin
  RCS.BeginRead;
  Result:='';
  if (Nr<=WndList.Count)and(Nr>0) then
  begin
    for Cnt:=0 to VerList.Count-1 do
      if VerList.Objects[Cnt]=WndList.Objects[Nr-1] then
    begin
      Result:=VerList[Cnt];
      Break;
    end;
  end;
  RCS.EndRead;
end;

////////////////////////////////////////////////////////////////////////////////
function TUOSel.SelectClient(Nr : Cardinal; Version : String = '') : Boolean;
begin
  RCS.BeginRead;
  repeat
    if (Nr>WndList.Count)or(Nr=0) then Break;
    CliHWnd:=StrToInt64(WndList[Nr-1]);
    GetWindowThreadProcessID(CliHWnd,PHandle);
    PHandle:=OpenProcess(PROCESS_ALL_ACCESS,False,PHandle);
    if PHandle=0 then Break;
    if Version='' then CstDB.Update(Ver)
    else CstDB.Update(Version);
    Result:=True;
    RCS.EndRead;
    Exit;
  until True;
  RCS.EndRead;
  CliHWnd:=0;
  PHandle:=0;
  CstDB.Update('');
  Result:=False;
end;

////////////////////////////////////////////////////////////////////////////////
function TUOSel.Cnt : Cardinal;
begin
  RCS.BeginRead;
  Result:=WndList.Count; //WndList might get freed and reassigned meanwhile!
  RCS.EndRead;
end;

////////////////////////////////////////////////////////////////////////////////
function TUOSel.Nr : Cardinal;
begin
  RCS.BeginRead;
  Result:=WndList.IndexOf(IntToStr(CliHWnd))+1;
  RCS.EndRead;
  if Result>0 then Exit;
  if PHandle>0 then
    CloseHandle(PHandle);
  CliHWnd:=0;
  PHandle:=0;
end;

////////////////////////////////////////////////////////////////////////////////
function TUOSel.Ver : String;
begin
  Result:=GetVer(Nr);
end;

////////////////////////////////////////////////////////////////////////////////
function TUOSel.ExePath : String;
begin
  Result:=GetExePath(PHandle);
end;

////////////////////////////////////////////////////////////////////////////////
function TimerThread(Parameter : Pointer) : Integer;
begin
  repeat
    Sleep(100);
    TimerProc;
  until False;
end;

////////////////////////////////////////////////////////////////////////////////
initialization
  WndList:=TStringList.Create;
  VerList:=TStringList.Create;
  Insts:=TList.Create;
  RCS:=TMultiReadExclusiveWriteSynchronizer.Create;
  TimerProc;
  ThreadHnd:=BeginThread(nil,0,@TimerThread,nil,0,ThreadHnd);
finalization
  TerminateThread(ThreadHnd,0);
  CloseHandle(ThreadHnd);
  RCS.Free;
  Insts.Free;
  VerList.Free;
  WndList.Free;
end.
