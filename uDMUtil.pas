unit uDMUtil;

interface

uses
  System.SysUtils, System.Classes, Vcl.AppEvnts, Vcl.forms, inifiles;

type
  TDMUtil = class(TDataModule)
    ApplicationEvents1: TApplicationEvents;
    procedure ApplicationEvents1Exception(Sender: TObject; E: Exception);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure ExceptionLogger(E: Exception; s: string);
  end;

var
  DMUtil: TDMUtil;

implementation

{ %CLASSGROUP 'Vcl.Controls.TControl' }

{$R *.dfm}

procedure TDMUtil.ExceptionLogger(E: Exception; s: string);
var
  ErrorLogFileName: string;
  ErrorFile: TextFile;
  ErrorData: string;
begin
  ErrorLogFileName := ChangeFileExt(Application.ExeName, '.error.log');
  AssignFile(ErrorFile, ErrorLogFileName);
  // either create an error log file, or append to an existing one
  if FileExists(ErrorLogFileName) then
    Append(ErrorFile)
  else
    Rewrite(ErrorFile);
  try
    // add the current date/time and the exception message to the log
    if E <> nil then
      ErrorData := Format('%s : %s - %s', [DateTimeToStr(Now), E.ClassName,
        E.Message + '[' + s + ']']);
    if s <> '' then
      ErrorData := s;
    WriteLn(ErrorFile, ErrorData);
  finally
    CloseFile(ErrorFile)
  end;
end;

procedure TDMUtil.ApplicationEvents1Exception(Sender: TObject; E: Exception);
begin
  ExceptionLogger(E, 'Global');
end;

end.
