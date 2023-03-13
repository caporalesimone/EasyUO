unit parser;
interface
uses Windows, SysUtils, Classes, Graphics,
     stdcommands, variables, menu, scripts, param,
     comm, uoselector, uoevents, uovariables, uocommands;

const
  RES_OK         = 0;
  RES_STOP       = 1;
  RES_PAUSE      = 2;
  RES_CLOSE      = 3;

type
  TPixData       = record
    Col          : Cardinal;
    X            : Cardinal;
    Y            : Cardinal;
  end;

  TOldParser     = class(TObject)
  private
    SkillStr     : String;
    SkillBool    : Boolean;
    TileCount    : Cardinal;
    SysMsgCol    : Cardinal;
    SCntBase     : Cardinal;
    SCnt2Base    : Cardinal;
    UOVar        : TUOVar;
    StdCmd       : TStdCmd;
    Vars         : TVars;
    MenuObj      : TMenuObj;
    CommObj      : TCommObj;
    EventObj     : TUOEvent;
    ParWnd       : Cardinal;
    Par          : TStringList;
    Par2         : TStringList;
    ParList      : TParList;
    NSStack      : TStringList;
    PixData      : Array[0..1000] of TPixData;
    PixCol       : Cardinal;
    ElseFlag     : Boolean;
    StrRes       : String;
    _Result      : String;
    SpeedVar     : TStringList;
    FindInd      : Cardinal;
    FindModX     : Integer;
    FindModY     : Integer;
    JIndex       : Cardinal;
    DJournal     : Cardinal;
    DJournalSave : Cardinal;
    procedure    Parameterize(Str : String; StrList : TStringList);
    function     GetParStr(Nr : Integer) : String;
    function     GetCmd(Line : Integer) : String;
    procedure    Eval(FP : Integer);
    function     ScanForBlock : Cardinal;
    procedure    ParseLine(PList : TParList);
    procedure    LineInfo(Line : Integer);
    function     Delay(ms : Cardinal) : Boolean;
    procedure    Interpret;
    procedure    InterpretUO;
    function     FindDist(var Dist : Cardinal) : Boolean;
    procedure    LinesPerCycleProc;
    procedure    ContinueBreakProc;
    procedure    UntilProc;
    procedure    WhileProc;
    procedure    ExEventProc;
    procedure    EventProc;
    procedure    SendProc;
    procedure    ForProc;
    procedure    ExitProc;
    procedure    CallProc;
    procedure    SubProc;
    procedure    GoSubProc;
    procedure    ReturnProc;
    procedure    MenuProc;
    procedure    NameSpaceProc;
    procedure    TileProc;
    procedure    StrProc;
    procedure    SetShopItemProc;
    procedure    GetShopInfoProc;
    procedure    IgnoreItemProc;
    procedure    FindItemProc;
    procedure    SoundProc;
    procedure    UOXLProc;
    procedure    TerminateProc;
    procedure    SleepProc;
    procedure    DeleteVarProc;
    procedure    GetUOTitleProc;
    procedure    SetUOTitleProc;
    procedure    DisplayProc;
    procedure    HideItemProc;
    procedure    DeleteJournalProc;
    procedure    ScanJournalProc;
    procedure    ExecuteProc;
    procedure    ShutdownProc;
    procedure    NextCPosProc;
    procedure    ChooseSkillProc;
    procedure    OnHotkeyProc;
    procedure    GoToProc;
    procedure    ElseProc;
    procedure    IfProc;
    procedure    SetProc;
    procedure    ContPosProc;
    procedure    TargetProc;
    procedure    CmpPixProc;
    procedure    SavePixProc;
    procedure    MsgProc;
    procedure    MoveProc;
    procedure    ClickProc;
    procedure    KeyProc;
    procedure    WaitProc;
    procedure    IgnoreContProc;
    function     GetTileFlags : String;
    procedure    UpdateJournal;
  public
    CS           : TMultiReadExclusiveWriteSynchronizer;
    UOSel        : TUOSel;
    UOCmd        : TUOCmd; //public for access to OpenClient command
    ScrList      : TScriptList;
    CurLine      : Integer;
    NextLine     : Integer;
    ResInt       : Integer;
    LPC          : Cardinal;
    Brk          : Boolean;
    Slp          : Boolean;
    Paused       : Boolean;
    constructor  Create(Wnd : Cardinal);
    procedure    Free;
    procedure    Clear;
    procedure    PlayLine;
    function     GetVar(Name : String) : String;
    procedure    SetVar(Name, Value : String);
    function     GetVarDump : String;
  end;

implementation
uses conversion, access;

const
  VarNamesR : Array[0..106] of String = (
    'CliCnt','CliNr','Time','Date','SysTime','Random','OSVer','CharPosX',
    'CharPosY','CharPosZ','CharID','CharGhost','CharStatus','CharDir',
    'CharName','Sex','Str','MaxWeight','Dex','Int','Hits','MaxHits',
    'Stamina','MaxStam','Mana','MaxMana','Gold','Weight','MaxStats',
    'AR','Followers','MaxFol','FR','CR','PR','ER','Luck','MaxDmg',
    'MinDmg','TP','Shard','ContSize','ContKind','ContID','ContType',
    'ContName','CliLang','CliVer','CliLogged','CursKind','EnemyHits',
    'EnemyID','LObjectType','LLiftedID','LLiftedType','LLiftedKind',
    'SysMsg','Skill','SkillCap','SkillLock','CursorX','CursorY','FindID',
    'FindType','FindX','FindY','FindZ','FindKind','FindStack','FindBagID',
    'FindRep','FindCol','FindCnt','FindDist','PixCol','Journal','JColor',
    'DispRes','ShopCurPos','ShopCnt','ShopItemType','ShopItemID',
    'ShopItemMax','ShopItemPrice','ShopItemName','TileCnt','TileType',
    'TileZ','TileName','TileFlags','JIndex','NSName','NSType','True',
    'False','SPC','SMC','DOT','Property','EUOVer','Opts','BackpackID',
    'CurPath','ContSizeX','ContSizeY','CharType','ContHP');

  VarNamesRW : Array[0..32] of String = (
    'SCnt','SCnt2','LShard','ContPosX','ContPosY','NextCPosX','NextCPosY',
    'TargCurs','CliXRes','CliYRes','CliLeft','CliTop','LSpell','LSkill',
    'LTargetKind','LTargetTile','LTargetX','LTargetY','LTargetZ','LTargetID',
    'LHandID','RHandID','LObjectID','FindIndex','FindMod','Result','StrRes',
    'MenuButton','MenuRes','LPC','SendHeader','SysMsgCol','CliTitle');

////////////////////////////////////////////////////////////////////////////////
/// Functions //////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

function UScore(Str : String) : String;
var
  Cnt : Integer;
begin
  for Cnt:=1 to Length(Str) do
    if Str[Cnt]=#32 then Str[Cnt]:='_';
  Result:=Str;
end;

////////////////////////////////////////////////////////////////////////////////
function NoScore(Str : String) : String;
var
  Cnt : Integer;
begin
  for Cnt:=1 to Length(Str) do
    if Str[Cnt]='_' then Str[Cnt]:=#32;
  Result:=Str;
end;

////////////////////////////////////////////////////////////////////////////////
function ExtractPath(Path : String) : String;
begin
  Result:=ExtractShortPathName(ExtractFileDir(Path))+'\';
end;

