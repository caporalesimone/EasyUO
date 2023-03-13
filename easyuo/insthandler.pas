unit insthandler;
interface
uses Windows, SysUtils, Classes, Graphics, Controls, Dialogs, Menus, SynEdit,
     executor;

type
  TInstHandler  = class(TObject)
  private
    SynList     : TStringList;
    ExecList    : TList;
    NewCnt      : Integer;
    function    CreateSyn : TSynEdit;
    function    GetSyn(Ind : Integer) : TSynEdit;
    function    GetExec(Ind : Integer) : TExecutor;
    procedure   SynLineColors(S: TObject; Line: Integer; var Special: Boolean; var FG, BG: TColor);
    procedure   SynReplaceText(Sender: TObject; const ASearch, AReplace: String; Line, Column: Integer; var Action: TSynReplaceAction);
  public
    Cur         : Integer;
    constructor Create;
    procedure   Free;
    function    Count : Integer;
    procedure   SwitchTo(Ind : Integer);
    procedure   New;
    procedure   Open;
    function    Reopen(FN : String) : Boolean;
    procedure   BuildReopenMenu(Parent : TMenuItem);
    procedure   ReopenHandler(Sender : TObject);
    function    Save : Boolean;
    function    SaveAs : Boolean;
    procedure   SaveAll;
    function    Close : Boolean;
    function    CloseAll : Boolean;
    property    Syn[Ind : Integer] : TSynEdit read GetSyn;
    property    Exec[Ind : Integer] : TExecutor read GetExec;
  end;

  function CSyn  : TSynEdit;
  function CFN   : String;
  function CExec : TExecutor;

const
  STOP     = 0;
  PLAY     = 1;
  PAUSE    = 2;
  STEPINTO = 3;
  STEPOVER = 4;
  STEPOUT  = 5;

var
  MarkOK     : Boolean = False;
  MarkLine   : Integer = -1;
  ReopenList : TStringList;

implementation
uses main;

const ReopenNr = 8;

////////////////////////////////////////////////////////////////////////////////
constructor TInstHandler.Create;
begin
  SynList:=TStringList.Create;
  ExecList:=TList.Create;
  ReopenList:=TStringList.Create;
  Cur:=-1;
  NewCnt:=0;
  New;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TInstHandler.Free;
var
  Cnt : Integer;
begin
  ReopenList.Free;
  for Cnt:=0 to ExecList.Count-1 do
  begin
    Exec[Cnt].Free;
    Syn[Cnt].Free;
  end;
  ExecList.Free;
  SynList.Free;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TInstHandler.SynLineColors(S: TObject; Line: Integer; var Special: Boolean; var FG, BG: TColor);
begin
  if MarkLine<0 then Exit;
  Special:=Line=MarkLine;
  FG:=clWindow;
  BG:=clNavy;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TInstHandler.SynReplaceText(Sender: TObject; const ASearch, AReplace: String; Line, Column: Integer; var Action: TSynReplaceAction);
begin
  case MessageBox(MainForm.Handle,'Replace this match?','Confirm',MB_ICONQUESTION+MB_YESNOCANCEL) of
    IDYes : Action:=raReplace;
    IDNo  : Action:=raSkip;
    else    Action:=raCancel;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
function TInstHandler.CreateSyn : TSynEdit;
begin
  Result:=TSynEdit.Create(nil);
  Result.Visible:=False;
  Result.Align:=alClient;
  Result.Ctl3D:=True;
  Result.WantTabs:=True;
  Result.TabWidth:=2;
  Result.RightEdge:=-1;

  Result.ParentColor:=False;
  Result.Color:=clWindow;

  Result.Gutter.Visible:=False;
  {Result.Gutter.AutoSize:=True;
  Result.Gutter.DigitCount:=3;
  Result.Gutter.ShowLineNumbers:=True;}
  Result.Options:=[eoAltSetsColumnMode,eoAutoIndent,eoGroupUndo,
    eoScrollByOneLess,eoScrollPastEol,eoShowScrollHint,eoSmartTabDelete,
    eoSmartTabs,eoTabIndent,eoTabsToSpaces,eoTrimTrailingSpaces];

  Result.SearchEngine:=MainForm.SynFind;
  Result.OnReplaceText:=SynReplaceText;
  Result.Highlighter:=MainForm.SynHilite;
  Result.OnSpecialLineColors:=SynLineColors;
  Result.PopupMenu:=MainForm.SynPopupMenu;

  Result.Parent:=MainForm.ScrPanel;
