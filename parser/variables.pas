// ***Unit Summary***
//
// This unit consists of two objects: TVarList and TVars. TVarList provides
// storage for variable names/values and direct thread-safe access to them
// while TVars holds the different variable lists and controls namespaces and
// thread-safe registy access.
//
// TVarList:
//   Clear()                     - Clears all variables in this list
//   SetVar(Name,Value)          - Sets a variable
//   GetVar(Name) : String       - Returns a variable
//   ListVars(FindStr) : String  - Lists all variables that begin with FindStr,
//                                 FindStr itself is cut away from all list entries!
//   DelVars(FindStr,Exact)      - Deletes specified variable(s)
//
// TVars:
//   UserVars : TVarList    - user varlist
//   NSName : String        - name of the current namespace
//   NSType : TNSType       - type of the current namespace
//   NSLocal : TVarList     - local namespace list
//   NSGlobal : TVarList    - global namesapce list
//   SetVar(Name,Value)     - set variable (universal)
//   GetVar(Name) : String  - get variable (universal)
//

unit variables;
interface
uses SysUtils, Classes, Registry, SyncObjs;

type
  TVarList      = class(TObject)
  private
    CS          : TCriticalSection;
    Names       : TStringList;
    Values      : TStringList;
  public
    constructor Create;
    procedure   Free;
    procedure   Clear;
    procedure   SetVar(Name,Value : String);
    function    GetVar(Name : String) : String;
    function    ListVars(FindStr : String) : String;
    procedure   DelVars(FindStr : String; Exact : Boolean);
  end;

  TNSType       = (global,local);

  TVars         = class(TObject)
  private
    CS          : TCriticalSection;
    Reg         : TRegistry;
    sNSName     : String;
    function    GetNSName : String;
    procedure   SetNSName(Value : String);
  public
    UserVars    : TVarList;
    NSType      : TNSType;
    NSLocal     : TVarList;
    NSGlobal    : TVarList;
    constructor Create;
    procedure   Free;
    procedure   SetVar(Name,Value : String);
    function    GetVar(Name : String) : String;
    property    NSName : String read GetNSName write SetNSName;
  end;

implementation

var
  _NSGlobal     : TVarList;

////////////////////////////////////////////////////////////////////////////////
/// TVarList ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

constructor TVarList.Create;
begin
  inherited Create;
  Names:=TStringList.Create;
  Values:=TStringList.Create;
  CS:=TCriticalSection.Create;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TVarList.Free;
begin
  CS.Free;
  Names.Free;
  Values.Free;
  inherited Free;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TVarList.Clear;
begin
  CS.Enter;
  Names.Clear;
  Values.Clear;
  CS.Leave;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TVarList.SetVar(Name,Value : String);
var
  i : Integer;
begin
  CS.Enter;
  Name:=UpperCase(Name);
  if not Names.Find(Name,i) then
  begin
    Names.Insert(i,Name);
    Values.Insert(i,Value);
  end
  else Values[i]:=Value;
  CS.Leave;
end;

////////////////////////////////////////////////////////////////////////////////
function TVarList.GetVar(Name : String) : String;
var
  i : Integer;
begin
  CS.Enter;
  Result:='N/A';
  if Names.Find(UpperCase(Name),i) then
    Result:=Values[i];
  CS.Leave;
end;

////////////////////////////////////////////////////////////////////////////////
function TVarList.ListVars(FindStr : String) : String;
var
  i,len : Integer;
begin
  CS.Enter;
  FindStr:=UpperCase(FindStr);
  len:=Length(FindStr);
  Result:='';
  Names.Find(FindStr,i);
  while i<Names.Count do
  begin
    if Copy(Names[i],1,len)<>FindStr then Break;
    Result:=Result+Copy(Names[i],len+1,999)+#13#10;
    Inc(i);
  end;
  Delete(Result,Length(Result)-1,2);
  CS.Leave;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TVarList.DelVars(FindStr : String; Exact : Boolean);
var
  i : Integer;
begin
  CS.Enter;
  FindStr:=UpperCase(FindStr);
  Names.Find(FindStr,i);
  while i<Names.Count do
  begin
    if Copy(Names[i],1,Length(FindStr))<>FindStr then Break;
    Names.Delete(i);
    Values.Delete(i);
    if Exact then Break;
  end;
  CS.Leave;
end;

////////////////////////////////////////////////////////////////////////////////
/// TVars //////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

constructor TVars.Create;
begin
  inherited Create;
  UserVars:=TVarList.Create;
  NSLocal:=TVarList.Create;
  NSGlobal:=_NSGlobal; //object reference is constant
  sNSName:='std';
  NSType:=local;
  Reg:=TRegistry.Create;
  Reg.OpenKey('\Software\EasyUO',True);
  CS:=TCriticalSection.Create;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TVars.Free;
begin
  CS.Free;
  Reg.CloseKey;
  Reg.Free;
  UserVars.Free;
  NSLocal.Free;
  inherited Free;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TVars.SetVar(Name,Value : String);
begin
  if Name<>'' then
  case Name[1] of
    '%' : UserVars.SetVar(Name,Value);
    '!' : begin
            CS.Enter;
            Name:='!'+sNSName+'~'+PChar(@Name[2]);
            CS.Leave;
            if NSType=local then NSLocal.SetVar(Name,Value)
            else NSGlobal.SetVar(Name,Value);
          end;
    '*' : begin
            CS.Enter;
            try Reg.WriteString(Name,Value); except end;
            CS.Leave;
          end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
function TVars.GetVar(Name : String) : String;
begin
  Result:='N/A';
  if Name<>'' then
  case Name[1] of
    '%' : Result:=UserVars.GetVar(Name);
    '!' : begin
            CS.Enter;
            Name:='!'+sNSName+'~'+PChar(@Name[2]);
            CS.Leave;
            if NSType=local then Result:=NSLocal.GetVar(Name)
            else Result:=NSGlobal.GetVar(Name);
          end;
    '*' : begin
            CS.Enter;
            if Reg.GetDataType(Name)=rdString then
              try Result:=Reg.ReadString(Name); except end;
            CS.Leave;
          end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
function TVars.GetNSName : String;
begin
  CS.Enter;
  Result:=sNSName;
  CS.Leave;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TVars.SetNSName(Value : String);
begin
  CS.Enter;
  sNSName:=Value;
  CS.Leave;
end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

initialization
  _NSGlobal:=TVarList.Create;
finalization
  _NSGlobal.Free;
end.