////////////////////////////////////////////////////////////////////////////////
function IsAbsolutePath(Path : String) : Boolean;
begin
  Result:=(Copy(Path,2,2)=':\')or(Copy(Path,1,1)='\');
end;

////////////////////////////////////////////////////////////////////////////////
function IsVar(Str : String) : Boolean;
var
  Cnt1 : Integer;
begin
  Result:=False;

  if Length(Str)<2 then Exit;
  if not(Str[1] in ['!','%','*','#']) then Exit;

  for Cnt1:=2 to Length(Str) do
    if not(Str[Cnt1] in ['0'..'9','A'..'Z','a'..'z','_']) then Exit;

  Result:=True;
end;

////////////////////////////////////////////////////////////////////////////////
function SysTime : Int64;
var
  ft : _FILETIME;
begin
  GetSystemTimeAsFileTime(ft);
  Result:=(Int64(ft.dwHighDateTime) shl 32 + ft.dwLowDateTime
          - 119600064000000000) div 10000; // Jan 1 1980 UTC
end;

////////////////////////////////////////////////////////////////////////////////
function OSVer : String;
var
  WinVerInfo : OSVERSIONINFO;
begin
  WinVerInfo.dwOSVersionInfoSize:=SizeOf(OSVERSIONINFO);
  GetVersionEx(WinVerInfo);
  Result:=IntToStr(WinVerInfo.dwPlatformId)+' '+
          IntToStr(WinVerInfo.dwMajorVersion)+' '+
          IntToStr(WinVerInfo.dwMinorVersion);
end;

////////////////////////////////////////////////////////////////////////////////
/// Parser /////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

constructor TOldParser.Create(Wnd : Cardinal);
var
  Cnt  : Integer;
  iBuf : Integer;
begin
  inherited Create;
  UOSel:=TUOSel.Create;
  UOVar:=TUOVar.Create(UOSel);
  StdCmd:=TStdCmd.Create(Delay);
  UOCmd:=TUOCmd.Create(UOSel,UOVar,Delay);
  EventObj:=TUOEvent.Create(UOSel,UOVar,Delay);
  Vars:=TVars.Create;
  ScrList:=TScriptList.Create;
  MenuObj:=TMenuObj.Create;
  CommObj:=TCommObj.Create;
  ParWnd:=Wnd;

  CS:=TMultiReadExclusiveWriteSynchronizer.Create;

  Par:=TStringList.Create;
  Par2:=TStringList.Create;
  ParList:=TParList.Create;
  NSStack:=TStringList.Create;

  SpeedVar:=TStringList.Create;
  for Cnt:=0 to High(VarNamesR) do
  begin
    SpeedVar.Find(UpperCase(VarNamesR[Cnt]),iBuf);
    SpeedVar.InsertObject(iBuf,UpperCase(VarNamesR[Cnt]),Pointer(Cnt));
  end;
  for Cnt:=0 to High(VarNamesRW) do
  begin
    SpeedVar.Find(UpperCase(VarNamesRW[Cnt]),iBuf);
    SpeedVar.InsertObject(iBuf,UpperCase(VarNamesRW[Cnt]),Pointer(500+Cnt));
  end;

  StrRes:='N/A';
  _Result:='N/A';
  LPC:=10;

  SCntBase:=0;
  SCnt2Base:=0;
  SysMsgCol:=0;
  TileCount:=0;

  SkillStr:='';
  SkillBool:=False;

  FindInd:=0;
  FindModX:=0;
  FindModY:=0;

  JIndex:=1000;
  DJournal:=0;
  DJournalSave:=0;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.Free;
begin
  UOSel.Free;
  UOVar.Free;
  UOCmd.Free;
  EventObj.Free;
  StdCmd.Free;
  Vars.Free;
  ScrList.Free;
  MenuObj.Free;
  CommObj.Free;

  CS.Free;

  Par.Free;
  Par2.Free;
  ParList.Free;
  NSStack.Free;
  SpeedVar.Free;
  inherited Free;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.Clear;
begin
  CurLine:=0;
  NextLine:=0;
  ResInt:=RES_OK;
  LPC:=10;
  Brk:=False;
  Slp:=False;
  Paused:=False;

  ScrList.Clear;
  Vars.UserVars.Clear;
  Vars.NSLocal.Clear;
  Vars.NSName:='std';
  Vars.NSType:=local;

  UOCmd.IgnoreItemReset;
  MenuObj.Clear;
  NSStack.Clear;

  UOVar.IgnoreCont($FFFFFFFF);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.PlayLine;
begin
  CurLine:=NextLine;

  CS.BeginWrite;
  try
    ParseLine(ParList);
    LineInfo(CurLine);
    Interpret;
  finally
    CS.EndWrite;
  end;

  if NextLine>=ScrList.Scr.Count then ExitProc;
  CurLine:=NextLine;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.LineInfo(Line : Integer);
var
  Cnt  : Integer;
  sBuf : String;
begin
  with ScrList.Info do
  begin
    Find(IntToStr(Line)+' ',Cnt);
    if Cnt>=Count then Exit;
    if Integer(Objects[Cnt])<>Line then Exit;

    Parameterize(Strings[Cnt],Par2);

    if Par2.Count=6 then
      if Par2[1]='FOR' then
    begin
      sBuf:=GetVar(Par2[2]);
      if not IsNumber(sBuf) then Exit;
      Cnt:=SToI64Def(sBuf,0);

      if Par2[4]='-' then
      begin
        Dec(Cnt);
        SetVar(Par2[2],IntToStr(Cnt));
        if Cnt<SToI64Def(Par2[3],0) then Exit;
      end
      else begin
        Inc(Cnt);
        SetVar(Par2[2],IntToStr(Cnt));
        if Cnt>SToI64Def(Par2[3],0) then Exit;
      end;

      NextLine:=SToI64Def(Par2[5],0);
    end;

    if Par2.Count=3 then
      if Par2[1]='WHILE' then
        NextLine:=SToI64Def(Par2[2],0);

    if Par2.Count=3 then
      if Par2[1]='ELSE' then
        ElseFlag:=Par2[2]='TRUE';
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.Parameterize(Str : String; StrList : TStringList);
var
  sBuf : String;
  Cnt1 : Integer;
begin
  Str:=Trim(Str)+' ';

  for Cnt1:=1 to Length(Str) do
    if Str[Cnt1]=#9 then Str[Cnt1]:=#32;

  StrList.Clear;
  repeat
    Cnt1:=Pos(#32,Str);
    if Cnt1<1 then Break;
    sBuf:=Copy(Str,1,Cnt1-1);
    Delete(Str,1,Cnt1);
    if sBuf='' then Continue;
    if sBuf[1]=';' then Break;
    StrList.Add(sBuf);
  until False;
end;

////////////////////////////////////////////////////////////////////////////////
function TOldParser.GetParStr(Nr : Integer) : String;
var
  Cnt1 : Integer;
begin
  Result:='';
  for Cnt1:=Nr to Par.Count-1 do
    Result:=Result+Par[Cnt1]+' ';
  Result:=Trim(Result);
end;

////////////////////////////////////////////////////////////////////////////////
function TOldParser.GetCmd(Line : Integer) : String;
var
  Cnt : Integer;
begin
  Result:=UpperCase(Trim(ScrList.Scr[Line]));
  for Cnt:=1 to Length(Result) do
    if Result[Cnt] in [#9,#32,';'] then
  begin
    Result:=Copy(Result,1,Cnt-1);
    Break;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
function TOldParser.ScanForBlock : Cardinal;
var
  LCnt : Integer;
  BCnt : Integer;
  sBuf : String;
begin
  Result:=1;
  if NextLine>=ScrList.Scr.Count then Exit;
  if GetCmd(NextLine)<>'{' then Exit;
  BCnt:=1;

  LCnt:=NextLine+1;
  while LCnt<ScrList.Scr.Count do
  begin
    sBuf:=GetCmd(LCnt);
    if sBuf='{' then Inc(BCnt);
    if sBuf='}' then Dec(BCnt);
    if BCnt<1 then Break;
    Inc(LCnt);
  end;

  if BCnt>0 then Result:=1
  else Result:=LCnt-NextLine+1;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.ParseLine(PList : TParList);
var
  sBuf    : String;
  sBuf2   : String;
  Cnt1    : Integer;
  ConvRes : Boolean;
begin
  Par.Clear;
  PList.Clear;
  if (NextLine>=ScrList.Scr.Count)or(NextLine<0) then Exit;

  sBuf:=Trim(ScrList.Scr[NextLine]);
  repeat
    Inc(NextLine);
    if NextLine>=ScrList.Scr.Count then Break;
    sBuf2:=Trim(ScrList.Scr[NextLine]);
    if Copy(sBuf2,1,1)<>'+' then Break;
    Delete(sBuf2,1,1);
    sBuf:=sBuf+sBuf2;
  until False;

  Parameterize(sBuf,Par);
  if Par.Count=0 then Exit;

  sBuf:=UpperCase(Par[0]);

  for Cnt1:=Par.Count-1 downto 0 do
  begin
    if Par[Cnt1]='.' then
      if (Cnt1<Par.Count-1)and(Cnt1>0) then
    begin
      Par[Cnt1-1]:=Par[Cnt1-1]+Par[Cnt1+1];
      Par.Delete(Cnt1);
      Par.Delete(Cnt1);
      Continue;
    end;

    if IsVar(Par[Cnt1]) then
    repeat
      if Cnt1=1 then
      begin
        if sBuf='SET' then Break;
        if sBuf='FOR' then Break;
      end;

      Par[Cnt1]:=GetVar(Par[Cnt1]);

    until True;
  end;

  for Cnt1:=Par.Count-2 downto 1 do
    if Par[Cnt1]=',' then
  begin
    Par[Cnt1-1]:=Par[Cnt1-1]+Par[Cnt1+1];
    Par.Delete(Cnt1);
    Par.Delete(Cnt1);
  end;

  for Cnt1:=0 to Par.Count-1 do
  with PList do
  begin
    AddNew;
    Last.Str:=Par[Cnt1];
    Last.StrU:=UpperCase(Par[Cnt1]);
    Last.Int:=SToI64Def(Par[Cnt1],0,ConvRes);
    Last.IntValid:=ConvRes;
    Last.CardValid:=ConvRes and (Last.Int>=0);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
function TOldParser.Delay(ms : Cardinal) : Boolean;
var
  iBuf      : Cardinal;
  iBufOld   : Cardinal;
  Start     : Cardinal;
begin
  Result:=True;

  Start:=GetTickCount;
  iBufOld:=Start;
  while not Brk do
  begin
    iBuf:=GetTickCount;

    if Slp then
      Start:=Start+iBuf-iBufOld;
    Paused:=Slp;
    iBufOld:=iBuf;

    if iBuf>=Start+ms then Exit;
    if iBuf<Start then Exit;

    CS.EndWrite;
    Sleep(1);
    CS.BeginWrite;
  end;

  Brk:=False;
  Result:=False;
end;

////////////////////////////////////////////////////////////////////////////////
/// SysVars ////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

function TOldParser.FindDist(var Dist : Cardinal) : Boolean;
var
  Buf : Cardinal;
begin
  Result:=False;
  Dist:=0;
  with UOVar,UOCmd.ItemRes do
  begin
    if ItemKind<>1 then Exit;
    Buf:=Abs(CharPosX-ItemX);
    Dist:=Abs(CharPosY-ItemY);
    if Dist<Buf then Dist:=Buf;
    Result:=True;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
function TOldParser.GetVar(Name : String) : String;
var
  iBuf : Integer;
  c    : Cardinal;
label Leave;
begin
  CS.BeginWrite;

  if Copy(Name,1,1)<>'#' then
  begin
    Result:=Vars.GetVar(Name);
    goto Leave;
  end;

  Result:='N/A';
  Name:=UpperCase(Name);
  Delete(Name,1,1);

  if SpeedVar.Find(Name,iBuf) then
    iBuf:=Cardinal(SpeedVar.Objects[iBuf])
  else goto Leave;

  UOVar.VarRes:=True;
  with UOVar do
  case iBuf of
    000: Result:=IntToStr   (UOSel.Cnt    );
    001: Result:=IntToStr   (UOSel.Nr     );
    002: Result:=FormatDateTime('hhnnss',Now);
    003: Result:=FormatDateTime('yymmdd',Now);
    004: Result:=IntToStr   (SysTime      );
    005: Result:=IntToStr   (Random(1000) );
    006: Result:=UScore     (OSVer        );
    060: Result:=IntToStr   (CursorX      );
    061: Result:=IntToStr   (CursorY      );
    077: Result:=            StdCmd.DispRes;
    091: Result:=            Vars.NSName;
    092: if Vars.NSType=local then Result:='local'
         else Result:='global';
    093: Result:=            '-1'          ;
    094: Result:=            '0'           ;
    095: Result:=            ' '           ;
    096: Result:=            ';'           ;
    097: Result:=            '.'           ;
    099: Result:=            '1_50_00'     ;
    100: if MCDefault then  Result:='SYS_EXEC_SEND'
         else               Result:='SYS_DMC_EXEC_SEND';
    102: //if ScrList.ScrName<>'' then
         //  Result:=ExtractPath(ScrList.ScrName)
         {else} Result:=ExtractPath(ParamStr(0));
    500: Result:=IntToStr   (GetTickCount div 1000 - SCntBase);
    501: Result:=IntToStr   (GetTickCount div 100 - SCnt2Base);
    525: Result:=            _Result       ;
    526: Result:=            StrRes        ;
    527: Result:=            MenuObj.MenuButton;
    528: Result:=            MenuObj.MenuRes;
    529: Result:=IntToStr   (LPC          );
    530: Result:=            CommObj.SendHeader;
  end;

  if UOSel.Nr>0 then
    with UOVar,UOCmd do
  case iBuf of
    007: Result:=IntToStr   (CharPosX     );
    008: Result:=IntToStr   (CharPosY     );
    009: Result:=IntToStr   (CharPosZ     );
    010: Result:=CardToSys26(CharID       );
    011: if CharGhost then Result:='yes' else Result:='no';
    012: Result:=            CharStatus    ;
    013: Result:=IntToStr   (CharDir      );
    014: Result:={UScore}   (CharName     );
    015: Result:=IntToStr   (Sex          );
    016: Result:=IntToStr   (Str          );
    017: Result:=IntToStr   (MaxWeight    );
    018: Result:=IntToStr   (Dex          );
    019: Result:=IntToStr   (Int          );
    020: Result:=IntToStr   (Hits         );
    021: Result:=IntToStr   (MaxHits      );
    022: Result:=IntToStr   (Stamina      );
    023: Result:=IntToStr   (MaxStam      );
    024: Result:=IntToStr   (Mana         );
    025: Result:=IntToStr   (MaxMana      );
    026: Result:=IntToStr   (Gold         );
    027: Result:=IntToStr   (Weight       );
    028: Result:=IntToStr   (MaxStats     );
    029: Result:=IntToStr   (AR           );
    030: Result:=IntToStr   (Followers    );
    031: Result:=IntToStr   (MaxFol       );
    032: Result:=IntToStr   (FR           );
    033: Result:=IntToStr   (CR           );
    034: Result:=IntToStr   (PR           );
    035: Result:=IntToStr   (ER           );
    036: Result:=IntToStr   (Luck         );
    037: Result:=IntToStr   (MaxDmg       );
    038: Result:=IntToStr   (MinDmg       );
    039: Result:=IntToStr   (TP           );
    040: Result:={UScore}   (Shard        );
    041: begin
           GetCont(0);
           Result:=IntToStr(ContSizeX)+'_'+IntToStr(ContSizeY);
         end;
    042: begin
           GetCont(0);
           Result:=CardToSys26(ContKind);
         end;
    043: begin
           GetCont(0);
           Result:=CardToSys26(ContID);
         end;
    044: begin
           GetCont(0);
           Result:=CardToSys26(ContType);
         end;
    045: begin
           GetCont(0);
           Result:=UScore(ContName);
         end;
    046: Result:=            CliLang       ;
    047: Result:=            CliVer        ;
    048: Result:=IntToStr   (Byte(CliLogged));
    049: Result:=IntToStr   (CursKind     );
    050: Result:=IntToStr   (EnemyHits    );
    051: begin
           Result:=CardToSys26(EnemyID      );
           if Result='YC' then Result:='N/A';
         end;
    052: Result:=CardToSys26(LObjectType  );
    053: Result:=CardToSys26(LLiftedID    );
    054: Result:=CardToSys26(LLiftedType  );
    055: Result:=IntToStr   (LLiftedKind  );
    056: Result:=UScore     (SysMsg       );
    057: begin
           GetSkill(SkillStr);
           if SkillBool then Result:=IntToStr(SkillReal)
           else Result:=IntToStr(SkillNorm);
         end;
    058: begin
           GetSkill(SkillStr);
           Result:=IntToStr(SkillCap);
         end;
    059: begin
           GetSkill(SkillStr);
           case SkillLock of
             0: Result:='up';
             1: Result:='down';
             2: Result:='locked';
           end;
         end;
    062: Result:=CardToSys26(ItemRes.ItemID   );
    063: Result:=CardToSys26(ItemRes.ItemType );
    064: if ItemRes.ItemKind=0 then
           Result:=IntToStr(ItemRes.ItemX+FindModX)
         else Result:=IntToStr(ItemRes.ItemX);
    065: if ItemRes.ItemKind=0 then
           Result:=IntToStr(ItemRes.ItemY+FindModY)
         else Result:=IntToStr(ItemRes.ItemY);
    066: Result:=IntToStr   (ItemRes.ItemZ    );
    067: Result:=IntToStr   (ItemRes.ItemKind );
    068: Result:=IntToStr   (ItemRes.ItemStack);
    069: begin
           GetCont(0);
           Result:=CardToSys26(ItemRes.ContID);
         end;
    070: Result:=IntToStr   (ItemRes.ItemRep  );
    071: Result:=IntToStr   (ItemRes.ItemCol  );
    072: Result:=IntToStr   (ItemCnt          );
    073: begin
           if FindDist(c) then Result:=IntToStr(c)
           else Result:='N/A';
         end;
    074: Result:=IntToStr   (PixCol       );
    075: begin
           Result:=UScore   (JournalStr   );
           VarRes:=Result<>'';
         end;
    076: Result:=IntToStr   (JournalCol   );
    078: Result:=IntToStr   (ShopPos      );
    079: Result:=IntToStr   (ShopCnt      );
    080: Result:=CardToSys26(ShopType     );
    081: Result:=CardToSys26(ShopID       );
    082: Result:=IntToStr   (ShopMax      );
    083: Result:=IntToStr   (ShopPrice    );
    084: Result:=UScore     (ShopName     );
    085: Result:=IntToStr   (TileCount    );
    086: Result:=IntToStr   (TileType     );
    087: Result:=IntToStr   (TileZ        );
    088: Result:=UScore     (TileName     );
    089: Result:=UScore     (GetTileFlags );
    090: begin
           UpdateJournal;
           Result:=IntToStr (JIndex       );
         end;
    098: begin
           Result:=EventObj.PropStr1+'$';
           if EventObj.PropStr2<>'' then
             Result:=Result+EventObj.PropStr2+'$';
           Result:=ReplaceStr(Result,#13#10,'$');
         end;
    101: Result:=CardToSys26(BackpackID   );
    103: begin
           GetCont(0);
           Result:=IntToStr(ContSizeX);
         end;
    104: begin
           GetCont(0);
           Result:=IntToStr(ContSizeY);
         end;
    105: Result:=CardToSys26(CharType     );
    106: begin
           GetCont(0);
           Result:=IntToStr(ContHP);
         end;
    502: Result:=IntToStr   (LShard       );
    503: Result:=IntToStr   (ContPosX     );
    504: Result:=IntToStr   (ContPosY     );
    505: Result:=IntToStr   (NextCPosX    );
    506: Result:=IntToStr   (NextCPosY    );
    507: Result:=IntToStr   (Byte(TargCurs));
    508: Result:=IntToStr   (CliXRes      );
    509: Result:=IntToStr   (CliYRes      );
    510: Result:=IntToStr   (CliLeft      );
    511: Result:=IntToStr   (CliTop       );
    512: Result:=IntToStr   (LSpell       );
    513: Result:=IntToStr   (LSkill       );
    514: Result:=IntToStr   (LTargetKind  );
    515: Result:=IntToStr   (LTargetTile  );
    516: Result:=IntToStr   (LTargetX     );
    517: Result:=IntToStr   (LTargetY     );
    518: Result:=IntToStr   (LTargetZ     );
    519: Result:=CardToSys26(LTargetID    );
    520: Result:=CardToSys26(LHandID      );
    521: Result:=CardToSys26(RHandID      );
    522: Result:=CardToSys26(LObjectID    );
    523: Result:=IntToStr   (FindInd      );
    524: Result:=IntToStr(FindModX)+'_'+IntToStr(FindModY);
    531: Result:=IntToStr   (SysMsgCol    );
    532: Result:=CliTitle;
  end;
  if UOVar.VarRes=False then Result:='N/A';

  Leave:
  CS.EndWrite;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.SetVar(Name, Value : String);
var
  Cnt     : Integer;
  iBuf    : Integer;
  i       : Int64;
  c       : Cardinal;
  ConvRes : Boolean;
label Leave;
begin
  CS.BeginWrite;
  i:=0;
  c:=0;

  if Copy(Name,1,1)<>'#' then
  begin
    Vars.SetVar(Name,Value);
    Goto Leave;
  end;

  Name:=UpperCase(Name);
  Delete(Name,1,1);

  iBuf:=-1;
  for Cnt:=500 to 500+High(VarNamesRW) do
    if UpperCase(VarNamesRW[Cnt-500])=Name then
  begin
    iBuf:=Cnt;
    Break;
  end;
  if iBuf<0 then Goto Leave;

  case iBuf of
    500..518,523,529,531 :
      begin
        i:=SToI64Def(Value,0,ConvRes);
        if not ConvRes then Goto Leave;
      end;
    519..522 :
      begin
        c:=Sys26ToCard(Value,ConvRes);
        //if not ConvRes then Goto Leave;
      end;
  end;

  with UOVar,UOCmd do
  case iBuf of
    500: SCntBase:=GetTickCount div 1000 - i;
    501: SCnt2Base:=GetTickCount div 100 - i;
    502: LShard     :=i;
    503: ContPosX   :=i;
    504: ContPosY   :=i;
    505: NextCPosX  :=i;
    506: NextCPosY  :=i;
    507: TargCurs   :=Boolean(i);
    508: CliXRes    :=i;
    509: CliYRes    :=i;
    510: CliLeft    :=i;
    511: CliTop     :=i;
    512: LSpell     :=i;
    513: LSkill     :=i;
    514: LTargetKind:=i;
    515: LTargetTile:=i;
    516: LTargetX   :=i;
    517: LTargetY   :=i;
    518: LTargetZ   :=i;
    519: LTargetID  :=c;
    520: LHandID    :=c;
    521: RHandID    :=c;
    522: LObjectID  :=c;
    523: begin
           FindInd:=i;
           GetItem(FindInd-1);
         end;
    524: begin
           c:=Pos('_',Value);
           FindModX:=StrToIntDef(Copy(Value,1,c-1),0);
           FindModY:=StrToIntDef(Copy(Value,c+1,99),0);
         end;
    525: _Result    :=Value;
    526: StrRes     :=Value;
    527: MenuObj.MenuButton:=Value;
    528: MenuObj.MenuRes:=Value;
    529: if i>0 then
           LPC      :=i;
    530: CommObj.SendHeader:=Value;
    531: SysMsgCol:=i;
    532: CliTitle:=Value;
  end;

  Leave:
  CS.EndWrite;
end;

////////////////////////////////////////////////////////////////////////////////
function TOldParser.GetVarDump : String;
var
  Cnt  : Integer;
  List : TStringList;
begin
  CS.BeginWrite;

  List:=TStringList.Create;
  Result:='';

  for Cnt:=0 to SpeedVar.Count-1 do
    Result:=Result+'#'+SpeedVar[Cnt]+': '+GetVar('#'+SpeedVar[Cnt])+#13#10;

  List.Text:=Vars.UserVars.ListVars('');
  for Cnt:=0 to List.Count-1 do
    Result:=Result+List[Cnt]+': '+Vars.UserVars.GetVar(List[Cnt])+#13#10;

  List.Text:=Vars.NSLocal.ListVars('!');
  for Cnt:=0 to List.Count-1 do
    Result:=Result+'!L~'+List[Cnt]+': '+Vars.NSLocal.GetVar('!'+List[Cnt])+#13#10;

  List.Text:=Vars.NSGlobal.ListVars('!');
  for Cnt:=0 to List.Count-1 do
    Result:=Result+'!G~'+List[Cnt]+': '+Vars.NSGlobal.GetVar(List[Cnt])+#13#10;

  Delete(Result,Length(Result)-1,2);
  List.Free;

  CS.EndWrite;
end;

////////////////////////////////////////////////////////////////////////////////
/// Interpreter ////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

const
  Cmd1 : Array[0..33] of String = (
  'Pause','Halt','Stop','Wait','StopCD','PlayCD','Set','If','Else','GoTo',
  'OnHotkey','Shutdown','Execute','Display','DeleteVar','Sleep','Terminate',
  'UOXL','Sound','Str','NameSpace','Menu','Return','GoSub','Sub','Call',
  'Exit','For','Send','While','Until','Break','Continue','LinesPerCycle');

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.Interpret;
var
  Cnt     : Integer;
begin
  ResInt:=RES_OK;
  if ParList.Count=0 then Exit;

  for Cnt:=0 to High(Cmd1) do
    if ParList[0].StrU=UpperCase(Cmd1[Cnt]) then Break;

  case Cnt of
    00 : ResInt:=RES_PAUSE;
    01 : ResInt:=RES_STOP;
    02 : ResInt:=RES_STOP;
    03 : WaitProc;
    06 : SetProc;
    07 : IfProc;
    08 : ElseProc;
    09 : GoToProc;
    10 : OnHotkeyProc;
    11 : ShutdownProc;
    12 : ExecuteProc;
    13 : begin
           CS.EndWrite;
           DisplayProc;
           CS.BeginWrite;
         end;
    14 : DeleteVarProc;
    15 : SleepProc;
    16 : TerminateProc;
    17 : UOXLProc;
    18 : SoundProc;
    19 : StrProc;
    20 : NameSpaceProc;
    21 : begin
           CS.EndWrite;
           TThread.Synchronize(nil,MenuProc);
           CS.BeginWrite;
         end;
    22 : ReturnProc;
    23 : GoSubProc;
    24 : SubProc;
    25 : CallProc;
    26 : ExitProc;
    27 : ForProc;
    28 : SendProc;
    29 : WhileProc;
    30 : UntilProc;
    31 : ContinueBreakProc;
    32 : ContinueBreakProc;
    33 : LinesPerCycleProc;
  end;

  if UOSel.Nr=0 then Exit;

  InterpretUO;
end;

////////////////////////////////////////////////////////////////////////////////
/// Interpreter Procs //////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

procedure TOldParser.ExecuteProc;
var
  sBuf : String;
begin
  if ParList.Count<2 then Exit;
  sBuf:=ParList[1].Str;
  StdCmd.Execute(sBuf,GetParStr(2),True);
  StdCmd.Wait(40*50,0);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.ShutdownProc;
var
  Force : Boolean;
begin
  Force:=False;
  if ParList.Count>1 then
    Force:=ParList[1].StrU='FORCE';
  StdCmd.ShutDown(Force);
  StdCmd.Wait(40*50,0);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.WaitProc;
var
  D1,D2 : Cardinal;
  Cnt   : Integer;
begin
  if ParList.Count<2 then Exit;
  D1:=0;
  D2:=0;

  repeat
    if ParList[1].CardValid then
      D1:=ParList[1].Int;
    Cnt:=Pos('S_',ParList[1].StrU+'_');
    if Cnt>0 then
    begin
      Delete(ParList[1].Str,Cnt,1);
      D1:=SToCDef(ParList[1].Str,0)*20;
    end;

    if ParList.Count<3 then Break;
    if ParList[2].CardValid then
      D2:=ParList[2].Int;
    Cnt:=Pos('S_',ParList[2].StrU+'_');
    if Cnt>0 then
    begin
      Delete(ParList[2].Str,Cnt,1);
      D2:=SToCDef(ParList[2].Str,0)*20;
    end;
  until True;

  StdCmd.Wait(D1*50,D2*50);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.SoundProc;
begin
  StdCmd.SoundProc(GetParStr(1));
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.TerminateProc;
begin
  if ParList.Count<2 then Exit;
  if ParList[1].StrU='EUO' then
    ResInt:=RES_CLOSE;
  if ParList[1].StrU='UO' then
  begin
    UOCmd.CloseClient;
    StdCmd.Wait(20*50,0);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.SleepProc;
begin
  if ParList.Count>1 then
    if ParList[1].CardValid then
      StdCmd.Wait(ParList[1].Int,0);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.GetUOTitleProc;
begin
  StrRes:=StdCmd.GetCliTitle(UOSel.HWnd);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.SetUOTitleProc;
begin
  if ParList.Count>1 then
    StdCmd.SetCliTitle(UOSel.HWnd,GetParStr(1));
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.DisplayProc;
var
  Cnt  : Integer;
  sBuf : String;
begin
  if ParList.Count<2 then Exit;

  Cnt:=1;
  sBuf:='OK';
  if ParList.Count>2 then
  begin
    if ParList[1].StrU='OK' then Cnt:=2;
    if ParList[1].StrU='OKCANCEL' then Cnt:=2;
    if ParList[1].StrU='YESNO' then Cnt:=2;
    if ParList[1].StrU='YESNOCANCEL' then Cnt:=2;
  end;
  if Cnt=2 then sBuf:=ParList[1].StrU;

  StdCmd.Display(UOSel.HWnd,GetParStr(Cnt),sBuf);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.LinesPerCycleProc;
begin
  if ParList.Count>1 then SetVar('#LPC',ParList[1].StrU);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.ContinueBreakProc;
var
  Cnt  : Integer;
  Cnt2 : Integer;
  Cnt3 : Integer;
  sBuf : String;
begin
  Cnt2:=1;
  Cnt:=NextLine;
  repeat
    if Cnt>=ScrList.Scr.Count then Exit;
    sBuf:=GetCmd(Cnt);

    if Length(sBuf) in [1,5,6] then
    begin
      if sBuf='}' then Dec(Cnt2)
      else if sBuf='{' then Inc(Cnt2)
      else if sBuf='UNTIL' then Dec(Cnt2)
      else if sBuf='REPEAT' then Inc(Cnt2);
    end;

    if Cnt2<1 then
    begin
      Inc(Cnt2);
      if sBuf='UNTIL' then Break;
      ScrList.Info.Find(IntToStr(Cnt)+' ',Cnt3);
      if Cnt3<ScrList.Info.Count then
        if Integer(ScrList.Info.Objects[Cnt3])=Cnt then Break;
    end;

    Inc(Cnt);
  until False;

  if ParList[0].StrU='BREAK' then Inc(Cnt);
  NextLine:=Cnt;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.UntilProc;
var
  Cnt  : Integer;
  Cnt2 : Integer;
  sBuf : String;
begin
  if ParList.Count<2 then Exit;
  Eval(1);
  if ParList[1].Int=-1 then Exit;

  Cnt2:=1;
  Cnt:=NextLine-2;
  while Cnt>=0 do
  begin
    sBuf:=GetCmd(Cnt);
    if sBuf='UNTIL' then Inc(Cnt2);
    if sBuf='REPEAT' then Dec(Cnt2);
    if Cnt2<1 then Break;
    Dec(Cnt);
  end;

  if Cnt>=0 then NextLine:=Cnt+1;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.WhileProc;
var
  Cnt  : Integer;
  Cnt2 : Integer;
begin
  if ParList.Count<2 then Exit;
  Cnt:=NextLine-1+ScanForBlock;

  Eval(1);
  if ParList[1].Int<>-1 then
  begin
    NextLine:=Cnt+1;
    Exit;
  end;

  ScrList.Info.Find(IntToStr(Cnt)+' ',Cnt2);
  if Cnt2<ScrList.Info.Count then
    if Integer(ScrList.Info.Objects[Cnt2])=Cnt then
      ScrList.Info.Delete(Cnt2);

  ScrList.Info.InsertObject(Cnt2,IntToStr(Cnt)+' WHILE '+IntToStr(NextLine-1),Pointer(Cnt));
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.SendProc;
var
  Cnt  : Integer;
  Port : Cardinal;
begin
  if ParList.Count<4 then Exit;
  Cnt:=Pos('HTTPPOST',ParList[1].StrU);
  if Cnt<1 then Exit;
  Port:=SToI64Def(Copy(ParList[1].Str,Cnt+8,9),80);

  CommObj.HTTPPost(ParList[2].Str,ParList[3].Str,GetParStr(4),Port);
  while CommObj.Stat<>Done do
    if not Delay(1) then Exit;

  if Copy(ParList[1].StrU,1,Cnt-1)='DEBUG' then
  begin
    MessageBox(0,@CommObj.SentHeader[1],'Send - Outgoing Packet',0);
    MessageBox(0,@CommObj.StrRes[1],'Send - Incoming Packet',0);
  end;

  CommObj.CropHeader;
  if CommObj.StrRes='' then Exit;
  ScrList.AddCall(NextLine,'send');
  ScrList.Scr.Text:=CommObj.StrRes;
  NextLine:=0;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.ForProc;
var
  Cnt  : Integer;
  Cnt2 : Integer;
  sBuf : String;
begin
  if ParList.Count<4 then Exit;
  if not IsVar(ParList[1].Str) then Exit;
  if not ParList[2].IntValid then Exit;
  if not ParList[3].IntValid then Exit;

  Cnt:=NextLine-1+ScanForBlock;
  SetVar(ParList[1].Str,ParList[2].Str);

  sBuf:='+';
  if ParList[2].Int>ParList[3].Int then sBuf:='-';

  ScrList.Info.Find(IntToStr(Cnt)+' ',Cnt2);
  if Cnt2<ScrList.Info.Count then
    if Integer(ScrList.Info.Objects[Cnt2])=Cnt then
      ScrList.Info.Delete(Cnt2);

  ScrList.Info.InsertObject(Cnt2,IntToStr(Cnt)+' FOR '+ParList[1].Str+' '+
    ParList[3].Str+' '+sBuf+' '+IntToStr(NextLine),Pointer(Cnt));
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.ExitProc;
begin
  if ScrList.CallLevel>0 then
  begin
    NextLine:=ScrList.DelCall;
  end
  else NextLine:=0;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.CallProc;
var
  Cnt   : Integer;
  sBuf  : String;
  sBuf2 : String;
begin
  if ParList.Count<2 then Exit;

  sBuf:=ParList[1].Str;
  if not IsAbsolutePath(sBuf) then
    sBuf:=GetVar('#curpath')+sBuf;

  if not FileExists(sBuf) then
  repeat
    sBuf2:=sBuf;
    sBuf:=sBuf2+'.txt';
    if FileExists(sBuf) then Break;
    sBuf:=sBuf2+'.euo';
    if FileExists(sBuf) then Break;
    Exit;
  until True;

  ScrList.AddCall(NextLine,sBuf);
  ScrList.Scr.LoadFromFile(sBuf);
  NextLine:=0;

  SetVar('%0',IntToStr(ParList.Count-2));
  for Cnt:=1 to ParList.Count-2 do
    SetVar('%'+IntToStr(Cnt),ParList[Cnt+1].Str);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.SubProc;
var
  Cnt : Integer;
begin
  Cnt:=ScanForBlock;
  if Cnt>1 then
  begin
    NextLine:=NextLine+Cnt;
    Exit;
  end;

  for Cnt:=NextLine to ScrList.Scr.Count-1 do
    if GetCmd(Cnt)='RETURN' then
  begin
    NextLine:=Cnt+1;
    Break;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.GoSubProc;
var
  Cnt  : Integer;
  Cnt2 : Integer;
begin
  if ParList.Count<2 then Exit;

  for Cnt:=ScrList.Scr.Count-1 downto 0 do
    if GetCmd(Cnt)='SUB' then
  begin
    Parameterize(ScrList.Scr[Cnt],Par2);
    if Par2.Count<2 then Continue;
    if UpperCase(Par2[1])<>ParList[1].StrU then Continue;

    ScrList.AddSub(NextLine,Par2[1]);
    NextLine:=Cnt+1;

    SetVar('%0',IntToStr(ParList.Count-2));
    for Cnt2:=1 to ParList.Count-2 do
      SetVar('%'+IntToStr(Cnt2),ParList[Cnt2+1].Str);

    Exit;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.ReturnProc;
begin
  with ScrList do
  begin
    if SubLevel<1 then Exit;
    NextLine:=DelSub;
  end;

  _Result:='N/A';
  if ParList.Count<2 then Exit;
  Eval(1);
  _Result:=ParList[1].Str;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.MenuProc;
var
  iBuf    : Integer;
  iBuf2   : Integer;
  ConvRes : Boolean;
begin
  if ParList.Count<2 then Exit;

  if ParList[1].StrU='SHOW' then
  begin
    repeat
      if ParList.Count<4 then Break;
      if not ParList[2].IntValid then Break;
      if not ParList[3].IntValid then Break;
      MenuObj.Form.Left:=ParList[2].Int;
      MenuObj.Form.Top:=ParList[3].Int;
    until True;
    MenuObj.Form.Show;
  end

  else if ParList[1].StrU='HIDE' then MenuObj.Form.Close

  else if ParList[1].StrU='HIDEEUO' then MenuObj.Form.HideEUO

  else if ParList[1].StrU='CLEAR' then MenuObj.Clear

  else if ParList[1].StrU='DELETE' then
  begin
    if ParList.Count>2 then MenuObj.Del(ParList[2].Str);
  end

  else if ParList[1].StrU='ACTIVATE' then
  begin
    if ParList.Count>2 then MenuObj.Activate(ParList[2].Str);
  end

  else if ParList[1].StrU='GET' then
  begin
    if ParList.Count>2 then MenuObj.Get(ParList[2].Str);
  end

  else if ParList[1].StrU='GETNUM' then
  begin
    if ParList.Count<3 then Exit;
    MenuObj.Get(ParList[2].Str);
    if not IsNumber(MenuObj.MenuRes) then
      if ParList.Count>3 then MenuObj.MenuRes:=ParList[3].Str;
  end

  else if ParList[1].StrU='SET' then
  begin
    if ParList.Count>2 then MenuObj._Set(ParList[2].Str,GetParStr(3));
  end

  else if ParList[1].StrU='WINDOW' then
  begin
    if ParList.Count<3 then Exit;

    if ParList[2].StrU='SIZE' then
    begin
      if ParList.Count<5 then Exit;
      if not(ParList[3].CardValid and ParList[4].CardValid) then Exit;
      MenuObj.Form.ClientWidth:=ParList[3].Int;
      MenuObj.Form.ClientHeight:=ParList[4].Int;
    end

    else if ParList[2].StrU='COLOR' then
    begin
      if ParList.Count<4 then Exit;
      iBuf:=SToCol(ParList[3].Str,ConvRes);
      if ConvRes then MenuObj.Form.Color:=iBuf;
    end

    else if ParList[2].StrU='TITLE' then
    begin
        MenuObj.Form.Caption:=GetParStr(3);
    end

    else if ParList[2].StrU='TRANSPARENT' then
    begin
      if ParList.Count>3 then
        if ParList[3].CardValid and (ParList[3].Int<101) then
            MenuObj.Form.SetTransparency(ParList[3].Int*235 div 100 + 20);
    end;
  end

  else if ParList[1].StrU='FONT' then
  begin
    if ParList.Count<3 then Exit;

    if ParList[2].StrU='NAME' then
    begin
      if ParList.Count>3 then MenuObj.FontName:=GetParStr(3);
    end

    else if ParList[2].StrU='ALIGN' then
    begin
      if ParList.Count<4 then Exit;
      if ParList[3].StrU='LEFT' then MenuObj.FontAlign:=taLeftJustify;
      if ParList[3].StrU='RIGHT' then MenuObj.FontAlign:=taRightJustify;
      if ParList[3].StrU='CENTER' then MenuObj.FontAlign:=taCenter;
    end

    else if ParList[2].StrU='SIZE' then
    begin
      if ParList.Count>3 then
        if ParList[3].CardValid then
          MenuObj.FontSize:=ParList[3].Int;
    end

    else if ParList[2].StrU='COLOR' then
    begin
      if ParList.Count<4 then Exit;
      iBuf:=SToCol(ParList[3].Str,ConvRes);
      if ConvRes then MenuObj.FontColor:=iBuf;
    end

    else if ParList[2].StrU='BGCOLOR' then
    begin
      if ParList.Count<4 then Exit;
      iBuf:=SToCol(ParList[3].Str,ConvRes);
      if ConvRes then MenuObj.FontBG:=iBuf;
    end

    else if ParList[2].StrU='STYLE' then
      with MenuObj do
    begin
      FontStyle:=[];
      if ParList.Count<4 then Exit;
      if Pos('B',ParList[3].StrU)>0 then FontStyle:=FontStyle+[fsBold];
      if Pos('I',ParList[3].StrU)>0 then FontStyle:=FontStyle+[fsItalic];
      if Pos('U',ParList[3].StrU)>0 then FontStyle:=FontStyle+[fsUnderline];
      if Pos('S',ParList[3].StrU)>0 then FontStyle:=FontStyle+[fsStrikeOut];
    end

    else if ParList[2].StrU='TRANSPARENT' then
    begin
      if ParList.Count>3 then
        if ParList[3].IntValid then
          MenuObj.FontTrans:=ParList[3].Int<>0;
    end;
  end

  else if ParList[1].StrU='TEXT' then
  begin
    if ParList.Count<5 then Exit;
    if not(ParList[3].IntValid and ParList[4].IntValid) then Exit;
    MenuObj.TextCreate(ParList[2].Str,ParList[3].Int,ParList[4].Int,GetParStr(5));
  end

  else if ParList[1].StrU='BUTTON' then
  begin
    if ParList.Count<7 then Exit;
    if not(ParList[3].IntValid and ParList[4].IntValid) then Exit;
    if not(ParList[5].CardValid and ParList[6].CardValid) then Exit;
    MenuObj.ButtonCreate(ParList[2].Str,ParList[3].Int,ParList[4].Int,
      ParList[5].Int,ParList[6].Int,GetParStr(7));
  end

  else if ParList[1].StrU='EDIT' then
  begin
    if ParList.Count<6 then Exit;
    if not(ParList[3].IntValid and ParList[4].IntValid) then Exit;
    if not ParList[5].CardValid then Exit;
    MenuObj.EditCreate(ParList[2].Str,ParList[3].Int,ParList[4].Int,
      ParList[5].Int,GetParStr(6));
  end

  else if ParList[1].StrU='CHECK' then
  begin
    if ParList.Count<8 then Exit;
    if not(ParList[3].IntValid and ParList[4].IntValid) then Exit;
    if not(ParList[5].CardValid and ParList[6].CardValid) then Exit;
    if not ParList[7].IntValid then Exit;
    MenuObj.CheckCreate(ParList[2].Str,ParList[3].Int,ParList[4].Int,
      ParList[5].Int,ParList[6].Int,ParList[7].Int<>0,GetParStr(8));
  end

  else if ParList[1].StrU='SHAPE' then
  begin
    if ParList.Count<13 then Exit;
    if not(ParList[3].IntValid and ParList[4].IntValid) then Exit;
    if not(ParList[5].IntValid and ParList[6].IntValid) then Exit;
    if not(ParList[7].CardValid and ParList[8].CardValid) then Exit;
    if not(ParList[9].CardValid and ParList[11].CardValid) then Exit;
    iBuf:=SToCol(ParList[10].Str,ConvRes);
    if not ConvRes then Exit;
    iBuf2:=SToCol(ParList[12].Str,ConvRes);
    if not ConvRes then Exit;
    MenuObj.ShapeCreate(ParList[2].Str,ParList[3].Int,ParList[4].Int,
      ParList[5].Int,ParList[6].Int,ParList[7].Int,ParList[8].Int,
      ParList[9].Int,iBuf,ParList[11].Int,iBuf2);
  end

  else if (ParList[1].StrU='COMBO')or(ParList[1].StrU='LIST') then
  begin
    if ParList.Count<3 then Exit;

    if ParList[2].StrU='ADD' then
    begin
      if ParList.Count<4 then Exit;
      MenuObj.ComboListAdd(ParList[3].Str,GetParStr(4))
    end

    else if ParList[2].StrU='SELECT' then
    begin
      if ParList.Count<5 then Exit;
      if not ParList[4].IntValid then Exit;
      MenuObj.ComboListSelect(ParList[3].Str,ParList[4].Int);
    end

    else if ParList[2].StrU='CLEAR' then
    begin
      if ParList.Count<4 then Exit;
      MenuObj.ComboListClear(ParList[3].Str);
    end

    else if ParList[2].StrU='CREATE' then
    begin
      if ParList.Count<7 then Exit;
      if not(ParList[4].IntValid and ParList[5].IntValid) then Exit;
      if not ParList[6].CardValid then Exit;

      if ParList[1].StrU='COMBO' then
        MenuObj.ComboCreate(ParList[3].Str,ParList[4].Int,ParList[5].Int,ParList[6].Int);

      if ParList.Count<8 then Exit;
      if not ParList[7].CardValid then Exit;

      if ParList[1].StrU='LIST' then
        MenuObj.ListCreate(ParList[3].Str,ParList[4].Int,ParList[5].Int,
          ParList[6].Int,ParList[7].Int);
    end;
  end

  else if ParList[1].StrU='IMAGE' then
  begin
    if ParList.Count<6 then Exit;
    if not(ParList[4].IntValid and ParList[5].IntValid) then Exit;

    if ParList[2].StrU='POS' then
      if ParList.Count>7 then
      begin
        if ParList[6].IntValid and ParList[7].IntValid then
          MenuObj.ImagePos(ParList[3].Str,ParList[4].Int,ParList[5].Int,
            ParList[6].Int,ParList[7].Int);
      end
      else MenuObj.ImagePos(ParList[3].Str,ParList[4].Int,ParList[5].Int);

    if ParList.Count<7 then Exit;

    if ParList[2].StrU='PIX' then
    begin
      iBuf:=SToCol(ParList[6].Str,ConvRes);
      if ConvRes then
        MenuObj.ImagePix(ParList[3].Str,ParList[4].Int,ParList[5].Int,iBuf);
    end;

    if ParList[2].StrU='FLOODFILL' then
    begin
      iBuf:=SToCol(ParList[6].Str,ConvRes);
      if ConvRes then
        MenuObj.ImageFloodFill(ParList[3].Str,ParList[4].Int,ParList[5].Int,iBuf);
    end;

    if ParList[2].StrU='PIXLINE' then
      MenuObj.ImagePixLine(ParList[3].Str,ParList[4].Int,ParList[5].Int,ParList[6].Str);

    if ParList[2].StrU='FILE' then
      MenuObj.ImageFile(ParList[3].Str,ParList[4].Int,ParList[5].Int,ParList[6].Str);

    if ParList.Count<8 then Exit;
    if not(ParList[6].IntValid and ParList[7].IntValid) then Exit;

    if ParList[2].StrU='CREATE' then
      MenuObj.ImageCreate(ParList[3].Str,ParList[4].Int,ParList[5].Int,
        ParList[6].Int,ParList[7].Int);

    if ParList.Count<9 then Exit;
    iBuf:=SToCol(ParList[8].Str,ConvRes);
    if not ConvRes then Exit;

    if ParList[2].StrU='LINE' then
      if ParList.Count>9 then
      begin
        if ParList[9].IntValid then MenuObj.ImageLine(ParList[3].Str,
          ParList[4].Int,ParList[5].Int,ParList[6].Int,ParList[7].Int,
          iBuf,ParList[9].Int);
      end
      else MenuObj.ImageLine(ParList[3].Str,ParList[4].Int,ParList[5].Int,
             ParList[6].Int,ParList[7].Int,iBuf);

    if ParList.Count<10 then Exit;
    iBuf2:=1;
    if ParList.Count>10 then
      if ParList[10].IntValid then
        iBuf2:=ParList[10].Int;

    if ParList[2].StrU='ELLIPSE' then MenuObj.ImageEllipse(ParList[3].Str,
      ParList[4].Int,ParList[5].Int,ParList[6].Int,ParList[7].Int,iBuf,
      ParList[9].Int<>0,iBuf2);

    if ParList[2].StrU='RECTANGLE' then MenuObj.ImageRectangle(ParList[3].Str,
      ParList[4].Int,ParList[5].Int,ParList[6].Int,ParList[7].Int,iBuf,
      ParList[9].Int<>0,iBuf2);
  end

  else if ParList[1].StrU='TEST' then
    MenuObj.Test;
end;

////////////////////////////////////////////////////////////////////////////////
function FilterStr(Filter : String; Str : String) : Boolean;
var
  Cnt   : Integer;
  F1,F2 : String;
  S1,S2 : String;
begin
  Cnt:=Pos('*',Filter);
  F1:=Copy(Filter,1,Cnt-1);
  F2:=Copy(Filter,Cnt+1,999);
  S1:=Copy(Str,1,Length(F1));
  S2:=Copy(Str,1+Length(Str)-Length(F2),999);
  for Cnt:=1 to Length(S1) do
    if Copy(F1,Cnt,1)='?' then S1[Cnt]:='?';
  for Cnt:=1 to Length(S2) do
    if Copy(F2,Cnt,1)='?' then S2[Cnt]:='?';
  Result:=(S1=F1)and(S2=F2);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.NameSpaceProc;
var
  Cnt    : Integer;
  sSrc,
  sTarg  : String;
  lSrc,
  lTarg  : TVarList;
  List   : TStringList;
begin
  if ParList.Count<2 then Exit;

  if ParList[1].StrU='PUSH' then
    NSStack.AddObject(Vars.NSName,Pointer(Vars.NSType=global));

  if ParList[1].StrU='POP' then
    if NSStack.Count>0 then
  begin
    Vars.NSName:=NSStack[NSStack.Count-1];
    if Boolean(NSStack.Objects[NSStack.Count-1]) then
      Vars.NSType:=global
    else Vars.NSType:=local;
    NSStack.Delete(NSStack.Count-1);
  end;

  if ParList[1].StrU='CLEAR' then
  begin
    if Vars.NSType=global then lSrc:=Vars.NSGlobal
    else lSrc:=Vars.NSLocal;
    lSrc.DelVars('!'+Vars.NSName+'~',False);
  end;

  if ParList.Count<3 then Exit;

  if ParList[1].StrU='LOCAL' then
    if IsVar('%'+ParList[2].StrU) then
  begin
    Vars.NSName:=ParList[2].StrU;
    Vars.NSType:=local;
  end;

  if ParList[1].StrU='GLOBAL' then
    if IsVar('%'+ParList[2].StrU) then
  begin
    Vars.NSName:=ParList[2].StrU;
    Vars.NSType:=global;
  end;

  if ParList.Count<6 then Exit;

  if ParList[1].StrU='COPY' then
    if IsVar('%'+ParList[5].StrU) then
  begin

    with Vars do
    begin
      lSrc:=NSLocal;
      lTarg:=NSLocal;
      if NSType=global then
      begin
        lSrc:=NSGlobal;
        lTarg:=NSGlobal;
      end;
      sSrc:='!'+NSName+'~';
      sTarg:='!'+NSName+'~';
      if ParList[3].StrU='FROM' then
      begin
        sSrc:='!'+ParList[5].StrU+'~';
        if ParList[4].StrU='LOCAL' then lSrc:=NSLocal
        else if ParList[4].StrU='GLOBAL' then lSrc:=NSGlobal
        else Exit;
      end
      else if ParList[3].StrU='TO' then
      begin
        sTarg:='!'+ParList[5].StrU+'~';
        if ParList[4].StrU='LOCAL' then lTarg:=NSLocal
        else if ParList[4].StrU='GLOBAL' then lTarg:=NSGlobal
        else Exit;
      end
      else Exit;
      if (sSrc=sTarg)and(lSrc=lTarg) then Exit;
    end;

    List:=TStringList.Create;
    List.Text:=lSrc.ListVars(sSrc);
    for Cnt:=0 to List.Count-1 do
      if FilterStr(ParList[2].StrU,List[Cnt]) then
        lTarg.SetVar(sTarg+List[Cnt],lSrc.GetVar(sSrc+List[Cnt]));
    List.Free;

  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.StrProc;
var
  Cnt1 : Integer;
  Cnt2 : Integer;
  Cnt3 : Integer;
begin
  StrRes:='N/A';
  if ParList.Count<3 then Exit;

  if ParList[1].StrU='LEN' then
    StrRes:=IntToStr(Length(ParList[2].Str));
  if ParList[1].StrU='LOWER' then
    StrRes:=LowerCase(ParList[2].Str);
  if ParList[1].StrU='UPPER' then
    StrRes:=UpperCase(ParList[2].Str);

  if ParList.Count<4 then Exit;

  if ParList[1].StrU='POS' then
    StrRes:=IntToStr(Pos(ParList[3].StrU,ParList[2].StrU));
  if ParList[1].StrU='LEFT' then
    if ParList[3].CardValid then
      StrRes:=Copy(ParList[2].Str,1,ParList[3].Int);
  if ParList[1].StrU='RIGHT' then
    if ParList[3].CardValid then
      StrRes:=Copy(ParList[2].Str,Length(ParList[2].Str)-ParList[3].Int+1,$7FFFFFFF);
  Cnt1:=0;
  if ParList[1].StrU='COUNT' then
  repeat
    Cnt2:=Pos(ParList[3].StrU,ParList[2].StrU);
    Delete(ParList[2].StrU,1,Cnt2-1+Length(ParList[3].StrU));
    StrRes:=IntToStr(Cnt1);
    Inc(Cnt1);
  until Cnt2<1;

  if ParList.Count<5 then Exit;

  if ParList[1].StrU='MID' then
    if ParList[3].CardValid and ParList[4].CardValid then
      StrRes:=Copy(ParList[2].Str,ParList[3].Int,ParList[4].Int);
  if ParList[1].StrU='INS' then
    if ParList[4].CardValid then
  begin
    StrRes:=ParList[2].Str;
    Insert(ParList[3].Str,StrRes,ParList[4].Int);
  end;
  if ParList[1].StrU='DEL' then
    if ParList[3].CardValid and ParList[4].CardValid then
  begin
    StrRes:=ParList[2].Str;
    Delete(StrRes,ParList[3].Int,ParList[4].Int);
  end;
  Cnt1:=0;
  if ParList[1].StrU='POS' then
    if (ParList[4].CardValid)and(ParList[4].Int<1000) then
  for Cnt3:=1 to ParList[4].Int do
  begin
    Cnt2:=Pos(ParList[3].StrU,ParList[2].StrU)-1;
    if Cnt2<0 then Cnt1:=0;
    Delete(ParList[2].StrU,1,Cnt2+Length(ParList[3].StrU));
    StrRes:=IntToStr(Cnt1+Cnt2+1);
    Cnt1:=Cnt1+Cnt2+Length(ParList[3].StrU);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.DeleteVarProc;
begin
  if ParList.Count<2 then Exit;
  Vars.UserVars.DelVars('%'+ParList[1].StrU,True);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.OnHotkeyProc;
var
  Cnt   : Integer;
  c,a,s : Boolean;
begin
  if ParList.Count<2 then Exit;

  c:=False;
  a:=False;
  s:=False;
  for Cnt:=2 to ParList.Count-1 do
  begin
    if ParList[Cnt].StrU='CTRL'  then c:=True;
    if ParList[Cnt].StrU='ALT'   then a:=True;
    if ParList[Cnt].StrU='SHIFT' then s:=True;
  end;

  if StdCmd.OnHotkey(ParList[1].StrU,c,a,s) then Exit;

  Cnt:=ScanForBlock;
  if (Cnt<2)and(ParList.Count>2) then
    with ParList[ParList.Count-1]^ do
      if IntValid then Cnt:=Int;
  NextLine:=NextLine+Cnt;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.GoToProc;
var
  i1,i2  : Integer;
  b1,b2  : Boolean;
  sBuf   : String;
begin
  if ParList.Count<2 then Exit;
  sBuf:=ParList[1].StrU;
  if Copy(sBuf,Length(sBuf),1)<>':' then
    sBuf:=sBuf+':';

  i1:=NextLine-1;
  i2:=i1;
  repeat
    Inc(i1);
    Dec(i2);
    b1:=i1<ScrList.Scr.Count;
    b2:=i2>=0;

    if b1 then
      if GetCmd(i1)=sBuf then
    begin
      NextLine:=i1+1;
      Exit;
    end;

    if b2 then
      if GetCmd(i2)=sBuf then
    begin
      NextLine:=i2+1;
      Exit;
    end;
  until not(b1 or b2);

end;

////////////////////////////////////////////////////////////////////////////////
procedure CompleteInt(Pars : PTPars);
begin
  Pars.Str:=IntToStr(Pars.Int);
  Pars.StrU:=Pars.Str;
  Pars.IntValid:=True;
  Pars.CardValid:=Pars.Int>=0;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.Eval(FP : Integer);
var
  Cnt       : Integer;
  iFrom,iTo : Integer;
  bEnd      : Boolean;
  bRes      : Boolean;
begin
  repeat

    {find brackets}
    iTo:=-1;
    for Cnt:=FP to ParList.Count-1 do
      if ParList[Cnt].StrU=')' then
    begin
      iTo:=Cnt;
      Break;
    end;
    iFrom:=-1;
    for Cnt:=iTo-1 downto FP do
      if ParList[Cnt].StrU='(' then
    begin
      iFrom:=Cnt;
      Break;
    end;
    if (iFrom=-1) or (iTo=-1) then
    begin
      iFrom:=FP;
      iTo:=ParList.Count-1;
      bEnd:=True;
    end
    else begin
      ParList.Delete(iTo);
      ParList.Delete(iFrom);
      Dec(iTo,2);
      bEnd:=False;
    end;

    {priority 5}
    Cnt:=iTo;
    while Cnt>iFrom do
    begin
      Dec(Cnt);

      if ParList[Cnt].StrU='!' then
        ParList[Cnt+1].Int:=not ParList[Cnt+1].Int
      else if ParList[Cnt].StrU='ABS' then
        ParList[Cnt+1].Int:=Abs(ParList[Cnt+1].Int)
      else Continue;

      ParList.Delete(Cnt);
      Dec(iTo);
      CompleteInt(ParList[Cnt]);
    end;

    {priority 4}
    Cnt:=iFrom;
    while Cnt<iTo-1 do
    begin
      Inc(Cnt);

      if ParList[Cnt].StrU='*' then
        ParList[Cnt+1].Int:=ParList[Cnt-1].Int*ParList[Cnt+1].Int
      else if ParList[Cnt].StrU='/' then
        if ParList[Cnt+1].Int<>0 then
          ParList[Cnt+1].Int:=ParList[Cnt-1].Int div ParList[Cnt+1].Int
        else ParList[Cnt+1].Int:=0
      else if ParList[Cnt].StrU='%' then
        if ParList[Cnt+1].Int<>0 then
          ParList[Cnt+1].Int:=ParList[Cnt-1].Int mod ParList[Cnt+1].Int
        else ParList[Cnt+1].Int:=0
      else Continue;

      Dec(Cnt);
      ParList.Delete(Cnt);
      ParList.Delete(Cnt);
      Dec(iTo,2);
      CompleteInt(ParList[Cnt]);
    end;

    {priority 3}
    Cnt:=iFrom;
    while Cnt<iTo-1 do
    begin
      Inc(Cnt);

      if ParList[Cnt].StrU='+' then
        ParList[Cnt+1].Int:=ParList[Cnt-1].Int+ParList[Cnt+1].Int
      else if ParList[Cnt].StrU='-' then
        ParList[Cnt+1].Int:=ParList[Cnt-1].Int-ParList[Cnt+1].Int
      else Continue;

      Dec(Cnt);
      ParList.Delete(Cnt);
      ParList.Delete(Cnt);
      Dec(iTo,2);
      CompleteInt(ParList[Cnt]);
    end;

    {priority 2}
    Cnt:=iFrom;
    while Cnt<iTo-1 do
    begin
      Inc(Cnt);

      if ParList[Cnt].StrU='=' then
        if ParList[Cnt-1].IntValid and ParList[Cnt+1].IntValid then
          bRes:=ParList[Cnt-1].Int=ParList[Cnt+1].Int
        else bRes:=ParList[Cnt-1].StrU=ParList[Cnt+1].StrU
      else if ParList[Cnt].StrU='<>' then
        if ParList[Cnt-1].IntValid and ParList[Cnt+1].IntValid then
          bRes:=ParList[Cnt-1].Int<>ParList[Cnt+1].Int
        else bRes:=ParList[Cnt-1].StrU<>ParList[Cnt+1].StrU
      else if ParList[Cnt].StrU='<' then
        if ParList[Cnt-1].IntValid and ParList[Cnt+1].IntValid then
          bRes:=ParList[Cnt-1].Int<ParList[Cnt+1].Int
        else bRes:=False
      else if ParList[Cnt].StrU='>' then
        if ParList[Cnt-1].IntValid and ParList[Cnt+1].IntValid then
          bRes:=ParList[Cnt-1].Int>ParList[Cnt+1].Int
        else bRes:=False
      else if (ParList[Cnt].StrU='<=') or (ParList[Cnt].StrU='=<') then
        if ParList[Cnt-1].IntValid and ParList[Cnt+1].IntValid then
          bRes:=ParList[Cnt-1].Int<=ParList[Cnt+1].Int
        else bRes:=False
      else if (ParList[Cnt].StrU='>=') or (ParList[Cnt].StrU='=>') then
        if ParList[Cnt-1].IntValid and ParList[Cnt+1].IntValid then
          bRes:=ParList[Cnt-1].Int>=ParList[Cnt+1].Int
        else bRes:=False
      else if ParList[Cnt].StrU='IN' then
        bRes:=Pos(ParList[Cnt-1].StrU,ParList[Cnt+1].StrU)>0
      else if ParList[Cnt].StrU='NOTIN' then
        bRes:=Pos(ParList[Cnt-1].StrU,ParList[Cnt+1].StrU)<1
      else Continue;

      if bRes then ParList[Cnt+1].Int:=-1
      else ParList[Cnt+1].Int:=0;

      Dec(Cnt);
      ParList.Delete(Cnt);
      ParList.Delete(Cnt);
      Dec(iTo,2);
      CompleteInt(ParList[Cnt]);
    end;

    {priority 1}
    Cnt:=iFrom;
    while Cnt<iTo-1 do
    begin
      Inc(Cnt);

      if ParList[Cnt].StrU='&&' then
        ParList[Cnt+1].Int:=ParList[Cnt-1].Int and ParList[Cnt+1].Int
      else Continue;

      Dec(Cnt);
      ParList.Delete(Cnt);
      ParList.Delete(Cnt);
      Dec(iTo,2);
      CompleteInt(ParList[Cnt]);
    end;

    {priority 0}
    Cnt:=iFrom;
    while Cnt<iTo-1 do
    begin
      Inc(Cnt);

      if (ParList[Cnt].StrU='||') or (ParList[Cnt].StrU='¦¦') then
        ParList[Cnt+1].Int:=ParList[Cnt-1].Int or ParList[Cnt+1].Int
      else Continue;

      Dec(Cnt);
      ParList.Delete(Cnt);
      ParList.Delete(Cnt);
      Dec(iTo,2);
      CompleteInt(ParList[Cnt]);
    end;

  until bEnd;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.ElseProc;
var
  Cnt : Integer;
begin
  if not ElseFlag then Exit;

  Cnt:=ScanForBlock;
  if (Cnt<2)and(ParList.Count>1) then
    if ParList[1].IntValid then Cnt:=ParList[1].Int;
  NextLine:=NextLine+Cnt;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.IfProc;
var
  Cnt   : Integer;
  Cnt2  : Integer;
  sBuf  : String;
begin
  if ParList.Count<2 then Exit;
  Cnt2:=NextLine;

  Eval(1);
  Cnt:=ScanForBlock;
  if (Cnt<2)and(ParList.Count>2) then
    if ParList[2].IntValid then Cnt:=ParList[2].Int;

  ElseFlag:=True;
  if ParList[1].Int<>-1 then
  begin
    ElseFlag:=False;
    NextLine:=NextLine+Cnt;
  end;

  {Extended ELSE?}
  //if Cnt<2 then Exit;  beware of single line gosubs!!!
  Cnt:=Cnt2+Cnt-1;
  repeat
    Inc(Cnt);
    if Cnt>=ScrList.Scr.Count then Exit;
    sBuf:=GetCmd(Cnt);
    if sBuf='ELSE' then Break;
    if sBuf<>'' then Exit;
  until False;

  ScrList.Info.Find(IntToStr(Cnt)+' ',Cnt2);
  if Cnt2<ScrList.Info.Count then
    if Integer(ScrList.Info.Objects[Cnt2])=Cnt then
      ScrList.Info.Delete(Cnt2);

  sBuf:='FALSE';
  if ElseFlag then sBuf:='TRUE';
  ScrList.Info.InsertObject(Cnt2,IntToStr(Cnt)+' ELSE '+sBuf,Pointer(Cnt));
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.SetProc;
var
  sBuf : String;
begin
  if ParList.Count<2 then Exit;
  if not IsVar(ParList[1].StrU) then Exit;

  Eval(2);

  sBuf:='';
  if ParList.Count>2 then
    sBuf:=ParList[2].Str;

  if ParList.Count>3 then
    if ParList[2].IntValid then
  begin
    if ParList[3].StrU='-' then
      sBuf:=IntToStr(ParList[2].Int-1);
    if ParList[3].StrU='+' then
      sBuf:=IntToStr(ParList[2].Int+1);
    if ParList[3].StrU='ABS' then
      sBuf:=IntToStr(Abs(ParList[2].Int));
  end;

  SetVar(ParList[1].StrU,sBuf);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.CmpPixProc;
var
  TF   : Boolean;
begin
  if ParList.Count<2 then Exit;
  if not((ParList[1].Int>=0) and (ParList[1].Int<1001)) then Exit;

  TF:=True;
  if ParList.Count>2 then
    TF:=ParList[2].StrU<>'F';

  with PixData[ParList[1].Int] do
    if (StdCmd.GetPix(UOSel.HWnd,X,Y)=Col) xor TF then
  begin
    if ParList.Count>3 then
      if ParList[3].IntValid then
    begin
      NextLine:=NextLine+ParList[3].Int;
      Exit;
    end;
    NextLine:=NextLine+ScanForBlock;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.SavePixProc;
begin
  if ParList.Count<4 then Exit;
  if not((ParList[1].CardValid) and (ParList[2].CardValid)
    and (ParList[3].Int>=0) and (ParList[3].Int<1001)) then Exit;

  with PixData[ParList[3].Int] do
  begin
    X:=ParList[1].Int;
    Y:=ParList[2].Int;

    if ParList.Count>4 then
      if ParList[4].CardValid then
    begin
      Col:=ParList[4].Int;
      Exit;
    end;

    Col:=UOCmd.GetPix(ParList[1].Int,ParList[2].Int);
    PixCol:=Col;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
/// UO Procs ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

const
  Cmd2 : Array[0..22] of String = (
  'Key','Click','Move','Msg','SavePix','CmpPix','Target','ContPos','ChooseSkill',
  'NextCPos','ScanJournal','DeleteJournal','HideItem','SetUOTitle','FindItem',
  'IgnoreItem','GetShopInfo','SetShopItem','Tile','Event','ExEvent','GetUOTitle',
  'IgnoreCont');

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.InterpretUO;
var
  i : Integer;
begin
  for i:=0 to High(Cmd2) do
    if ParList[0].StrU=UpperCase(Cmd2[i]) then Break;

  case i of
    00 : KeyProc;
    01 : ClickProc;
    02 : MoveProc;
    03 : MsgProc;
    04 : SavePixProc;
    05 : CmpPixProc;
    06 : TargetProc;
    07 : ContPosProc;
    08 : ChooseSkillProc;
    09 : NextCPosProc;
    10 : ScanJournalProc;
    11 : DeleteJournalProc;
    12 : HideItemProc;
    13 : SetUOTitleProc;
    14 : FindItemProc;
    15 : IgnoreItemProc;
    16 : GetShopInfoProc;
    17 : SetShopItemProc;
    18 : TileProc;
    19 : EventProc;
    20 : ExEventProc;
    21 : GetUOTitleProc;
    22 : IgnoreContProc;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.IgnoreContProc;
var
  s : String;
  c : Cardinal;
  b : Boolean;
begin
  if ParList.Count<2 then Exit;
  s:=ParList[1].StrU;
  if s='RESET' then
  begin
    UOVar.IgnoreCont(0);
    Exit;
  end;

  c:=Sys26ToCard(s,b);
  if b and (c<$10000) then
  begin
    if c>0 then UOVar.IgnoreCont(c); // Only accept RESET, not YC!
  end
  else UOVar.IgnoreCont(s);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.ExEventProc;
var
  iBuf  : Integer;
  iBuf2 : Integer;
  i     : Integer;
  c     : Cardinal;
  b     : Boolean;
  s     : String;
begin
  if ParList[1].StrU='DROPPD' then
    EventObj.ExEv_DropPD;

  if ParList[1].StrU='DRAG' then
  begin
    iBuf:=ParList[3].Int;
    if iBuf<1 then iBuf:=1;
    EventObj.ExEv_Drag(Sys26ToCard(ParList[2].Str),iBuf);
  end;

  if ParList[1].StrU='DROPC' then
  begin
    iBuf:=ParList[3].Int;
    iBuf2:=ParList[4].Int;
    if iBuf<0 then iBuf:=-1;
    if iBuf2<0 then iBuf2:=-1;
    EventObj.ExEv_DropC(Sys26ToCard(ParList[2].Str),iBuf,iBuf2);
  end;

  if ParList[1].StrU='POPUP' then
  begin
    EventObj.ExEv_PopUp(Sys26ToCard(ParList[2].Str),0,0);
  end;

  if ParList[1].StrU='DROPG' then
    if ParList[2].CardValid and ParList[3].CardValid then
  begin
    iBuf:=-1000;
    if ParList[4].IntValid then
      iBuf:=ParList[4].Int;
    EventObj.ExEv_DropG(ParList[2].Int,ParList[3].Int,iBuf);
  end;

  if ParList[1].StrU='SKILLLOCK' then
  begin
    iBuf:=-1;
    if ParList[3].StrU='UP'     then iBuf:=0;
    if ParList[3].StrU='DOWN'   then iBuf:=1;
    if ParList[3].StrU='LOCKED' then iBuf:=2;
    if iBuf=-1 then Exit;
    EventObj.ExEv_SkillLock(ParList[2].Str,iBuf);
  end;

  if ParList[1].StrU='STATLOCK' then
  begin
    iBuf:=-1;
    if ParList[3].StrU='UP'     then iBuf:=0;
    if ParList[3].StrU='DOWN'   then iBuf:=1;
    if ParList[3].StrU='LOCKED' then iBuf:=2;
    if iBuf=-1 then Exit;
    EventObj.ExEv_StatLock(ParList[2].Str,iBuf);
  end;

  if ParList[1].StrU='RENAMEPET' then
  begin
    EventObj.ExEv_RenamePet(Sys26ToCard(ParList[2].Str),ParList[3].Str);
  end;

  if ParList[1].StrU='EQUIP' then
  begin
    s:='';
    for i:=2 to ParList.Count-1 do
    begin
      c:=Sys26ToCard(ParList[i].StrU,b);
      if b then s:=s+NumStr(c,4,False);
    end;
    if s<>'' then EventObj.ExEv_Custom(#236+
      NumStr(Length(s)  +  4,2,True)+
      NumStr(Length(s) div 4,1,True)+
    s);
  end;

end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.EventProc;
var
  Cnt : Integer;
begin
  if ParList.Count<3 then Exit;

  if ParList[1].StrU='PROPERTY' then
    EventObj.EvProperty(Sys26ToCard(ParList[2].Str));

  if ParList[1].StrU='DRAG' then
    EventObj.Drag(Sys26ToCard(ParList[2].Str));

  if ParList[1].StrU='SYSMESSAGE' then
    EventObj.SysMessage(GetParStr(2),SysMsgCol);

  if ParList[1].StrU='MACRO' then
    if ParList[2].CardValid then
  begin
    Cnt:=0;
    if ParList.Count>3 then
      if ParList[3].CardValid then
        Cnt:=ParList[3].Int;
    EventObj.Macro(ParList[2].Int,Cnt,GetParStr(4));
  end;

  if ParList[1].StrU='CONTTOP' then
    EventObj.ContTop(ParList[2].Int);

  if ParList[1].StrU='STATBAR' then
    EventObj.StatBar(Sys26ToCard(ParList[2].Str));

  if ParList.Count<4 then Exit;

  if ParList[1].StrU='SKILLLOCK' then
  begin
    Cnt:=-1;
    if ParList[3].StrU='UP'     then Cnt:=0;
    if ParList[3].StrU='DOWN'   then Cnt:=1;
    if ParList[3].StrU='LOCKED' then Cnt:=2;
    if Cnt=-1 then Exit;
    EventObj.ExEv_SkillLock(ParList[2].Str,Cnt);
  end;

  if ParList[1].StrU='PATHFIND' then
    if ParList[2].CardValid and ParList[3].CardValid then
  begin
    if ParList.Count>4 then Cnt:=ParList[4].Int
    else Cnt:=UOVar.CharPosZ;
    EventObj.Pathfind(ParList[2].Int,ParList[3].Int,Cnt);
  end;

  if ParList.Count<6 then Exit;

  if ParList[1].StrU='EXMSG' then
    if ParList[3].CardValid and ParList[4].CardValid then
      EventObj.ExMsg(Sys26ToCard(ParList[2].Str),ParList[3].Int,
        ParList[4].Int,ReplaceStr(GetParStr(5),'$',#13#10));
end;

////////////////////////////////////////////////////////////////////////////////
function TOldParser.GetTileFlags : String;
const TileDesc : Array[0..31] of String = (
  'Background','Weapon','Transparent','Translucent','Wall','Damaging',
  'Impassable','Wet','Unknown','Surface','Bridge','GenericStackable',
  'Window','NoShoot','PrefixA','PrefixAn','Internal','Foliage','PartialHue',
  'Unknown1','Map','Container','Wearable','LightSource','Animated',
  'NoDiagonal','Unknown2','Armor','Roof','Door','StairBack','StairRight');
var
  Cnt : Integer;
begin
  Result:='';
  for Cnt:=0 to 31 do
    if (UOCmd.TileFlags and (1 shl Cnt))>0 then
      Result:=Result+TileDesc[Cnt]+' ';
  Delete(Result,Length(Result),1);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.TileProc;
var
  Cnt : Integer;
begin
  if ParList.Count<2 then Exit;

  if ParList[1].StrU='INIT' then
    if ParList.Count<3 then UOCmd.TileInit
    else UOCmd.TileInit(ParList[2].StrU='NOOVERRIDES');

  if ParList.Count<4 then Exit;

  if ParList[1].StrU='CNT' then
    if ParList[2].CardValid and ParList[3].CardValid then
  begin
    Cnt:=-1;
    if ParList.Count>4 then
      if ParList[4].CardValid then
        Cnt:=ParList[4].Int;
    TileCount:=UOCmd.TileCnt(ParList[2].Int,ParList[3].Int,Cnt);
  end;

  if ParList.Count<5 then Exit;

  if ParList[1].StrU='GET' then if ParList[2].CardValid
    and ParList[3].CardValid and ParList[4].CardValid then
  begin
    Cnt:=-1;
    if ParList.Count>5 then
      if ParList[5].CardValid then
        Cnt:=ParList[5].Int;
    UOCmd.TileGet(ParList[2].Int,ParList[3].Int,ParList[4].Int,Cnt);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.SetShopItemProc;
begin
  if ParList.Count<3 then Exit;
  if not ParList[2].CardValid then Exit;
  UOCmd.SetShopItem(Sys26ToCard(ParList[1].StrU),ParList[2].Int);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.GetShopInfoProc;
begin
  UOCmd.GetShopInfo;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.IgnoreItemProc;
var
  sList : String;
  sBuf  : String;
  Cnt   : Integer;
begin
  if ParList.Count<2 then Exit;
  sList:='';
  if ParList.Count>2 then
    sList:=ParList[2].StrU;

  if ParList[1].StrU<>'RESET' then
  repeat
    sBuf:=ParList[1].StrU;
    Cnt:=Pos('_',sBuf);
    if Cnt>0 then sBuf:=Copy(sBuf,1,Cnt-1);
    Delete(ParList[1].StrU,1,Cnt);
    UOCmd.IgnoreItem(Sys26ToCard(sBuf), sList);
  until Cnt<1
  else UOCmd.IgnoreItemReset(sList);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.FindItemProc;
const
  CLEAR     = 0;
  ITEMID    = 1;
  ITEMTYPE  = 2;
  CONTAINER = 3;
  GROUND    = 4;
var
  i        : Integer;
  s1,s2    : String;
  c        : Cardinal;
  b        : Boolean;
begin
  if ParList.Count<2 then Exit;

  c:=0;
  s1:='';
  s2:='';
  FindInd:=1;
  if ParList.Count>2 then
  begin
    if ParList[2].CardValid then
      FindInd:=ParList[2].Int;

    s1:=ParList[ParList.Count-1].StrU;
    i:=Pos('_',s1);
    if i>0 then
      s2:=Copy(s1,i+1,9999);
    Delete(s1,i,9999);

    c:=SToCDef(s2,0,b);
    if not b then
      c:=Sys26ToCard(s2);
  end;

  UOCmd.ScanItems(Pos('A',s1)=0);

  if Pos('C',s1)>0 then
    if s2='' then UOCmd.FilterItems(CONTAINER)
    else UOCmd.FilterItems(CONTAINER,c);
  if Pos('G',s1)>0 then
    if s2='' then UOCmd.FilterItems(GROUND)
    else UOCmd.FilterItems(GROUND,c);

  s1:=ParList[1].StrU;
  if Pos('*',s1)<1 then
  repeat
    i:=Pos('_',s1);
    if i>0 then
    begin
      s2:=Copy(s1,1,i-1);
      Delete(s1,1,i);
    end
    else s2:=s1;
    c:=Sys26ToCard(s2);
    UOCmd.FilterItems(ITEMTYPE,c);
    UOCmd.FilterItems(ITEMID,c);
  until i<1;

  UOCmd.GetItem(FindInd-1);

  if UOCmd.ItemRes.ItemKind=-1 then
  begin
    UOCmd.ItemRes.ItemID:=85;
    UOCmd.ItemRes.ItemType:=85;
  end;
  if UOCmd.ItemRes.ContID=0 then
    UOCmd.ItemRes.ContID:=85;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.UOXLProc;
begin
  if ParList.Count<2 then Exit;
  if ParList[1].StrU='NEW' then
    UOCmd.OpenClient(True);
  if ParList[1].StrU='SWAP' then
    with UOSel do
      SelectClient(Nr mod Cnt+1);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.HideItemProc;
var
  ID      : Cardinal;
  ConvRes : Boolean;
begin
  if ParList.Count<2 then Exit;
  ID:=Sys26ToCard(ParList[1].StrU,ConvRes);
  if ConvRes then UOCmd.HideItem(ID);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.DeleteJournalProc;
begin
  DJournal:=DJournalSave;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.UpdateJournal;
begin
  if UOCmd.ScanJournal(UOCmd.JournalRef) then
    JIndex:=JIndex+UOCmd.JournalCnt
  else JIndex:=1000;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.ScanJournalProc;
var
  c,d : Cardinal;
begin
  UOCmd.JournalStr:='';
  UpdateJournal;

  // read parameter
  c:=1;
  if ParList.Count>1 then
    if ParList[1].Int>0 then
      c:=ParList[1].Int;

  // calculate line number
  if c>500 then c:=JIndex-c
  else Dec(c);
  if c>99 then Exit;

  // line deleted?
  d:=JIndex-c;
  if DJournal>=d then Exit;

  // return result
  DJournalSave:=d;
  UOCmd.GetJournal(c);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.NextCPosProc;
begin
  if ParList.Count<3 then Exit;
  if not ParList[1].IntValid then Exit;
  if not ParList[2].IntValid then Exit;
  UOVar.NextCPosX:=ParList[1].Int;
  UOVar.NextCPosY:=ParList[2].Int;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.ChooseSkillProc;
begin
  if ParList.Count<2 then Exit;

  SkillBool:=False;
  if ParList.Count>2 then
    SkillBool:=Copy(ParList[2].StrU,1,1)='R';
  SkillStr:=ParList[1].StrU;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.ContPosProc;
begin
  if ParList.Count<3 then Exit;
  if not ParList[1].IntValid then Exit;
  if not ParList[2].IntValid then Exit;
  UOVar.ContPosX:=ParList[1].Int;
  UOVar.ContPosY:=ParList[2].Int;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.TargetProc;
var
  TargTime : Cardinal;
  Cnt      : Integer;
  GTC      : Cardinal;
begin
  TargTime:=40;

  if ParList.Count>1 then
  begin
    if not ParList[1].CardValid then
    begin
      Cnt:=Pos('S_',ParList[1].StrU+'_');
      if Cnt>0 then
      begin
        Delete(ParList[1].Str,Cnt,1);
        TargTime:=SToCDef(ParList[1].Str,2)*20;
      end;
    end
    else TargTime:=ParList[1].Int;
  end;

  GTC:=GetTickCount;
  repeat
    if UOVar.TargCurs then Exit;
    if not Delay(50) then Exit;
  until GetTickCount>=GTC+TargTime*50;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.MsgProc;
begin
  UOCmd.Msg(ReplaceStr(GetParStr(1),'$',#13));
  StdCmd.Wait(1*50,0);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.MoveProc;
var
  Acc,
  TOut : Cardinal;
begin
  if ParList.Count<3 then Exit;
  if not ParList[1].CardValid then Exit;
  if not ParList[2].CardValid then Exit;

  Acc:=2;
  TOut:=0;
  if ParList.Count>3 then
  begin
    if ParList[3].CardValid then
      Acc:=ParList[3].Int
    else if ParList[3].StrU='A' then
      Acc:=0;
  end;
  if ParList.Count>4 then
    if ParList[4].CardValid then
      TOut:=ParList[4].Int
  else begin
    Delete(ParList[4].Str,Pos('S_',ParList[4].StrU+'_'),1);
    TOut:=SToCDef(ParList[4].Str,0)*20;
  end;

  UOCmd.Move(ParList[1].Int,ParList[2].Int,Acc,TOut*50);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.ClickProc;
var
  Cnt,X : Integer;
  Left,
  Down,
  Up,
  Fast,
  MC    : Boolean;
begin
  if ParList.Count<3 then Exit;
  if not ParList[1].CardValid then Exit;
  if not ParList[2].CardValid then Exit;

  X:=1;
  Left:=True;
  Down:=True;
  Up:=True;
  Fast:=False;

  MC:=MCDefault;

  for Cnt:=3 to ParList.Count-1 do
  begin
    if ParList[Cnt].StrU='D' then X:=X*2;
    if ParList[Cnt].StrU='X' then
      if Cnt+1<ParList.Count then
        if ParList[Cnt+1].CardValid then
          X:=X*ParList[Cnt+1].Int;
    if ParList[Cnt].StrU='R' then Left:=False;
    if ParList[Cnt].StrU='F' then Fast:=True;
    if ParList[Cnt].StrU='DMC' then MC:=False;
    if ParList[Cnt].StrU='MC' then MC:=True;
    if ParList[Cnt].StrU='G' then Up:=False;
    if ParList[Cnt].StrU='P' then Down:=False;
    if ParList[Cnt].StrU='N' then
    begin
      Up:=False;
      Down:=False;
    end;
  end;

  UOCmd.Click(ParList[1].Int,ParList[2].Int,X,Left,Down,Up,Fast,MC);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TOldParser.KeyProc;
var
  sBuf  : String;
  c,a,s : Boolean;
begin
  if Par.Count<2 then Exit;
  sBuf:=UpperCase(GetParStr(2));
  c:=Pos('CTRL',sBuf)>0;
  a:=Pos('ALT',sBuf)>0;
  s:=Pos('SHIFT',sBuf)>0;
  UOCmd.Key(Par[1],c,a,s);
  StdCmd.Wait(5*50,0);
end;

////////////////////////////////////////////////////////////////////////////////
initialization
  Randomize;
end.