end;

////////////////////////////////////////////////////////////////////////////////
function TInstHandler.GetSyn(Ind : Integer) : TSynEdit;
begin
  Result:=TSynEdit(SynList.Objects[Ind]);
end;

////////////////////////////////////////////////////////////////////////////////
function TInstHandler.GetExec(Ind : Integer) : TExecutor;
begin
  Result:=ExecList[Ind];
end;

////////////////////////////////////////////////////////////////////////////////
procedure TInstHandler.SwitchTo(Ind : Integer);
begin
  Syn[Ind].Visible:=True;
  if (Cur>-1)and(Cur<>Ind) then
    Syn[Cur].Visible:=False;

  MainForm.TabCtrl.TabIndex:=Ind;
  Cur:=Ind;

  if MainForm.Visible then
    MainForm.ActiveControl:=Syn[Ind];
end;

////////////////////////////////////////////////////////////////////////////////
function TInstHandler.Count : Integer;
begin
  Result:=ExecList.Count;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TInstHandler.New;
var
  ExecObj : TExecutor;
begin
  SynList.AddObject('',CreateSyn);

  ExecObj:=TExecutor.Create(MainForm.Handle);
  ExecList.Add(ExecObj);

  Inc(NewCnt);
  MainForm.TabCtrl.Tabs.Add('new'+IntToStr(NewCnt));
  SwitchTo(Count-1);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TInstHandler.Open;
var
  OpenDiag : TOpenDialog;
  FN       : String;
begin
  OpenDiag:=TOpenDialog.Create(MainForm);
  OpenDiag.DefaultExt:='txt';
  OpenDiag.Filter:='Scripts (*.txt; *.euo)|*.txt; *.euo|All Files (*.*)|*.*';
  OpenDiag.Options:=[ofFileMustExist,ofEnableSizing];
  OpenDiag.Title:='Open Script';
  FN:='';
  if OpenDiag.Execute then FN:=OpenDiag.FileName;
  OpenDiag.Free;
  if FN='' then Exit;

  Reopen(FN);
end;

////////////////////////////////////////////////////////////////////////////////
function TInstHandler.Reopen(FN : String) : Boolean;
var
  SynEdit : TSynEdit;
  ExecObj : TExecutor;
  Cnt     : Integer;
begin
  Result:=False;
  if not FileExists(FN) then Exit;
  Result:=True;

  SynEdit:=CreateSyn;
  SynEdit.Lines.LoadFromFile(FN);
  SynList.AddObject(FN,SynEdit);

  ExecObj:=TExecutor.Create(MainForm.Handle);
  ExecList.Add(ExecObj);

  MainForm.TabCtrl.Tabs.Add(ExtractFileName(FN));
  SwitchTo(Count-1);

  if (Count<3)and(SynList[0]='')and not Syn[0].Modified then
  begin
    Cur:=0;
    Close;
  end;

  ReopenList.Text:=Reg.ReadString('Reopen');
  Cnt:=ReopenList.IndexOf(FN);
  if Cnt>=0 then
    ReopenList.Delete(Cnt);
  ReopenList.Insert(0,FN);
  while ReopenList.Count>ReopenNr do
    ReopenList.Delete(ReopenNr);
  Reg.WriteString('Reopen',ReopenList.Text);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TInstHandler.BuildReopenMenu(Parent : TMenuItem);
var
  Cnt : Integer;
  MI  : TMenuItem;
