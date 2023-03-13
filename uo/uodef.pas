unit uodef;
interface
uses uowrap;

  function  Version : Integer; stdcall;
  function  Open : Integer; stdcall;
  procedure Close(Hnd : Integer); stdcall;
  function  Query(Hnd : Integer) : Integer; stdcall;
  function  Execute(Hnd : Integer) : Integer; stdcall;
  function  GetTop(Hnd : Integer) : Integer; stdcall;
  function  GetType(Hnd,Index : Integer) : Integer; stdcall;
  procedure Insert(Hnd,Index : Integer); stdcall;
  procedure PushNil(Hnd : Integer); stdcall;
  procedure PushBoolean(Hnd : Integer; Value : LongBool); stdcall;
  procedure PushPointer(Hnd : Integer; Value : Pointer); stdcall;
  procedure PushPtrOrNil(Hnd : Integer; Value : Pointer); stdcall;
  procedure PushInteger(Hnd,Value : Integer); stdcall;
  procedure PushDouble(Hnd : Integer; Value : Double); stdcall;
  procedure PushStrRef(Hnd : Integer; Value : PChar); stdcall;
  procedure PushStrVal(Hnd : Integer; Value : PChar); stdcall;
  procedure PushLStrRef(Hnd : Integer; Value : PChar; Len : Integer); stdcall;
  procedure PushLStrVal(Hnd : Integer; Value : PChar; Len : Integer); stdcall;
  procedure PushValue(Hnd,Index : Integer); stdcall;
  function  GetBoolean(Hnd,Index : Integer) : LongBool; stdcall;
  function  GetPointer(Hnd,Index : Integer) : Pointer; stdcall;
  function  GetInteger(Hnd,Index : Integer) : Integer; stdcall;
  function  GetDouble(Hnd,Index : Integer) : Double; stdcall;
  function  GetString(Hnd,Index : Integer) : PChar; stdcall;
  function  GetLString(Hnd,Index : Integer; var Len : Integer) : PChar; stdcall;
  procedure Remove(Hnd,Index : Integer); stdcall;
  procedure SetTop(Hnd,Index : Integer); stdcall;
  procedure Mark(Hnd : Integer); stdcall;
  procedure Clean(Hnd : Integer); stdcall;

implementation

////////////////////////////////////////////////////////////////////////////////
function Version : Integer;
begin
  Result:=3;
end;

////////////////////////////////////////////////////////////////////////////////
function Open : Integer;
begin
  Result:=Integer(TUOWrap.Create);
end;

////////////////////////////////////////////////////////////////////////////////
procedure Close(Hnd : Integer);
begin
  TUOWrap(Hnd).Free;
end;

////////////////////////////////////////////////////////////////////////////////
function Query(Hnd : Integer) : Integer;
begin
  Result:=TUOWrap(Hnd).Query;
end;

////////////////////////////////////////////////////////////////////////////////
function Execute(Hnd : Integer) : Integer;
begin
  Result:=TUOWrap(Hnd).Execute;
end;

////////////////////////////////////////////////////////////////////////////////
function GetTop(Hnd : Integer) : Integer;
begin
  Result:=TUOWrap(Hnd).Stack.GetTop;
end;

////////////////////////////////////////////////////////////////////////////////
function GetType(Hnd,Index : Integer) : Integer;
begin
  Result:=TUOWrap(Hnd).Stack.GetType(Index);
end;

////////////////////////////////////////////////////////////////////////////////
procedure Insert(Hnd,Index : Integer);
begin
  TUOWrap(Hnd).Stack.Insert(Index);
end;

////////////////////////////////////////////////////////////////////////////////
procedure PushNil(Hnd : Integer);
begin
  TUOWrap(Hnd).Stack.PushNil;
end;

////////////////////////////////////////////////////////////////////////////////
procedure PushBoolean(Hnd : Integer; Value : LongBool);
begin
  TUOWrap(Hnd).Stack.PushBoolean(Value);
end;

