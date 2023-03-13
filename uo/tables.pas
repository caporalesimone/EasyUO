unit tables;
interface
uses stack, SysUtils;
type
  TIndex        = record
    N           : PChar;
    C           : Integer;
    T           : Pointer;
    H           : Integer;
  end;
  TDoc          = record
    P           : PChar;
    R           : PChar;
  end;
  TItem        = record
    N           : PChar;
    T           : Integer;
    C           : Integer;
    P           : PChar;
  end;
  TFindRes      = record
    I           : ^TItem;
    C           : Integer;
  end;
  TReq          = set of 0..31;

const
  RO = 01; RW = 02; ME = 03; EV = 04; CM = 05; QY = 06; PA = 31;

  function Find(Str : String; Ptr : Pointer; W,H : Integer) : Integer;
  function Find_First(var Res : TFindRes; Name : String; var Items : array of TItem) : Boolean; overload;
  function Find_First(var Res : TFindRes; Cls : TClass; Name : String; var Index : array of TIndex) : Boolean; overload;
  function Find_Next(var Res : TFindRes) : Boolean;
  function ParComp(Stack : TStack; i : Integer; Mask : PChar) : Boolean;
  function Check(var Res : TFindRes; Stack : TStack; Index : Integer; Req : TReq) : Integer;

implementation

////////////////////////////////////////////////////////////////////////////////
function PtrAdd(Ptr : Pointer; Amount : Cardinal) : Pointer;
begin
  Result:=Pointer(Cardinal(Ptr)+Amount);
end;

////////////////////////////////////////////////////////////////////////////////
function Find(Str : String; Ptr : Pointer; W,H : Integer) : Integer;            // Binary Search, operates on generic array, W = SizeOf(element), H = High(array)
type
  T = array[0..9999] of PChar;
var
  a,m,z : Integer;
begin
  a:=0;
  z:=H;
  while a<z do
  begin
    m:=a+(z-a)shr 1;
    if CompareStr(T(Ptr^)[m*W],Str)<0 then a:=m+1
    else z:=m;
  end;
  Result:=-1;
  repeat                                                                        // Find first occurence!
    if T(Ptr^)[a*W]<>Str then Exit;
    Result:=a;
    Dec(a);
  until a<0;
end;

////////////////////////////////////////////////////////////////////////////////
function Find_First(var Res : TFindRes; Name : String; var Items : array of TItem) : Boolean; // normal version
var
  i : Integer;
begin
  Res.I:=nil;
  Res.C:=0;
  Result:=False;
  i:=Find(Name,@Items,4,High(Items));   // item table width = 4
  if i<0 then Exit;
  Res.I:=@Items[i];
  Res.C:=High(Items)-i;
  Result:=True;
end;

////////////////////////////////////////////////////////////////////////////////
function Find_First(var Res : TFindRes; Cls : TClass; Name : String; var Index : array of TIndex) : Boolean; // object version (with index)
var
  i,j : Integer;
begin
  Res.I:=nil;
  Res.C:=0;
  Result:=False;
  repeat
    i:=Find(Cls.ClassName,@Index,4,High(Index));   // index table width = 4
    Cls:=Cls.ClassParent;
    if i<0 then Continue;
    if Index[i].T=nil then Continue;
    j:=Find(Name,Index[i].T,4,Index[i].H);         // item table width = 4
    if j<0 then Continue;
    Res.I:=PtrAdd(Index[i].T,j*SizeOf(TItem));
    Res.C:=Index[i].H-j;
    Result:=True;
  until (Cls=nil) or Result;
end;

////////////////////////////////////////////////////////////////////////////////
function Find_Next(var Res : TFindRes) : Boolean;
var
  I : ^TItem;
begin
  I:=PtrAdd(Res.I,SizeOf(TItem));
  if (Res.I<>nil)and(Res.C>0) then
    if CompareStr(Res.I^.N,I^.N)=0 then
  begin
    Res.I:=Pointer(I);
    Res.C:=Res.C-1;
    Result:=True;
    Exit;
  end;
  Res.I:=nil;
  Res.C:=0;
  Result:=False;
end;

////////////////////////////////////////////////////////////////////////////////
function ParComp(Stack : TStack; i : Integer; Mask : PChar) : Boolean; //checks parameters on the stack against a string mask
var
  cls : TClass;
  j   : Integer;
  s   : String;
  c   : Char;
begin
  Result:=False;
  j:=-1;
  Dec(i);
  repeat
    Inc(j);
    Inc(i);
    case Mask[j] of
      '?': Continue;
      '*': if Stack.GetTop()>=i-1 then Break
           else Exit;
      #0 : if Stack.GetTop()=i-1 then Break
           else Exit;
    end;
    case Stack.GetType(i) of
      T_NIL    : if Mask[j]<>'-' then
                 if Mask[j]<>'[' then Exit
                 else repeat
                   Inc(j);
                   if Mask[j]=#0 then Exit;
                 until Mask[j]=']';
      T_BOOLEAN: if Mask[j]<>'b' then Exit;
      T_NUMBER : if Mask[j]<>'n' then Exit;
      T_STRING : if Mask[j]<>'s' then Exit;
      T_POINTER: if Mask[j]<>'p' then
                 begin
                   c:=')';
                   if Mask[j]='[' then c:=']'
                   else if Mask[j]<>'(' then Exit;
                   cls:=TObject(Stack.GetPointer(i)).ClassType;
                   repeat
                     if cls=nil then Exit;
                     s:=cls.ClassName+c;
                     cls:=cls.ClassParent;
                   until StrLComp(@s[1],@Mask[j+1],Length(s))=0;
                   j:=j+Length(s);
                 end;
    end;
  until False;
  Result:=True;
end;

////////////////////////////////////////////////////////////////////////////////
function Check(var Res : TFindRes; Stack : TStack; Index : Integer; Req : TReq) : Integer; //uses all of the above functions to find a matching entry
begin
  Result:=-1;
  if Res.I<>nil then
  repeat
    if not(Res.I^.T in Req) then Continue;
    Result:=-2;
    if PA in Req then
      if not ParComp(Stack,Index,Res.I^.P) then Continue;
    Result:=Res.I^.C;
    Exit;
  until not Find_Next(Res);
end;

////////////////////////////////////////////////////////////////////////////////
end.
