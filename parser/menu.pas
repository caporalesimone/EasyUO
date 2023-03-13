unit menu;
interface
uses Windows, SysUtils, Controls, Forms, Classes, Graphics, StdCtrls, ExtCtrls,
     axCtrls, colorbtn;

type
  TMenuForm     = class(TForm)
  private
    MenuObj     : TObject;
    procedure   MyFormClose(Sender: TObject; var Action: TCloseAction);
  protected
    procedure   CreateParams(var Params: TCreateParams); override;
  public
    procedure   SetTransparency(Value : Byte);
    procedure   ShowEUO;
    procedure   HideEUO;
  end;

  TMenuObj      = class(TObject)
  private
    Ctrls       : TStringList;
    procedure   MyButtonClick(Sender : TObject);
    procedure   MyComboSelect(Sender : TObject);
  public
    Form        : TMenuForm;
    FontName    : String;
    FontAlign   : TAlignment;
    FontSize    : Integer;
    FontColor   : Integer;
    FontBG      : Integer;
    FontStyle   : TFontStyles;
    FontTrans   : Boolean;
    MenuButton  : String;
    MenuRes     : String;
    constructor Create;
    procedure   Free;
    procedure   Clear;
    procedure   Del(sName : String);
    procedure   Get(sName : String);
    procedure   _Set(sName,Str : String);
    procedure   Activate(sName : String);
    procedure   TextCreate(sName : String; X,Y : Integer; Str : String);
    procedure   ButtonCreate(sName : String; X,Y,W,H : Integer; Str : String);
    procedure   EditCreate(sName : String; X,Y,W : Integer; Str : String);
    procedure   CheckCreate(sName : String; X,Y,W,H : Integer; C : Boolean; Str : String);
    procedure   ComboCreate(sName : String; X,Y,W : Integer);
    procedure   ListCreate(sName : String; X,Y,W,H : Integer);
    procedure   ComboListAdd(sName,Str : String);
    procedure   ComboListSelect(sName : String; Ind : Integer);
    procedure   ComboListClear(sName : String);
    procedure   ShapeCreate(sName : String; X,Y,W,H,ST,LT,LW,LC,FT,FC : Integer);
    procedure   ImageCreate(sName : String; X,Y,W,H : Integer);
    procedure   ImagePos(sName : String; X,Y : Integer; W:Integer=-1;H:Integer=-1);
    procedure   ImageLine(sName : String; X1,Y1,X2,Y2,C : Integer; W:Integer=1);
    procedure   ImageEllipse(sName:String;X1,Y1,X2,Y2,C : Integer; Fill:Boolean; W:Integer=1);
    procedure   ImageRectangle(sName:String;X1,Y1,X2,Y2,C : Integer; Fill:Boolean; W:Integer=1);
    procedure   ImagePix(sName : String; X,Y,C : Integer);
    procedure   ImagePixLine(sName : String; X,Y : Integer; Data : String);
    procedure   ImageFloodFill(sName : String; X,Y,C : Integer);
    procedure   ImageFile(sName : String; X,Y : Integer; FN : String);
    procedure   Test;
  end;

implementation
uses conversion;
{$R menu.dfm}

////////////////////////////////////////////////////////////////////////////////
procedure TMenuForm.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.ExStyle:=Params.ExStyle or WS_EX_TOPMOST;
  Params.WndParent:=GetDesktopWindow;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuForm.SetTransparency(Value : Byte);
var
  Info : TOSVersionInfo;
  SLWA : TSetLayeredWindowAttributes;
begin
  Info.dwOSVersionInfoSize:=SizeOf(Info);
  GetVersionEx(Info);
  if (Info.dwPlatformId<>VER_PLATFORM_WIN32_NT)or(Info.dwMajorVersion<5) then Exit;
  SLWA:=GetProcAddress(GetModulehandle(user32),'SetLayeredWindowAttributes');
  if not Assigned(SLWA) then Exit;
  SetWindowLong(Handle,GWL_EXSTYLE,GetWindowLong(Handle,GWL_EXSTYLE)or WS_EX_LAYERED);
  SLWA(Handle,0,Value,LWA_ALPHA);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuForm.ShowEUO;
begin
  Application.Restore;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuForm.HideEUO;
begin
  Application.Minimize;
  Show;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuForm.MyFormClose(Sender: TObject; var Action: TCloseAction);
begin
  Application.Restore;
  TMenuObj(MenuObj).MenuButton:='CLOSED';
end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

