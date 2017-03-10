program ImageLayoutDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  MainView in 'MainView.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
