program OPC306;

uses
  Vcl.Forms,
  MainUnit in 'MainUnit.pas' {Form1},
  OpcServerUnit in 'OpcServerUnit.pas',
  uDM in 'uDM.pas' {DM: TDataModule},
  uDMUtil in 'uDMUtil.pas' {DMUtil: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TDM, DM);
  Application.CreateForm(TDMUtil, DMUtil);
  Application.Run;
end.
