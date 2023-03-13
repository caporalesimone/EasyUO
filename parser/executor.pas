unit executor;
interface
uses SysUtils, Windows, Classes, parser;

type
  TExeThread    = class(TThread)
  private
    Parent      : TObject;
    Term        : Boolean;
  protected
    procedure   Execute; override;
  end;

  TExecutor     = class(TObject)
  private
    Thrd        : TExeThread;
    ParWnd      : Cardinal;
    Stat        : Cardinal;
    OldCall     : Cardinal;
    OldSub      : Cardinal;
    procedure   SetState(Value : Cardinal);
  public
    Parser      : TOldParser;
    constructor Create(PWnd : Cardinal);
    procedure   Free;
    procedure   LoadScript(Scr : String);
    procedure   SetVar(Name, Value : String);
    function    GetVar(Name : String) : String;
    function    GetVarDump : String;
    function    CurLine : Cardinal;
    function    NextLine : Cardinal;
    function    Paused : Boolean;
    property    State : Cardinal read Stat write SetState;
  end;

const
  STOP     = 0;
  PLAY     = 1;
  PAUSE    = 2;
  STEPINTO = 3;
  STEPOVER = 4;
  STEPOUT  = 5;

implementation

////////////////////////////////////////////////////////////////////////////////
/// External Thread ////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
function KillDisplayBox(Wnd : HWnd; ThrdID : Cardinal) : Boolean; stdcall;
const
  WM_CLOSE = $0010;
var
  Buf : Array[1..16] of Char;
begin
  Result:=True;
  if GetWindowThreadProcessID(Wnd)<>ThrdID then Exit;
  GetClassName(Wnd,@Buf,16);
  if StrPas(@Buf[1])<>'#32770' then Exit;
  GetWindowText(Wnd,@Buf,16);
  if StrPas(@Buf[1])<>'EUO Message' then Exit;
  PostMessage(Wnd,WM_CLOSE,0,0);
  Result:=False;
end;

////////////////////////////////////////////////////////////////////////////////
constructor TExecutor.Create(PWnd : Cardinal);
begin
  inherited Create;

  Parser:=TOldParser.Create(PWnd);
  ParWnd:=PWnd;

  Stat:=Stop;
  Thrd:=TExeThread.Create(True);
  Thrd.Parent:=self;
  Thrd.Resume;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TExecutor.Free;
var
  GTC : Cardinal;
begin
  EnumWindows(@KillDisplayBox,Thrd.ThreadID);

  Thrd.Term:=True;
  Stat:=Stop;
  Parser.Brk:=True;
  GTC:=GetTickCount;
  while Thrd.Term do
  begin
    Sleep(1);
    if GTC+3000>GetTickCount then Continue;
    TerminateThread(Thrd.Handle,0);
    Break;
  end;
  Thrd.Free;

  Parser.Free;
  inherited Free;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TExecutor.LoadScript(Scr : String);
begin
  with Parser do
    if (Stat=Stop)and Paused then
  begin
    Clear;
    ScrList.Scr.Text:=Scr;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
function TExecutor.GetVar(Name : String) : String;
begin
  Result:=Parser.GetVar(Name);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TExecutor.SetVar(Name, Value : String);
begin
  Parser.SetVar(Name,Value);
end;

////////////////////////////////////////////////////////////////////////////////
function TExecutor.GetVarDump : String;
begin
  Result:=Parser.GetVarDump;
end;

////////////////////////////////////////////////////////////////////////////////
function TExecutor.CurLine : Cardinal;
begin
  Result:=Parser.CurLine;
end;

////////////////////////////////////////////////////////////////////////////////
function TExecutor.NextLine : Cardinal;
begin
  Result:=Parser.NextLine;
end;

////////////////////////////////////////////////////////////////////////////////
function TExecutor.Paused : Boolean;
begin
  Result:=Parser.Paused;
end;

////////////////////////////////////////////////////////////////////////////////
{
  Current State:      Valid Values:
  Stop                Play, Step
  Pause               Play, Stop, Step
  Play                Pause, Stop, Step
  Step                Play, Pause, Stop, Step
}

procedure TExecutor.SetState(Value : Cardinal);
begin
  if Value=Stat then Exit;

  if Value in [Play,StepInto,StepOver,StepOut] then
    with Parser do
  begin
    if ScrList.Scrs[0].Count=0 then Exit;
    if (Stat=STOP)and Paused then
      Parser.Clear;
    Brk:=False;
    Slp:=False;
    OldCall:=ScrList.CallLevel;
    OldSub:=ScrList.SubLevel;
    if (OldCall=0)and(OldSub=0) then
      if Value=StepOut then Value:=StepOver;
  end;

  if Value in [Pause] then
  begin
    if Stat=Stop then Exit;
    Parser.Slp:=True;
  end;

  if Value in [Stop] then
  begin
    Parser.Brk:=True;
    EnumWindows(@KillDisplayBox,Thrd.ThreadID);
  end;

  Stat:=Value;
end;

////////////////////////////////////////////////////////////////////////////////
/// Internal Thread ////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

procedure TExeThread.Execute;
const
  WM_CLOSE = $0010;
var
  i,j : Integer;
begin
  Term:=False;
  j:=0;

  while not Term do
    with TExecutor(Parent) do
  begin
    Sleep(50);

    for i:=1 to Parser.LPC do
    begin

      if Stat in [Stop,Pause] then Break;
      Parser.Paused:=False;

      // Prevent freeze even if LPC is very high!
      j:=(j+1) and $3FF;
      if j=0 then Sleep(1);
      Parser.PlayLine;

      case Parser.ResInt of
        RES_PAUSE : Stat:=Pause;
        RES_STOP  : Stat:=Stop;
        RES_CLOSE : begin
                      PostMessage(ParWnd,WM_CLOSE,0,0);
                      Stat:=Stop;
                    end;
      end;

      if Stat=StepOver then
        with Parser.ScrList do
      begin
        if CallLevel<OldCall then Stat:=Pause;
        if CallLevel=OldCall then
          if SubLevel<=OldSub then Stat:=Pause;
      end;

      if Stat=StepOut then
        with Parser.ScrList do
      begin
        if CallLevel<OldCall then Stat:=Pause;
        if CallLevel=OldCall then
          if SubLevel<OldSub then Stat:=Pause;
      end;

      if Stat=StepInto then Stat:=Pause;

    end;
    Parser.Paused:=True;

  end;

  Term:=False;
end;

////////////////////////////////////////////////////////////////////////////////
end.
