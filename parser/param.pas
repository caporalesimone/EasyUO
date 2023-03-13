unit param;
interface
uses Classes;

type
  TPars          = record
    Str          : String;
    StrU         : String;
    Int          : Int64;
    IntValid     : Boolean;
    CardValid    : Boolean;
  end;
  PTPars         = ^TPars;

  TParList       = class(TObject)
  private
    List         : TList;
    EmptyRec     : TPars;
    function     Get(Index: Integer): PTPars;
  public
    constructor  Create;
    procedure    Free;
    procedure    AddNew;
    procedure    InsertNew(Index : Cardinal);
    procedure    Delete(Index : Cardinal);
    procedure    Clear;
    function     Count : Cardinal;
    function     Last  : PTPars;
    property     Items[Index: Integer]: PTPars read Get; default;
  end;

implementation

////////////////////////////////////////////////////////////////////////////////
constructor TParList.Create;
begin
  inherited Create;
  List:=TList.Create;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TParList.Free;
begin
  Clear;
  List.Free;
  inherited Free;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TParList.AddNew;
begin
  InsertNew(List.Count);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TParList.InsertNew(Index : Cardinal);
var
  PItem : PTPars;
begin
  New(PItem);
  List.Insert(Index,PItem);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TParList.Delete(Index : Cardinal);
begin
  Dispose(PTPars(List[Index]));
  List.Delete(Index);
end;

////////////////////////////////////////////////////////////////////////////////
function TParList.Get(Index: Integer): PTPars;
begin
  if Index<List.Count then
  begin
    Result:=List[Index];
    Exit;
  end;

  EmptyRec.Str:='';
  EmptyRec.StrU:='';
  EmptyRec.Int:=-1;
  EmptyRec.IntValid:=False;
  EmptyRec.CardValid:=False;
  Result:=@EmptyRec;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TParList.Clear;
var
  Cnt : Integer;
begin
  for Cnt:=0 to List.Count-1 do
    Dispose(PTPars(List[Cnt]));
  List.Clear;
end;

////////////////////////////////////////////////////////////////////////////////
function TParList.Count : Cardinal;
begin
  Result:=List.Count;
end;

////////////////////////////////////////////////////////////////////////////////
function TParList.Last : PTPars;
begin
  Result:=List[List.Count-1];
end;

////////////////////////////////////////////////////////////////////////////////
end.

