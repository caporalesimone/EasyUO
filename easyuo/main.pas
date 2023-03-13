unit main;
interface
uses Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
     Dialogs, Menus, ComCtrls, ExtCtrls, ToolWin, ImgList, StdCtrls, SynEdit,
     SynEditMiscClasses, SynEditSearch, SynEditTypes, SynEditPlugins, Registry,
     SynMacroRecorder, SynEditHighlighter, SynUniHighlighter, ShellApi,
     vartree, access, insthandler;

type
  TMainForm = class(TForm)
    MainMenu: TMainMenu;
    File1: TMenuItem;
    Edit1: TMenuItem;
    Control1: TMenuItem;
    ools1: TMenuItem;
    Help1: TMenuItem;
    Exit1: TMenuItem;
    N1: TMenuItem;
    New1: TMenuItem;
    Open1: TMenuItem;
    Reopen1: TMenuItem;
    Save1: TMenuItem;
    SaveAs1: TMenuItem;
    Cut1: TMenuItem;
    Copy1: TMenuItem;
    Paste1: TMenuItem;
    Delete1: TMenuItem;
    SelectAll1: TMenuItem;
    N2: TMenuItem;
    Find1: TMenuItem;
    Replace1: TMenuItem;
    Undo1: TMenuItem;
    N3: TMenuItem;
    Start1: TMenuItem;
    Stop1: TMenuItem;
    Pause1: TMenuItem;
    N4: TMenuItem;
    StepOver1: TMenuItem;
    StepInto1: TMenuItem;
    StepOut1: TMenuItem;
    VarDump1: TMenuItem;
    N5: TMenuItem;
    SwapToNextClient1: TMenuItem;
    Help2: TMenuItem;
    GoToWebsite1: TMenuItem;
    N6: TMenuItem;
    About1: TMenuItem;
    ToolBar: TToolBar;
    ImageList: TImageList;
    StopAll1: TMenuItem;
    StatusBar: TStatusBar;
    SynHilite: TSynUniSyn;
    SynRec: TSynMacroRecorder;
    SynFind: TSynEditSearch;
    Close1: TMenuItem;
    N7: TMenuItem;
    SaveAll1: TMenuItem;
    CloseAll1: TMenuItem;
    TabCtrl: TTabControl;
    UpdateTimer: TTimer;
    MidPanel: TPanel;
    VarSplitter: TSplitter;
    VarTreeView: TTreeView;
    Redo1: TMenuItem;
    ClientPathDialog: TOpenDialog;
    xxx1: TMenuItem;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    ToolButton9: TToolButton;
    ToolButton10: TToolButton;
    ToolButton11: TToolButton;
    ToolButton12: TToolButton;
    ToolButton13: TToolButton;
    ToolButton14: TToolButton;
    ToolButton15: TToolButton;
    ToolButton16: TToolButton;
    ToolButton17: TToolButton;
    ToolButton18: TToolButton;
    ToolButton19: TToolButton;
    ToolButton20: TToolButton;
    ToolButton21: TToolButton;
    ToolButton22: TToolButton;
    ToolButton24: TToolButton;
    SynPopupMenu: TPopupMenu;
    Undo2: TMenuItem;
    Redo2: TMenuItem;
    N8: TMenuItem;
    Cut2: TMenuItem;
    Copy2: TMenuItem;
    Paste2: TMenuItem;
    Delete2: TMenuItem;
    SelectAll2: TMenuItem;
    TabPopupMenu: TPopupMenu;
    Close2: TMenuItem;
    CloseAll2: TMenuItem;
    FindDiag: TFindDialog;
    ReplaceDiag: TReplaceDialog;
    ScrPanel: TPanel;
    DontMoveCursor1: TMenuItem;
    UserVars1: TMenuItem;
    ToolButton23: TToolButton;
    NewClient1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure WMDropFiles(var Msg: TMessage); message WM_DROPFILES;
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure TabCtrlChange(Sender: TObject);
    procedure TabCtrlContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure MenuHandlerProc(Sender: TObject);
    procedure MenuHandler(Tag : Integer);
    procedure UpdateTimerTimer(Sender: TObject);
    procedure ToolButtonReopen(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FindDiagFind(Sender: TObject);
    procedure ReplaceDiagReplace(Sender: TObject);
  end;

const
  EUOVer     = '1.5.1.294';

var
  MainForm   : TMainForm;
  IH         : TInstHandler;
  Reg        : TRegistry;
  UpdateCnt  : Cardinal = 0;

implementation
uses text;
{$R *.dfm}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Reg:=TRegistry.Create;
  Reg.OpenKey('\Software\EasyUO',True);
  IH:=TInstHandler.Create;                                 // Create instance handler
  VarTreeFormCreate;                                       // Initialize VarTree
  VarTreeLoad('');                                         //
  UpdateTimer.Enabled:=True;                               // Enable Updatetimer
  UpdateTimerTimer(nil);
  DragAcceptFiles(Handle,True);                            // Activate Drag&Drop

  if ParamStr(1)<>'' then                                  // Check CmdLine
    if IH.Reopen(ParamStr(1)) then                         //
  begin                                                    //
    MainForm.WindowState:=wsMinimized;                     //
    MenuHandler(60);                                       //
  end;                                                     //

  Caption:='EasyUO '+EUOVer;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.WMDropFiles(var Msg: TMessage);
var
  FN : String;
begin
  SetLength(FN,256);
  DragQueryFile(Msg.WParam,0,@FN[1],Length(FN));
  IH.Reopen(PChar(@FN[1]));
  DragFinish(THandle(Msg.WParam));
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.FormDestroy(Sender: TObject);
begin
  VarTreeFormClose;                                        // Finalize VarTree
  IH.Free;                                                 // Free instance handler
  Reg.Free;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose:=IH.CloseAll;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.TabCtrlChange(Sender: TObject);
begin
  IH.SwitchTo(TabCtrl.TabIndex);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.TabCtrlContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
begin
  if MousePos.Y>20 then Handled:=True;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.FindDiagFind(Sender: TObject);
var
  Diag : TFindDialog;
  Opt  : TSynSearchOptions;
begin
  Diag:=TFindDialog(Sender);

  Opt:=[];
  if not(frDown in Diag.Options) then
    Include(Opt,ssoBackwards);
  if frMatchCase in Diag.Options then
    Include(Opt,ssoMatchCase);
  if frWholeWord in Diag.Options then
    Include(Opt,ssoWholeWord);

  if CSyn.SearchReplace(Diag.FindText,'',Opt)=0 then
    ShowMessage('No matches found!');
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.ReplaceDiagReplace(Sender: TObject);
var
  Opt : TSynSearchOptions;
begin
  Opt:=[ssoReplace,ssoSelectedOnly];
  if frMatchCase in ReplaceDiag.Options then
    Include(Opt,ssoMatchCase);
  if frWholeWord in ReplaceDiag.Options then
    Include(Opt,ssoWholeWord);

  if frReplaceAll in ReplaceDiag.Options then
  begin
    Include(Opt,ssoReplaceAll);
    Include(Opt,ssoPrompt);
  end;

  if CSyn.SearchReplace(ReplaceDiag.FindText,ReplaceDiag.ReplaceText,Opt)=0 then
    ShowMessage('No matches found!');
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.ToolButtonReopen(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  IH.BuildReopenMenu(Reopen1);
end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

procedure TMainForm.MenuHandlerProc(Sender: TObject);
begin
  MenuHandler(TComponent(Sender).Tag);                     // Forward proc
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.MenuHandler(Tag : Integer);
var
  Cnt  : Integer;
begin
  case Tag of
    01 : IH.New;
    02 : IH.Open;
    03 : IH.Save;
    04 : IH.SaveAs;
    05 : IH.SaveAll;
    06 : IH.Close;
    07 : IH.CloseAll;
    08 : Close;
    09 : IH.BuildReopenMenu(Reopen1);
    20 : CSyn.Undo;
    21 : CSyn.Redo;
    22 : CSyn.CutToClipboard;
    23 : CSyn.CopyToClipboard;
    24 : CSyn.PasteFromClipboard;
    25 : CSyn.ClearSelection;
    26 : CSyn.SelectAll;
    27 : FindDiag.Execute;
    28 : ReplaceDiag.Execute;
    60 : begin
           if CExec.Parser.UOSel.Cnt<1 then
           begin
             ShowMessage('No supported UO client found!');
             Exit;
           end;
           MarkOK:=True;
           if CExec.State=STOP then CExec.LoadScript(CSyn.Text);
           CExec.State:=PLAY;
         end;
    61 : CExec.State:=PAUSE;
    62 : CExec.State:=STOP;
    63 : for Cnt:=0 to IH.Count-1 do
           IH.Exec[Cnt].State:=STOP;
    64 : begin
           MarkOK:=True;
           if CExec.State=STOP then CExec.LoadScript(CSyn.Text);
           CExec.State:=STEPOVER;
         end;
    65 : begin
           MarkOK:=True;
           if CExec.State=STOP then CExec.LoadScript(CSyn.Text);
           CExec.State:=STEPINTO;
         end;
    66 : begin
           MarkOK:=True;
           if CExec.State=STOP then CExec.LoadScript(CSyn.Text);
           CExec.State:=STEPOUT;
         end;
    81 : if not CExec.Parser.UOCmd.OpenClient(CExec.State=STOP) then
           if ClientPathDialog.Execute then
             ShellExecute(0,'open',PChar(ClientPathDialog.FileName),'','',SW_SHOW);
    82 : with CExec.Parser.UOSel do
           SelectClient(Nr+1);
    83 : begin
           TextForm.Caption:='VarDump';
           TextForm.TextMemo.Text:=CExec.GetVarDump;
           TextForm.ShowModal;
         end;
    84 : begin
           DontMoveCursor1.Checked:=not DontMoveCursor1.Checked;
           MCDefault:=not DontMoveCursor1.Checked;
         end;
    85 : begin
           TextForm.Caption:='Manage VarList';
           TextForm.TextMemo.Text:=Identifiers;
           if TextForm.ShowModal=mrOK then
           begin
             Identifiers:=TextForm.TextMemo.Text;
             VarTreeLoad(Identifiers);
           end;
         end;
   100 : ShellExecute(0,'open','http://wiki.easyuo.com','','',SW_SHOW);
   101 : ShellExecute(0,'open','http://www.easyuo.com','','',SW_SHOW);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

procedure TMainForm.UpdateTimerTimer(Sender: TObject);
var
  PL,PAU,
  STO,STEPS,
  SEL        : Boolean;
  i1,i2      : Integer;
  Cnt        : Integer;
begin
  Inc(UpdateCnt);

  (***Update WndList***)
  for Cnt:=0 to IH.Count-1 do
    with IH.Exec[Cnt] do
  begin
    if Parser.UOSel.Nr=0 then State:=STOP;

    if (Parser.UOSel.Nr=0)and(Parser.UOSel.Cnt>0) then
      Parser.UOSel.SelectClient(1);
  end;

  {***Update VarList***}
  if UpdateCnt mod 2=0 then VarTreeRefresh;
  if UpdateCnt mod 10=0 then
    for Cnt:=0 to IH.Count-1 do
  begin
    IH.Exec[Cnt].GetVar('#jindex');
  end;

  (***Update Controller Toolbar/Menubar***)
  PL:=False;
  PAU:=False;
  STO:=False;
  STEPS:=False;
  case CExec.State of
    PLAY  : begin
              PL:=False;
              PAU:=True;
              STO:=True;
              STEPS:=True;
            end;
    PAUSE : begin
              PL:=True;
              PAU:=False;
              STO:=True;
              STEPS:=True;
            end;
    STOP  : begin
              PL:=True;
              PAU:=False;
              STO:=False;
              STEPS:=True;
            end;
    STEPOVER,
    STEPINTO,
    STEPOUT:begin
              PL:=False;
              PAU:=True;
              STO:=True;
              STEPS:=False;
            end;
  end;
  SEL:=True;
  if CSyn.Lines.Count<2 then
    if CSyn.Text='' then
  begin
    PL:=False;
    STEPS:=False;
    SEL:=False;
  end;
  Start1.Enabled:=PL;
  ToolButton14.Enabled:=PL;
  Pause1.Enabled:=PAU;
  ToolButton15.Enabled:=PAU;
  Stop1.Enabled:=STO;
  ToolButton16.Enabled:=STO;
  StepOver1.Enabled:=STEPS;
  StepInto1.Enabled:=STEPS;
  StepOut1.Enabled:=STEPS;

  (***Update Edit Toolbar/Menubar***)
  Undo1.Enabled:=CSyn.CanUndo;
  Redo1.Enabled:=CSyn.CanRedo;
  Cut1.Enabled:=CSyn.SelLength>0;
  ToolButton7.Enabled:=Cut1.Enabled;
  Copy1.Enabled:=CSyn.SelLength>0;
  ToolButton8.Enabled:=Copy1.Enabled;
  Paste1.Enabled:=CSyn.CanPaste;
  ToolButton9.Enabled:=Paste1.Enabled;
  Delete1.Enabled:=CSyn.SelLength>0;
  SelectAll1.Enabled:=SEL;
  Undo2.Enabled:=Undo1.Enabled;
  Redo2.Enabled:=Redo1.Enabled;
  Cut2.Enabled:=Cut1.Enabled;
  Copy2.Enabled:=Copy1.Enabled;
  Paste2.Enabled:=Paste1.Enabled;
  Delete2.Enabled:=Delete1.Enabled;
  SelectAll2.Enabled:=SelectAll1.Enabled;

  (***Update File Toolbar/Menubar***)
  Save1.Enabled:=CSyn.Modified;
  ToolButton4.Enabled:=Save1.Enabled;
  SaveAs1.Enabled:=CSyn.Modified;

  (***Update Tools Toolbar/Menubar***)
  SwapToNextClient1.Enabled:=CExec.Parser.UOSel.Cnt>1;
  ToolButton24.Enabled:=SwapToNextClient1.Enabled;

  (***Update Macro Recorder***)
  if SynRec.Editor<>CSyn then
  begin
    SynRec.Stop;
    SynRec.Editor:=CSyn;
  end;

  (***Update Editor Window***)
  CSyn.ReadOnly:=CExec.State<>STOP;

  (***Update LineMark in Pause Mode***)
  if (CExec.State=PAUSE) and MarkOK then
    if CExec.Paused then
  begin
    MarkOK:=False;
    CSyn.InvalidateLine(MarkLine);
    MarkLine:=CExec.CurLine+1;
    CSyn.InvalidateLine(MarkLine);
    CSyn.GotoLineAndCenter(MarkLine);
  end;
  if (CExec.State<>PAUSE) and (MarkLine>-1) then
  begin
    CSyn.InvalidateLine(MarkLine);
    MarkLine:=-1;
  end;

  (***Update Statusbar***)
  StatusBar.Panels[0].Text:=IntToStr(CSyn.CaretY)+': '+IntToStr(CSyn.CaretX);

  i1:=StrToIntDef(CExec.GetVar('#charposx'),-1);
  i2:=StrToIntDef(CExec.GetVar('#charposy'),-1);
  StatusBar.Panels[1].Text:=IntToStr(i1)+'/'+IntToStr(i2);
  StatusBar.Panels[2].Text:=IntToStr(i1 mod 8)+','+IntToStr(i2 mod 8);
  StatusBar.Panels[3].Text:=CExec.GetVar('#cursorx')+'/'+CExec.GetVar('#cursory');
  StatusBar.Panels[4].Text:=IntToStr(CExec.Parser.UOSel.Nr)+'|'+IntToStr(CExec.Parser.UOSel.Cnt);
end;

////////////////////////////////////////////////////////////////////////////////
end.
