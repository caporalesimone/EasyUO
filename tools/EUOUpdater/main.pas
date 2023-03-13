unit main;
interface
uses Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
     Dialogs, RWAccess, UOSelector, ExtCtrls, StdCtrls;

type
  TMainForm = class(TForm)
    MainPanel: TPanel;
    SysTimer: TTimer;
    ScanMemo: TMemo;
    ResMemo: TMemo;
    BottomPanel: TPanel;
    StartButton: TButton;
    ScanLabel: TLabel;
    MainSplitter: TSplitter;
    ResLabel: TLabel;
    procedure SysTimerTimer(Sender: TObject);
    procedure StartButtonClick(Sender: TObject);
  end;

var
  MainForm : TMainForm;
  UOSel    : TUOSel;

implementation
{$R *.dfm}

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.SysTimerTimer(Sender: TObject);
begin
  UOSel.Update;
  if UOSel.Nr>0 then Exit;

  if UOSel.Cnt>0 then
    UOSel.SelectClient(1);
  MainPanel.Visible:=UOSel.Cnt>0
end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

function GetAddr(Str : String; var Res : Cardinal; var Desc : String) : Boolean;
var
  sBuf   : String;
  Cnt    : Cardinal;
  Cnt2   : Integer;
  sPar   : Array[1..6] of String;
begin
  Result:=False;

  sBuf:=Str+';';
  for Cnt:=1 to 6 do
  begin
    sPar[Cnt]:='';
    Cnt2:=Pos(';',sBuf);
    if Cnt2=0 then Continue;
    sPar[Cnt]:=UpperCase(Trim(Copy(sBuf,1,Cnt2-1)));
    Delete(sBuf,1,Cnt2);
  end;
  Desc:=sPar[6];

  sBuf:='';
  while sPar[1]<>'' do
  begin
    sBuf:=sBuf+Char(StrToIntDef('$'+Copy(sPar[1],1,2),0));
    Delete(sPar[1],1,2);
  end;

  sPar[2]:=Char(StrToIntDef('$'+sPar[2],1));
  Res:=SearchMem(UOSel.HProc,sBuf,sPar[2][1]);
  if Res<1 then Exit;

  Res:=Res+StrToIntDef(sPar[3],0);
  Cnt:=Res;
  if Copy(sPar[4],1,1)='C' then
    RWVar(UOSel.HProc,Read,Cnt,@Res,4);
  if Copy(sPar[4],2,1)='B' then
    Res:=Res+Cnt+4;

  Res:=Res+StrToIntDef(sPar[5],0);

  Result:=True;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.StartButtonClick(Sender: TObject);
var
  Cnt   : Integer;
  Res   : Cardinal;
  Desc  : String;
  sBuf  : String;
begin
  ResMemo.Clear;
  sBuf:='empty';
  for Cnt:=0 to ScanMemo.Lines.Count-1 do
  begin

    if Copy(ScanMemo.Lines[Cnt],1,2)='//' then Continue;

    if ScanMemo.Lines[Cnt]='' then
    begin
      ResMemo.Lines.Add('');
      Continue;
    end;

    if not GetAddr(ScanMemo.Lines[Cnt],Res,Desc) then
    begin
      if sBuf<>Desc then
        ResMemo.Lines.Add('N/A '+Desc);
    end
    else begin
      if sBuf=Desc then
        ResMemo.Lines.Delete(ResMemo.Lines.Count-1);
      ResMemo.Lines.Add('$'+IntToHex(Res,8)+' '+Desc);
    end;

    sBuf:=Desc;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

initialization
  UOSel:=TUOSel.Create;
finalization
  UOSel.Free;
end.
