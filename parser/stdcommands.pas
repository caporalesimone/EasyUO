unit stdcommands;
interface
uses SysUtils, Windows, Messages, ShellApi, MMSystem, Registry, Classes;

type
  TDelayFunc    = function(Duration : Cardinal) : Boolean of object;
  TStdCmd       = class(TObject)
  private
    Delay       : TDelayFunc;
    function    GetVK(KeyStr : String) : Cardinal;
  public
    DispRes     : String;

    constructor Create(DFunc : TDelayFunc);
    procedure   Wait(Duration, RandHi : Cardinal);
    function    OnHotkey(KeyStr : String; Ctrl,Alt,Shift : Boolean) : Boolean;
    procedure   Shutdown(Force : Boolean = False);
    function    Execute(App,Par : String; Show : Boolean; TimeOut : Cardinal = 0) : Boolean;
    procedure   SoundProc(SndFile : String = '');

    function    GetPix(Wnd : Cardinal; X,Y : Cardinal) : Cardinal;
    function    Display(Wnd : Cardinal; Str : String; MsgType : String; Dollar : Boolean = True) : String;
    function    GetCliTitle(Wnd : Cardinal) : String;
    procedure   SetCliTitle(Wnd : Cardinal; Title : String);
  end;

implementation
uses conversion;

////////////////////////////////////////////////////////////////////////////////
constructor TStdCmd.Create(DFunc : TDelayFunc);
begin
  Delay:=DFunc;
  DispRes:='';
end;

////////////////////////////////////////////////////////////////////////////////
procedure TStdCmd.Wait(Duration, RandHi : Cardinal);
begin
  Delay(Duration+Random(RandHi));
end;

////////////////////////////////////////////////////////////////////////////////
function TStdCmd.GetVK(KeyStr : String) : Cardinal;
const
  HKStr : Array[0..22] of String = (
    'F10','F11','F12','ESC','BACK','TAB','ENTER','PAUSE','CAPSLOCK','SPACE',
    'PGUP','PGDN','END','HOME','LEFT','RIGHT','UP','DOWN','PRNSCR','INSERT',
    'DELETE','NUMLOCK','SCROLLLOCK');
  HKVK : Array[0..22] of Cardinal = (
    VK_F10,VK_F11,VK_F12,VK_ESCAPE,VK_BACK,VK_TAB,VK_RETURN,VK_PAUSE,
    VK_CAPITAL,VK_SPACE,VK_PRIOR,VK_NEXT,VK_END,VK_HOME,VK_LEFT,VK_RIGHT,
    VK_UP,VK_DOWN,VK_SNAPSHOT,VK_INSERT,VK_DELETE,VK_NUMLOCK,VK_SCROLL);
var
  Cnt : Integer;
begin
  Result:=0;
  KeyStr:=UpperCase(KeyStr);
  if Length(KeyStr)=1 then
    if KeyStr[1] in ['A'..'Z','0'..'9'] then
      Result:=Byte(KeyStr[1]);
  if Length(KeyStr)=2 then
    if (KeyStr[1]='F')and(KeyStr[2] in ['1'..'9']) then
      Result:=Byte(VK_F1+Byte(KeyStr[2])-49);
  if Result=0 then
    for Cnt:=0 to High(HKStr) do
      if KeyStr=HKStr[Cnt] then
        Result:=HKVK[Cnt];
end;

////////////////////////////////////////////////////////////////////////////////
function TStdCmd.OnHotkey(KeyStr : String; Ctrl,Alt,Shift : Boolean) : Boolean;
var
  VK       : Cardinal;
begin
  Result:=False;
  VK:=GetVK(KeyStr);
  if VK=0 then Exit;

  if (Hi(GetAsyncKeyState(VK))<128) then Exit;
  if Ctrl xor (Hi(GetAsyncKeyState(VK_CONTROL))>127) then Exit;
  if Alt xor (Hi(GetAsyncKeyState(VK_MENU))>127) then Exit;
  if Shift xor (Hi(GetAsyncKeyState(VK_SHIFT))>127) then Exit;
  Result:=True;
end;

////////////////////////////////////////////////////////////////////////////////
function TStdCmd.Execute(App,Par : String; Show : Boolean; TimeOut : Cardinal = 0) : Boolean;
var
  Info   : ShellExecuteInfoA;
