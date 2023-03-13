program EasyUO;

uses
  Forms,
  main in 'main.pas' {MainForm},
  text in 'text.pas' {TextForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TTextForm, TextForm);
  Application.Run;
end.