////////////////////////////////////////////////////////////////////////////////
procedure PushPointer(Hnd : Integer; Value : Pointer);
begin
  TUOWrap(Hnd).Stack.PushPointer(Value);
end;

////////////////////////////////////////////////////////////////////////////////
procedure PushPtrOrNil(Hnd : Integer; Value : Pointer);
begin
  TUOWrap(Hnd).Stack.PushPtrOrNil(Value);
end;

////////////////////////////////////////////////////////////////////////////////
procedure PushInteger(Hnd,Value : Integer);
begin
  TUOWrap(Hnd).Stack.PushInteger(Value);
end;

////////////////////////////////////////////////////////////////////////////////
procedure PushDouble(Hnd : Integer; Value : Double);
begin
  TUOWrap(Hnd).Stack.PushDouble(Value);
end;

////////////////////////////////////////////////////////////////////////////////
procedure PushStrRef(Hnd : Integer; Value : PChar);
begin
  TUOWrap(Hnd).Stack.PushStrRef(Value);
end;

////////////////////////////////////////////////////////////////////////////////
procedure PushStrVal(Hnd : Integer; Value : PChar);
begin
  TUOWrap(Hnd).Stack.PushStrVal(Value);
end;

////////////////////////////////////////////////////////////////////////////////
procedure PushLStrRef(Hnd : Integer; Value : PChar; Len : Integer);
begin
  TUOWrap(Hnd).Stack.PushLStrRef(Value,Len);
end;

////////////////////////////////////////////////////////////////////////////////
procedure PushLStrVal(Hnd : Integer; Value : PChar; Len : Integer);
begin
  TUOWrap(Hnd).Stack.PushLStrVal(Value,Len);
end;

////////////////////////////////////////////////////////////////////////////////
procedure PushValue(Hnd,Index : Integer);
begin
  TUOWrap(Hnd).Stack.PushValue(Index);
end;

////////////////////////////////////////////////////////////////////////////////
function GetBoolean(Hnd,Index : Integer) : LongBool;
begin
  Result:=TUOWrap(Hnd).Stack.GetBoolean(Index);
end;

////////////////////////////////////////////////////////////////////////////////
function GetPointer(Hnd,Index : Integer) : Pointer;
begin
  Result:=TUOWrap(Hnd).Stack.GetPointer(Index);
end;

////////////////////////////////////////////////////////////////////////////////
function GetInteger(Hnd,Index : Integer) : Integer;
begin
  Result:=TUOWrap(Hnd).Stack.GetInteger(Index);
end;

////////////////////////////////////////////////////////////////////////////////
function GetDouble(Hnd,Index : Integer) : Double;
begin
  Result:=TUOWrap(Hnd).Stack.GetDouble(Index);
end;

////////////////////////////////////////////////////////////////////////////////
function GetString(Hnd,Index : Integer) : PChar;
begin
  Result:=TUOWrap(Hnd).Stack.GetString(Index);
end;

////////////////////////////////////////////////////////////////////////////////
function GetLString(Hnd,Index : Integer; var Len : Integer) : PChar;
begin
  Result:=TUOWrap(Hnd).Stack.GetLString(Index,Len);
end;

////////////////////////////////////////////////////////////////////////////////
procedure Remove(Hnd,Index : Integer);
begin
  TUOWrap(Hnd).Stack.Remove(Index);
end;

////////////////////////////////////////////////////////////////////////////////
procedure SetTop(Hnd,Index : Integer);
begin
  TUOWrap(Hnd).Stack.SetTop(Index);
end;

////////////////////////////////////////////////////////////////////////////////
procedure Mark(Hnd : Integer);
begin
  TUOWrap(Hnd).Stack.Mark;
end;

////////////////////////////////////////////////////////////////////////////////
procedure Clean(Hnd : Integer);
begin
  TUOWrap(Hnd).Stack.Clean;
end;

////////////////////////////////////////////////////////////////////////////////
initialization
  IsMultiThread:=True; //IMPORTANT: Activates multi-threading support for Delphi stack
  Set8087CW($27F);     //IMPORTANT: Disables floating point exceptions
end.