begin
  while Parent.Count>0 do
    Parent.Items[0].Free;
  ReopenList.Text:=Reg.ReadString('Reopen');
  for Cnt:=0 to ReopenList.Count-1 do
  begin
    MI:=TMenuItem.Create(Parent);
    MI.OnClick:=ReopenHandler;
    MI.Caption:='&'+IntToStr(Cnt+1)+' '+ReopenList[Cnt];
    MI.Tag:=73590+Cnt;
    Parent.Add(MI);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TInstHandler.ReopenHandler(Sender : TObject);
begin
  IH.Reopen(ReopenList[TMenuItem(Sender).Tag-73590]);
end;

////////////////////////////////////////////////////////////////////////////////
function TInstHandler.Save : Boolean;
begin
  if SynList[Cur]='' then
  begin
    Result:=SaveAs;
    Exit;
  end;
  Syn[Cur].Lines.SaveToFile(SynList[Cur]);
  Syn[Cur].Modified:=False;
  Result:=True;
end;

////////////////////////////////////////////////////////////////////////////////
function TInstHandler.SaveAs : Boolean;
var
  SaveDiag : TSaveDialog;
  FN       : String;
begin
  SaveDiag:=TSaveDialog.Create(MainForm);
  SaveDiag.DefaultExt:='txt';
  SaveDiag.Filter:='Scripts (*.txt)|*.txt;*.euo|All Files (*.*)|*.*';
  SaveDiag.Options:=[ofPathMustExist,ofEnableSizing];
  SaveDiag.Title:='Save '+MainForm.TabCtrl.Tabs[Cur]+' As';
  FN:='';
  if SaveDiag.Execute then FN:=SaveDiag.FileName;
  SaveDiag.Free;

  Result:=FN<>'';
  if FN='' then Exit;

  Syn[Cur].Lines.SaveToFile(FN);
  Syn[Cur].Modified:=False;
  SynList[Cur]:=FN;
  MainForm.TabCtrl.Tabs[Cur]:=ExtractFileName(FN);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TInstHandler.SaveAll;
var
  Cnt     : Integer;
begin
  for Cnt:=Count-1 downto 0 do
  begin
    Cur:=Cnt;
    if not CSyn.Modified then Continue;
    if not Save then Break;
  end;
  Cur:=MainForm.TabCtrl.TabIndex;
end;

////////////////////////////////////////////////////////////////////////////////
function TInstHandler.Close : Boolean;
var
  OldCur : Integer;
begin
  Result:=False;
  if Syn[Cur].Modified then
  case MessageBox(MainForm.Handle,
    @('Save changes to '+MainForm.TabCtrl.Tabs[Cur]+'?')[1],
    'Confirm',MB_ICONQUESTION+MB_YESNOCANCEL) of
    IDYES : if not Save then Exit;
    IDCANCEL : Exit;
  end;
  Result:=True;

  if Cur=MainForm.TabCtrl.TabIndex then
  begin
    OldCur:=Cur;
    if Cur>0 then SwitchTo(Cur-1)
    else if Count<2 then New
    else SwitchTo(1);
    Cur:=OldCur;
  end;

  Exec[Cur].Free;
  ExecList.Delete(Cur);
  Syn[Cur].Free;
  SynList.Delete(Cur);
  MainForm.TabCtrl.Tabs.Delete(Cur);

  Cur:=MainForm.TabCtrl.TabIndex;
end;

////////////////////////////////////////////////////////////////////////////////
function TInstHandler.CloseAll : Boolean;
var
  Cnt     : Integer;
begin
  for Cnt:=Count-1 downto 0 do
  begin
    Cur:=Cnt;
    if not Close then Break;
  end;
  Cur:=MainForm.TabCtrl.TabIndex;
  Result:=Cnt<0;
end;

////////////////////////////////////////////////////////////////////////////////
function CSyn : TSynEdit;
begin
  Result:=IH.Syn[IH.Cur];
end;

////////////////////////////////////////////////////////////////////////////////
function CFN : String;
begin
  Result:=IH.SynList[IH.Cur];
end;

////////////////////////////////////////////////////////////////////////////////
function CExec : TExecutor;
begin
  Result:=IH.Exec[IH.Cur];
end;

////////////////////////////////////////////////////////////////////////////////
end.