constructor TMenuObj.Create;
begin
  inherited Create;
  Ctrls:=TStringList.Create;
  Form:=TMenuForm.Create(nil);
  Form.MenuObj:=self;
  Form.OnClose:=Form.MyFormClose;
  Clear;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuObj.Free;
begin
  Clear;
  Ctrls.Free;
  Form.Free;
  inherited Free;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuObj.Clear;
var
  Cnt : Integer;
begin
  for Cnt:=0 to Ctrls.Count-1 do
    Ctrls.Objects[Cnt].Free;
  Ctrls.Clear;
  FontName:='Arial';
  FontAlign:=taLeftJustify;
  FontSize:=10;
  FontColor:=clBlack;
  FontBG:=clBtnFace;
  FontStyle:=[];
  FontTrans:=False;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuObj.Del(sName : String);
var
  Cnt : Integer;
begin
  sName:=UpperCase(sName);
  for Cnt:=Ctrls.Count-1 downto 0 do
    if Ctrls[Cnt]=sName then
  begin
    Ctrls.Objects[Cnt].Free;
    Ctrls.Delete(Cnt);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuObj.Get(sName : String);
var
  Cnt  : Integer;
begin
  MenuRes:='N/A';
  Cnt:=Ctrls.IndexOf(UpperCase(sName));
  if Cnt<0 then Exit;

  // TLabel may contain CRLFs
  with Ctrls,Ctrls.Objects[Cnt] do
  if ClassName='TEdit' then
    MenuRes:=TEdit(Objects[Cnt]).Text
  else if ClassName='TComboBox' then
    MenuRes:=IntToStr(TComboBox(Objects[Cnt]).Tag+1)
  else if ClassName='TListBox' then
    MenuRes:=IntToStr(TListBox(Objects[Cnt]).ItemIndex+1)
  else if ClassName='TCheckBox' then
    if TCheckBox(Objects[Cnt]).Checked then MenuRes:='-1'
    else MenuRes:='0';
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuObj._Set(sName,Str : String);
var
  Cnt : Integer;
begin
  sName:=UpperCase(sName);
  for Cnt:=0 to Ctrls.Count-1 do
    if Ctrls[Cnt]=sName then
      with Ctrls,Ctrls.Objects[Cnt] do
  begin
    if ClassName='TEdit' then
      TEdit(Objects[Cnt]).Text:=Str
    else if ClassName='TLabel' then  // "$" doesn't work here
      TLabel(Objects[Cnt]).Caption:=Str
    else if ClassName='TBitBtnWithColor' then
      TBitBtnWithColor(Objects[Cnt]).Caption:=Str
    else if ClassName='TCheckBox' then
      TCheckBox(Objects[Cnt]).Checked:=SToI64Def(Str,0)<>0;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuObj.Activate(sName : String);
var
  Cnt : Integer;
begin
  Cnt:=Ctrls.IndexOf(UpperCase(sName));
  if Cnt<0 then Exit;

  with Ctrls.Objects[Cnt] do
    if (ClassName='TEdit')or(ClassName='TBitBtnWithColor')or
      (ClassName='TComboBox')or(ClassName='TListBox')or
      (ClassName='TCheckBox') then
        Form.ActiveControl:=TWinControl(Ctrls.Objects[Cnt]);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuObj.TextCreate(sName : String; X,Y : Integer; Str : String);
var
  NewLabel : TLabel;