begin
  Info.cbSize:=SizeOf(ShellExecuteInfoA);
  Info.fMask:=SEE_MASK_DOENVSUBST or SEE_MASK_NOCLOSEPROCESS;
  Info.Wnd:=0;
  Info.lpVerb:='open';
  Info.lpFile:=PChar(App);
  Info.lpParameters:=PChar(Par);
  Info.lpDirectory:='';
  Info.nShow:=SW_SHOW*Byte(Show)+SW_HIDE*Byte(not Show);
  ShellExecuteEx(@Info);

  Result:=Info.hInstApp>32;
  if not Result then Exit;

  if TimeOut>0 then
    Result:=WaitForSingleObject(Info.hProcess,TimeOut)<>WAIT_FAILED;
  CloseHandle(Info.hProcess);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TStdCmd.Shutdown(Force : Boolean = False);
var
  hTokenHandle : Cardinal;
  PrivLUID     : Int64;
  TokenPriv    : TOKEN_PRIVILEGES;
  tkpDummy     : TOKEN_PRIVILEGES;
  lDummy       : Cardinal;
begin
  OpenProcessToken(GetCurrentProcess,
    TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, hTokenHandle);
  LookupPrivilegeValue('', 'SeShutdownPrivilege', PrivLUID);
  TokenPriv.PrivilegeCount:=1;
  TokenPriv.Privileges[0].Luid:=PrivLUID;
  TokenPriv.Privileges[0].Attributes:=SE_PRIVILEGE_ENABLED;
  AdjustTokenPrivileges(hTokenHandle, False, TokenPriv,
    SizeOf(tkpDummy), tkpDummy, lDummy);
  CloseHandle(hTokenHandle);
  ExitWindowsEx(EWX_FORCE*Byte(Force)+EWX_POWEROFF+EWX_SHUTDOWN, 0);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TStdCmd.SoundProc(SndFile : String = '');
begin
  if SndFile='' then
  begin
    MessageBeep($FFFFFFFF);
    MessageBeep(MB_OK);
  end
  else SndPlaySound(@SndFile[1], SND_ASYNC or SND_NOSTOP or SND_NODEFAULT);
end;

////////////////////////////////////////////////////////////////////////////////
function TStdCmd.GetPix(Wnd : Cardinal; X,Y : Cardinal) : Cardinal;
var
  DC : HDC;
begin
  DC:=GetDC(Wnd);
  Result:=GetPixel(DC,X,Y);
  ReleaseDC(Wnd,DC);
end;

////////////////////////////////////////////////////////////////////////////////
function TStdCmd.Display(Wnd : Cardinal; Str : String; MsgType : String; Dollar : Boolean = True) : String;
var
  MBType : Cardinal;
begin
  MsgType:=UpperCase(MsgType);
  MBType:=MB_OK;
  if MsgType='OKCANCEL'    then MBType:=MB_OKCANCEL;
  if MsgType='YESNO'       then MBType:=MB_YESNO;
  if MsgType='YESNOCANCEL' then MBType:=MB_YESNOCANCEL;

  if Dollar then Str:=ReplaceStr(Str,'$',#13#10);
  MBType:=MessageBox(Wnd,@Str[1],'EUO Message',MB_SETFOREGROUND+{MB_TOPMOST+}MBType);
  //MB_TOPMOST will only work if executed in the EUO window thread!
  //But because of the sync all other threads who use display get blocked
  //until the very last display message disappears!!!!!!!!!!

  Result:='Cancel';
  case MBType of
    ID_OK  : Result:='Ok';
    ID_YES : Result:='Yes';
    ID_NO  : Result:='No';
  end;
  DispRes:=Result;
end;

////////////////////////////////////////////////////////////////////////////////
function TStdCmd.GetCliTitle(Wnd : Cardinal) : String;
begin
  SetLength(Result,255);
  GetWindowText(Wnd,@Result[1],255);
  Result:=PChar(@Result[1]);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TStdCmd.SetCliTitle(Wnd : Cardinal; Title : String);
begin
  SetWindowText(Wnd,@Title[1]);
end;

////////////////////////////////////////////////////////////////////////////////
initialization
  Randomize;
end.
