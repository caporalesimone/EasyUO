unit text;
interface
uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
     Buttons, ExtCtrls;

type
  TTextForm = class(TForm)
    TextMemo: TMemo;
    BottomPanel: TPanel;
    BottomLabel: TLabel;
    ButtonPanel: TPanel;
    OKButton: TButton;
    CancelButton: TButton;
    procedure FormResize(Sender: TObject);
  end;

var
  TextForm: TTextForm;

implementation
{$R *.dfm}

procedure TTextForm.FormResize(Sender: TObject);
begin
  ButtonPanel.Left:=(BottomPanel.Width-ButtonPanel.Width) div 2;
end;

end.