begin
  with NewLabel do
  begin
    NewLabel:=TLabel.Create(nil);
    Left:=X;
    Top:=Y;

    Font.Name:=FontName;
    Font.Size:=FontSize;
    Font.Color:=FontColor;
    Color:=FontBG;
    Transparent:=FontTrans;
    Font.Style:=FontStyle;
    Width:=0;
    Alignment:=FontAlign;

    Caption:=ReplaceStr(Str,'$',#13#10);
    Parent:=Form;

    Ctrls.AddObject(UpperCase(sName),NewLabel);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuObj.ButtonCreate(sName : String; X,Y,W,H : Integer; Str : String);
var
  NewButton : TBitBtnWithColor;
begin
  with NewButton do
  begin
    NewButton:=TBitBtnWithColor.Create(nil);
    Left:=X;
    Top:=Y;
    Width:=W;
    Height:=H;

    Font.Name:=FontName;
    Font.Size:=FontSize;
    Font.Style:=FontStyle;
    Font.Color:=FontColor;
    Color:=FontBG;
    Caption:=Str;
    Parent:=Form;
    OnClick:=MyButtonClick;

    Ctrls.AddObject(UpperCase(sName),NewButton);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuObj.EditCreate(sName : String; X,Y,W : Integer; Str : String);
var
  NewEdit : TEdit;
begin
  with NewEdit do
  begin
    NewEdit:=TEdit.Create(nil);
    Left:=X;
    Top:=Y;
    Width:=W;

    Font.Name:=FontName;
    Font.Size:=FontSize;
    Font.Color:=FontColor;
    Color:=FontBG;
    Font.Style:=FontStyle;
    Text:=Str;
    Parent:=Form;

    Ctrls.AddObject(UpperCase(sName),NewEdit);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuObj.CheckCreate(sName : String; X,Y,W,H : Integer; C : Boolean; Str : String);
var
  NewCheck : TCheckBox;
begin
  with NewCheck do
  begin
    NewCheck:=TCheckBox.Create(nil);
    Left:=X;
    Top:=Y;
    Width:=W;
    Height:=H;
    Checked:=C;

    if FontAlign=taRightJustify then Alignment:=taLeftJustify
    else Alignment:=taRightJustify;
    Font.Name:=FontName;
    Font.Size:=FontSize;
    Font.Color:=FontColor;
    Color:=FontBG;
    Font.Style:=FontStyle;
    WordWrap:=True;
    Caption:=Str;
    Parent:=Form;

    Ctrls.AddObject(UpperCase(sName),NewCheck);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuObj.ComboCreate(sName : String; X,Y,W : Integer);
var
  NewCombo : TComboBox;
begin
  with NewCombo do
  begin
    NewCombo:=TComboBox.Create(nil);
    Left:=X;
    Top:=Y;
    Width:=W;

    Font.Name:=FontName;
    Font.Size:=FontSize;
    Font.Color:=FontColor;
    Color:=FontBG;
    Font.Style:=FontStyle;
    Style:=csDropDownList;
    Tag:=-1;
    OnSelect:=MyComboSelect;
    Parent:=Form;

    Ctrls.AddObject(UpperCase(sName),NewCombo);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuObj.ListCreate(sName : String; X,Y,W,H : Integer);
var
  NewList : TListBox;
begin
  with NewList do
  begin
    NewList:=TListBox.Create(nil);
    Left:=X;
    Top:=Y;
    Width:=W;
    Height:=H;

    Font.Name:=FontName;
    Font.Size:=FontSize;
    Font.Color:=FontColor;
    Color:=FontBG;
    Font.Style:=FontStyle;
    Parent:=Form;

    Ctrls.AddObject(UpperCase(sName),NewList);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuObj.ComboListAdd(sName,Str : String);
var
  Cnt : Integer;
begin
  sName:=UpperCase(sName);
  for Cnt:=0 to Ctrls.Count-1 do
    if Ctrls[Cnt]=sName then
    with Ctrls,Ctrls.Objects[Cnt] do
    if (ClassName='TListBox') then
      TListBox(Objects[Cnt]).Items.Add(Str)
    else if (ClassName='TComboBox') then
      TComboBox(Objects[Cnt]).Items.Add(Str);
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuObj.ComboListSelect(sName : String; Ind : Integer);
var
  Cnt : Integer;
begin
  sName:=UpperCase(sName);
  for Cnt:=0 to Ctrls.Count-1 do
    if Ctrls[Cnt]=sName then
    with Ctrls,Ctrls.Objects[Cnt] do
    if (ClassName='TListBox') then
      TListBox(Objects[Cnt]).ItemIndex:=Ind-1
    else if (ClassName='TComboBox') then
    begin
      TComboBox(Objects[Cnt]).ItemIndex:=Ind-1;
      TComboBox(Objects[Cnt]).Tag:=Ind-1;
    end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuObj.ComboListClear(sName : String);
var
  Cnt : Integer;
begin
  sName:=UpperCase(sName);
  for Cnt:=0 to Ctrls.Count-1 do
    if Ctrls[Cnt]=sName then
    with Ctrls,Ctrls.Objects[Cnt] do
    if (ClassName='TListBox') then
      TListBox(Objects[Cnt]).Items.Clear
    else if (ClassName='TComboBox') then
    begin
      TComboBox(Objects[Cnt]).Items.Clear;
      TComboBox(Objects[Cnt]).Tag:=-1;
    end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuObj.ShapeCreate(sName : String; X,Y,W,H,ST,LT,LW,LC,FT,FC : Integer);
var
  NewShape  : TShape;
begin
  with NewShape do
  begin
    NewShape:=TShape.Create(nil);
    Left:=X;
    Top:=Y;
    Width:=W;
    Height:=H;

    case ST of
      1: Shape:=stCircle;
      2: Shape:=stEllipse;
      4: Shape:=stRoundRect;
      5: Shape:=stRoundSquare;
      6: Shape:=stSquare;
    else Shape:=stRectangle;
    end;

    //try Pen.Color:=StringToColor('CL'+Param[10]);
    Pen.Color:=LC;

    case LT of
      1: Pen.Style:=psClear;
      2: Pen.Style:=psDash;
      3: Pen.Style:=psDashDot;
      4: Pen.Style:=psDashDotDot;
      5: Pen.Style:=psDot;
      6: Pen.Style:=psInsideFrame;
    else Pen.Style:=psSolid;
    end;

    Pen.Width:=LW;

    //try Brush.Color:=StringToColor('CL'+Param[12]);
    Brush.Color:=FC;

    case FT of
      1: Brush.Style:=bsBDiagonal;
      2: Brush.Style:=bsClear;
      3: Brush.Style:=bsCross;
      4: Brush.Style:=bsDiagCross;
      5: Brush.Style:=bsFDiagonal;
      6: Brush.Style:=bsHorizontal;
      8: Brush.Style:=bsVertical;
    else Brush.Style:=bsSolid;
    end;

    Parent:=Form;

    Ctrls.AddObject(UpperCase(sName),NewShape);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuObj.ImageCreate(sName : String; X,Y,W,H : Integer);
var
  NewImage : TImage;
begin
  with NewImage do
  begin
    NewImage:=TImage.Create(nil);
    Left:=X;
    Top:=Y;
    Width:=W;
    Height:=H;

    Transparent:=True;
    Picture.Bitmap.TransparentColor:=$FEEEED;
    Picture.Bitmap.PixelFormat:=pf32bit;
    Picture.Bitmap.Height:=H;
    Picture.Bitmap.Width:=W;
    Canvas.Brush.Color:=$FEEEED;
    Canvas.Rectangle(-10,-10,W+10,H+10);

    Parent:=Form;
    Ctrls.AddObject(UpperCase(sName),NewImage);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuObj.ImagePos(sName : String; X,Y : Integer; W:Integer=-1;H:Integer=-1);
var
  Cnt : Integer;
begin
  sName:=UpperCase(sName);
  for Cnt:=0 to Ctrls.Count-1 do
    if Ctrls[Cnt]=sName then
    if (Ctrls.Objects[Cnt].ClassName='TImage') then
    with TImage(Ctrls.Objects[Cnt]) do
  begin
    Left:=X;
    Top:=Y;
    if W>=0 then Width:=W;
    if W>=0 then Height:=H;
    Stretch:=True;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuObj.ImageLine(sName : String; X1,Y1,X2,Y2,C : Integer; W:Integer=1);
var
  Cnt : Integer;
begin
  sName:=UpperCase(sName);
  for Cnt:=0 to Ctrls.Count-1 do
    if Ctrls[Cnt]=sName then
    if (Ctrls.Objects[Cnt].ClassName='TImage') then
    with TImage(Ctrls.Objects[Cnt]).Canvas do
  begin
    Pen.Color:=C;
    Pen.Width:=W;
    MoveTo(X1,Y1);
    LineTo(X2,Y2);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuObj.ImageEllipse(sName:String;X1,Y1,X2,Y2,C : Integer; Fill:Boolean; W:Integer=1);
var
  Cnt : Integer;
begin
  sName:=UpperCase(sName);
  for Cnt:=0 to Ctrls.Count-1 do
    if Ctrls[Cnt]=sName then
    if (Ctrls.Objects[Cnt].ClassName='TImage') then
    with TImage(Ctrls.Objects[Cnt]).Canvas do
  begin
    Pen.Color:=C;
    Pen.Width:=W;
    Brush.Color:=C;
    if Fill then Brush.Style:=bsSolid
    else Brush.Style:=bsClear;
    Ellipse(X1,Y1,X2,Y2);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuObj.ImageRectangle(sName:String;X1,Y1,X2,Y2,C : Integer; Fill:Boolean; W:Integer=1);
var
  Cnt : Integer;
begin
  sName:=UpperCase(sName);
  for Cnt:=0 to Ctrls.Count-1 do
    if Ctrls[Cnt]=sName then
    if (Ctrls.Objects[Cnt].ClassName='TImage') then
    with TImage(Ctrls.Objects[Cnt]).Canvas do
  begin
    Pen.Color:=C;
    Pen.Width:=W;
    Brush.Color:=C;
    if Fill then Brush.Style:=bsSolid
    else Brush.Style:=bsClear;
    Rectangle(X1,Y1,X2,Y2);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuObj.ImagePix(sName : String; X,Y,C : Integer);
var
  Cnt : Integer;
begin
  sName:=UpperCase(sName);
  for Cnt:=0 to Ctrls.Count-1 do
    if Ctrls[Cnt]=sName then
    if (Ctrls.Objects[Cnt].ClassName='TImage') then
    with TImage(Ctrls.Objects[Cnt]).Canvas do
      Pixels[X,Y]:=C;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuObj.ImagePixLine(sName : String; X,Y : Integer; Data : String);
type
  TPixel = packed Array[0..3] of Byte;
  TPixArray = packed Array[0..99999] of TPixel;
const
  Feed : Array[0..2] of Byte = ($FE,$EE,$ED);
var
  Cnt  : Integer;
  Cnt2 : Integer;
  Cnt3 : Integer;
  Pix  : ^TPixArray;
  X2   : Integer;
  sBuf : String;
begin
  sName:=UpperCase(sName);
  for Cnt:=0 to Ctrls.Count-1 do
    if Ctrls[Cnt]=sName then
    if (Ctrls.Objects[Cnt].ClassName='TImage') then
    with TImage(Ctrls.Objects[Cnt]).Picture.Bitmap,TImage(Ctrls.Objects[Cnt]) do
  begin
    if (Y<0)or(Y>=Height) then Continue;
    X2:=X-1+Length(Data)div 3;
    if (X<0)or(X2>=Width) then Continue;

    sBuf:=UpperCase(Data);
    Pix:=ScanLine[Y];
    for Cnt2:=X to X2 do
    begin
      Pix[Cnt2][3]:=0;
      for Cnt3:=2 downto 0 do
      case Byte(sBuf[3-Cnt3]) of
        65..90 : Pix[Cnt2][Cnt3]:=8*(Byte(sBuf[3-Cnt3])-65);
        49..54 : Pix[Cnt2][Cnt3]:=8*(Byte(sBuf[3-Cnt3])-23);
        57     : begin end;
        56     : Pix[Cnt2][Cnt3]:=Feed[Cnt3];
        else       Exit;
      end;
      Delete(sBuf,1,3);
    end;

    Canvas.Pixels[0,0]:=Canvas.Pixels[0,0]; //Force update!
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuObj.ImageFloodFill(sName : String; X,Y,C : Integer);
var
  Cnt : Integer;
begin
  sName:=UpperCase(sName);
  for Cnt:=0 to Ctrls.Count-1 do
    if Ctrls[Cnt]=sName then
    if (Ctrls.Objects[Cnt].ClassName='TImage') then
    with TImage(Ctrls.Objects[Cnt]).Canvas do
  begin
    Brush.Color:=C;
    FloodFill(X,Y,Pixels[X,Y],fsSurface);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuObj.ImageFile(sName : String; X,Y : Integer; FN : String);
var
  Cnt : Integer;
  OGr : TOleGraphic;
  FS  : TFileStream;
begin
  if not FileExists(FN) then Exit;
  sName:=UpperCase(sName);
  for Cnt:=0 to Ctrls.Count-1 do
    if Ctrls[Cnt]=sName then
    if (Ctrls.Objects[Cnt].ClassName='TImage') then
    with TImage(Ctrls.Objects[Cnt]) do
  begin
    OGr:=TOleGraphic.Create;
    FS:=TFileStream.Create(FN,fmOpenRead or fmSharedenyNone);
    try
      OGr.LoadFromStream(FS);
      Canvas.Draw(X,Y,OGr);
    except end;
    FS.Free;
    OGr.Free;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuObj.Test;
begin
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuObj.MyButtonClick(Sender : TObject);
var
  Cnt : Integer;
begin
  for Cnt:=0 to Ctrls.Count-1 do
    if Ctrls.Objects[Cnt]=Sender then
      MenuButton:=Ctrls[Cnt];
end;

////////////////////////////////////////////////////////////////////////////////
procedure TMenuObj.MyComboSelect(Sender : TObject);
begin
  TComboBox(Sender).Tag:=TComboBox(Sender).ItemIndex;
end;

////////////////////////////////////////////////////////////////////////////////
{***menu.dfm***
object MenuForm: TMenuForm
  Left = 10
  Top = 10
  Width = 200
  Height = 100
  Caption = 'EUO Menu'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Arial'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
end}

end.


