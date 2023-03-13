unit scripts;
interface
uses Classes;

type
  TScriptList   = class(TObject)
  private
    ScrList     : TList;
    InfoList    : TList;
    SubList     : TList;
    CallList    : TStringList;
    SubLvl      : Cardinal;
    function    GetScrs(Ind : Integer) : TStringList;
    function    GetScrNames(Ind : Integer) : String;
  public
    constructor Create;
    procedure   Free;
    procedure   Clear;
    function    CallLevel : Cardinal;
    procedure   AddCall(OldLine : Cardinal; FN : String);
    function    DelCall : Cardinal;
    procedure   AddSub(OldLine : Cardinal; SN : String);
    function    DelSub : Cardinal;
    function    Info : TStringList;
    function    Scr : TStringList;
    function    ScrName : String;
    property    Scrs[i : Integer] : TStringList read GetScrs;
    property    ScrNames[i : Integer] : String read GetScrNames;
    property    SubLevel : Cardinal read SubLvl;
  end;

implementation

////////////////////////////////////////////////////////////////////////////////
constructor TScriptList.Create;
begin
  inherited Create;                                        // Create lists
  ScrList:=TList.Create;
  InfoList:=TList.Create;
  SubList:=TList.Create;
  CallList:=TStringList.Create;
  AddCall(0,'main');                                       // Add lowest level
end;

////////////////////////////////////////////////////////////////////////////////
procedure TScriptList.Free;
var
  Cnt  : Integer;
begin
  for Cnt:=0 to CallLevel do                               // Free all lists
  begin
    TObject(ScrList[Cnt]).Free;                            
    TObject(InfoList[Cnt]).Free;                           
    TObject(SubList[Cnt]).Free;                            
  end;                                                     
  ScrList.Free;                                            
  InfoList.Free;                                           
  SubList.Free;                                            
  CallList.Free;                                           
  inherited Free;                                          
end;

////////////////////////////////////////////////////////////////////////////////
procedure TScriptList.Clear;
begin
  while CallLevel>0 do DelCall;                            // Delete all upper levels
  //TStringList(ScrList[0]).Clear;                         // Clear lowest level
  TStringList(InfoList[0]).Clear;                         
  TStringList(SubList[0]).Clear;                          
end;                                                      

////////////////////////////////////////////////////////////////////////////////
function TScriptList.CallLevel : Cardinal;
begin
  Result:=ScrList.Count-1;                                 // GetLevel
end;

////////////////////////////////////////////////////////////////////////////////
procedure TScriptList.AddCall(OldLine : Cardinal; FN : String);
begin
  ScrList.Add(TStringList.Create);                         // Add a new level
  InfoList.Add(TStringList.Create);                       
  SubList.Add(TStringList.Create);                        
  CallList.AddObject(FN,Pointer(OldLine));                
  SubLvl:=0;                                              
end;

////////////////////////////////////////////////////////////////////////////////
function TScriptList.DelCall : Cardinal;
begin
  Result:=0;
  if CallLevel<1 then Exit;                                // Check
  TObject(ScrList[CallLevel]).Free;                        // Delete last CallLevel
  TObject(InfoList[CallLevel]).Free;                      
  TObject(SubList[CallLevel]).Free;                       
  InfoList.Delete(CallLevel);                             
  SubList.Delete(CallLevel);                              
  Result:=Cardinal(CallList.Objects[CallLevel]);          
  CallList.Delete(CallLevel);                             
  ScrList.Delete(CallLevel);                              
  SubLvl:=TStringList(SubList[CallLevel]).Count;          
end;

////////////////////////////////////////////////////////////////////////////////
procedure TScriptList.AddSub(OldLine : Cardinal; SN : String);
begin
  with TStringList(SubList[CallLevel]) do
  begin
    AddObject(SN,Pointer(OldLine));
    if SubLevel>1000 then Delete(0)
    else Inc(SubLvl);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
function TScriptList.DelSub : Cardinal;
begin
  Result:=0;
  with TStringList(SubList[CallLevel]) do
    if Count>0 then
  begin
    Result:=Cardinal(Objects[Count-1]);
    Delete(Count-1);
    SubLvl:=Count;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
function TScriptList.Info : TStringList;
begin
  Result:=TStringList(InfoList[CallLevel]);
end;

////////////////////////////////////////////////////////////////////////////////
function TScriptList.Scr : TStringList;
begin
  Result:=TStringList(ScrList[CallLevel]);
end;

////////////////////////////////////////////////////////////////////////////////
function TScriptList.ScrName : String;
begin
  Result:=CallList[CallLevel];
end;

////////////////////////////////////////////////////////////////////////////////
function TScriptList.GetScrs(Ind : Integer) : TStringList;
begin
  Result:=TStringList(ScrList[Ind]);
end;

////////////////////////////////////////////////////////////////////////////////
function TScriptList.GetScrNames(Ind : Integer) : String;
begin
  Result:=CallList[Ind];
end;

////////////////////////////////////////////////////////////////////////////////
end.
