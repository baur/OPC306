unit uDM;

interface

uses
  System.SysUtils, System.Classes, Data.DB, Data.Win.ADODB, Vcl.ExtCtrls,
  Vcl.Dialogs, IOUtils, Vcl.Graphics, IniFiles, Vcl.forms,
  prOpcServer, prOpcTypes, Generics.collections, prOpcDa, System.Variants,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.MSSQL, FireDAC.Phys.MSSQLDef, FireDAC.VCLUI.Wait,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client;

type

  TTagData = record
    Branch: string;
    SubBranch: string;
    BranchName: string;
    AccessRights: TAccessRights;
    VarType: integer;
    TagValue: OleVariant;
    TagDateTime: TDateTime;
  end;

  TTagList = record
    Branch: string;
    KeyLabel: string;
    ExternalTagName: string;
    KeyIndex: integer;
  end;

  TDM = class(TDataModule)
    ADOConnectionDBF: TADOConnection;
    ADOQuery: TADODataSet;
    Timer_getDataFromDBF: TTimer;
    ADOConnection: TADOConnection;
    ADOQuery_TSIGNAL: TADOQuery;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure Timer_getDataFromDBFTimer(Sender: TObject);
  private
    { Private declarations }
    procedure InitIni;
    procedure SaveIni;
    procedure InitDic;
    procedure AddTagData(IndexVal: integer; Branch1: string; Branch2: string; KeyValue: string; ExternalTagName: string;
      AccessRights: TAccessRights; VarType: integer);
    procedure ReadTagData1();
    procedure ReadTagData2();
    procedure ConnectToASUTPdb;
    procedure getDataJOF123_Signal;
    procedure SetFormatSettings;
  public
    { Public declarations }
    function OpenDBF(folderName: string; fileName: string): boolean;
    procedure GetData;
    procedure getDataFromDBF;
    function GetTagData(KeyValue: string): TTagData;
    procedure SetTagData(KeyValue: string; TagValue: variant; TagDateTime: TDateTime);
    function ATagList_IndexOf(const KeyLabel: string): TTagList;
  end;

  TAppData = record
    path: string;
  end;

  TFSORec = record
    dbf_read_status: boolean;
    TagData: TTagData;
  end;

CONST
  TAGCOUNT = 261;
  SIGNAL_FROM_FSO = 'FSO';
  SIGNAL_FROM_JOF123 = 'JOF123';
  CUSTOM_VALUE = 'CUSTOM_VALUE';

var
  DM: TDM;
  FSO: TFSORec;
  folderName, fileName: string;
  td: TTagData;
  tl: TTagList;
  TagDic: TDictionary<String, TTagData>;
  KeyVal: string;
  ATagList: array [0 .. TAGCOUNT] of TTagList;

implementation

{ %CLASSGROUP 'Vcl.Controls.TControl' }

uses uDMUtil, OpcServerUnit;
{$R *.dfm}

procedure TDM.ConnectToASUTPdb;
begin
  ADOConnection.Connected := true;
  ADOQuery_TSIGNAL.Open();
end;

procedure TDM.getDataJOF123_Signal;
begin
  ConnectToASUTPdb;
  ReadTagData2();
end;

procedure TDM.SetFormatSettings;
begin
  FormatSettings.DateSeparator := '.';
  FormatSettings.TimeSeparator := ':';
  FormatSettings.ShortDateFormat := 'dd.mm.yyyy';
  FormatSettings.ShortTimeFormat := 'hh24:mi:ss';
end;

procedure TDM.ReadTagData2();
var
  i: integer;
begin
  try

    for i := Low(ATagList) to High(ATagList) do
    begin
      if ATagList[i].Branch = SIGNAL_FROM_JOF123 then
        if (ATagList[i].ExternalTagName = '') then
          SetTagData(ATagList[i].KeyLabel, 0, ADOQuery_TSIGNAL.FieldByName('tdatetime').AsDateTime)
        else
          SetTagData(ATagList[i].KeyLabel, ADOQuery_TSIGNAL.FieldByName(ATagList[i].ExternalTagName).AsVariant,
            ADOQuery_TSIGNAL.FieldByName('tdatetime').AsDateTime);
    end;

  finally
      ADOQuery_TSIGNAL.Close;
      ADOConnection.Close;
  end;
end;

procedure TDM.ReadTagData1();
var
  i: integer;
  TagDT: TDateTime;
begin
  SetFormatSettings;
  TagDT := StrToDateTime(ADOQuery.FieldByName('DAT').asstring + ' ' + ADOQuery.FieldByName('TIMER').asstring,
    FormatSettings);

  for i := Low(ATagList) to High(ATagList) do
  begin
    if ATagList[i].Branch = SIGNAL_FROM_FSO then
      if (ATagList[i].ExternalTagName = '') then
        SetTagData(ATagList[i].KeyLabel, 0, TagDT)
      else
        SetTagData(ATagList[i].KeyLabel, ADOQuery.FieldByName(ATagList[i].ExternalTagName).AsVariant, TagDT);
  end;

end;

function TDM.ATagList_IndexOf(const KeyLabel: string): TTagList;
var
  i: integer;
begin
  for i := Low(ATagList) to High(ATagList) do
    if ATagList[i].KeyLabel = KeyLabel then
    begin
      tl.KeyLabel := ATagList[i].KeyLabel;
      tl.KeyIndex := i;
      result := tl;
    end;
end;

function TDM.GetTagData(KeyValue: string): TTagData;
begin
  TagDic.TryGetValue(KeyValue, td);
  result := td;
end;

procedure TDM.SetTagData(KeyValue: string; TagValue: variant; TagDateTime: TDateTime);
begin
  if TagDic.ContainsKey(KeyValue) then
  begin
    TagDic.TryGetValue(KeyValue, td);
    td.TagDateTime := TagDateTime;
    td.TagValue := TagValue;
    TagDic.AddOrSetValue(KeyValue, td);
  end;
end;

procedure TDM.Timer_getDataFromDBFTimer(Sender: TObject);
begin
  getDataFromDBF;
  getDataJOF123_Signal;
end;

procedure TDM.AddTagData(IndexVal: integer; Branch1: string; Branch2: string;
KeyValue: string; ExternalTagName: string;
  AccessRights: TAccessRights; VarType: integer);
begin
  if IndexVal <= TAGCOUNT then
  BEGIN
    td.Branch := Branch1;
    td.SubBranch := Branch2;
    td.BranchName := KeyValue;
    td.AccessRights := AccessRights;
    td.VarType := VarType;
    td.TagValue := 0;
    KeyVal := td.Branch + '.' + td.SubBranch + '.' + KeyValue;
    TagDic.Add(KeyVal, td);
    ATagList[IndexVal].KeyLabel := KeyVal;
    ATagList[IndexVal].KeyIndex := IndexVal;
    ATagList[IndexVal].Branch := Branch1;
    ATagList[IndexVal].ExternalTagName := ExternalTagName;
  END;
end;

procedure TDM.InitDic;
var
  i, j, k: integer;
  tagName: string;
begin
  TagDic := TDictionary<String, TTagData>.Create;
  AddTagData(0, SIGNAL_FROM_FSO, 'Drum', 'Drum1.T_Burner', 'T_TOPKI1', [iaRead], varDouble);
  AddTagData(1, SIGNAL_FROM_FSO, 'Drum', 'Drum2.T_Burner', 'T_TOPKI2', [iaRead], varDouble);
  AddTagData(2, SIGNAL_FROM_FSO, 'Drum', 'Drum3.T_Burner', 'T_TOPKI3', [iaRead], varDouble);
  AddTagData(3, SIGNAL_FROM_FSO, 'Drum', 'Drum1.T_Output', 'T_VIH_P1', [iaRead], varDouble);
  AddTagData(4, SIGNAL_FROM_FSO, 'Drum', 'Drum2.T_Output', 'T_VIH_P2', [iaRead], varDouble);
  AddTagData(5, SIGNAL_FROM_FSO, 'Drum', 'Drum3.T_Output', 'T_VIH_P3', [iaRead], varDouble);
  AddTagData(6, SIGNAL_FROM_FSO, 'Drum', 'Drum1.is_working', 'SBARABAN1', [iaRead], varBoolean);
  AddTagData(7, SIGNAL_FROM_FSO, 'Drum', 'Drum2.is_working', 'SBARABAN2', [iaRead], varBoolean);
  AddTagData(8, SIGNAL_FROM_FSO, 'Drum', 'Drum3.is_working', 'SBARABAN3', [iaRead], varBoolean);
  AddTagData(9, SIGNAL_FROM_FSO, 'Drum', 'Drum1.T_Bearing1', 'T_D1_1', [iaRead], varDouble);
  AddTagData(10, SIGNAL_FROM_FSO, 'Drum', 'Drum1.T_Bearing2', 'T_D1_2', [iaRead], varDouble);
  AddTagData(11, SIGNAL_FROM_FSO, 'Drum', 'Drum2.T_Bearing1', 'T_D2_1', [iaRead], varDouble);
  AddTagData(12, SIGNAL_FROM_FSO, 'Drum', 'Drum2.T_Bearing2', 'T_D2_2', [iaRead], varDouble);
  AddTagData(13, SIGNAL_FROM_FSO, 'Drum', 'Drum3.T_Bearing1', 'T_D3_1', [iaRead], varDouble);
  AddTagData(14, SIGNAL_FROM_FSO, 'Drum', 'Drum3.T_Bearing2', 'T_D3_2', [iaRead], varDouble);

  AddTagData(15, SIGNAL_FROM_FSO, 'Conveyor', 'C1.is_working', 'LENTK1_SB', [iaRead], varBoolean);
  AddTagData(16, SIGNAL_FROM_FSO, 'Conveyor', 'C2.is_working', 'LENTK2_SB', [iaRead], varBoolean);
  AddTagData(17, SIGNAL_FROM_FSO, 'Conveyor', 'C3.is_working', 'LENTK3_SB', [iaRead], varBoolean);
  AddTagData(18, SIGNAL_FROM_FSO, 'Conveyor', 'C4.is_working', 'LENTK4', [iaRead], varBoolean);
  AddTagData(19, SIGNAL_FROM_FSO, 'Conveyor', 'C4A.is_working', 'LENTK4A', [iaRead], varBoolean);
  AddTagData(20, SIGNAL_FROM_FSO, 'Conveyor', 'C5.is_working', 'LENTK5', [iaRead], varBoolean);
  AddTagData(21, SIGNAL_FROM_FSO, 'Conveyor', 'C6B.is_working', 'LENTK6B', [iaRead], varBoolean);
  AddTagData(22, SIGNAL_FROM_FSO, 'Conveyor', 'C6.is_working', 'LENTK6', [iaRead], varBoolean);
  AddTagData(23, SIGNAL_FROM_FSO, 'Conveyor', 'C6A.is_working', 'LENTKV6A', [iaRead], varBoolean);
  AddTagData(24, SIGNAL_FROM_FSO, 'Conveyor', 'C7.is_working', 'LENTK7', [iaRead], varBoolean);
  AddTagData(25, SIGNAL_FROM_FSO, 'Conveyor', 'C7A.is_working', 'LENTK7A', [iaRead], varBoolean);
  AddTagData(26, SIGNAL_FROM_FSO, 'Conveyor', 'C8.is_working', 'LENTK8', [iaRead], varBoolean);
  AddTagData(27, SIGNAL_FROM_FSO, 'Conveyor', 'C8A.is_working', 'LENTK8A', [iaRead], varBoolean);
  AddTagData(28, SIGNAL_FROM_FSO, 'Conveyor', 'C9.is_working', '', [iaRead], varBoolean);
  AddTagData(29, SIGNAL_FROM_FSO, 'Conveyor', 'C10.is_working', '', [iaRead], varBoolean);

  AddTagData(30, SIGNAL_FROM_FSO, 'Conveyor', 'C1.to_C4_is_working', 'LENTK1_4', [iaRead], varBoolean);
  AddTagData(31, SIGNAL_FROM_FSO, 'Conveyor', 'C2.to_C4_is_working', 'LENTK2_4', [iaRead], varBoolean);
  AddTagData(32, SIGNAL_FROM_FSO, 'Conveyor', 'C3.to_C4_is_working', 'LENTK3_4', [iaRead], varBoolean);

  AddTagData(33, SIGNAL_FROM_FSO, 'Filter', 'F1.is_working', 'VF1_RUN', [iaRead], varBoolean);
  AddTagData(34, SIGNAL_FROM_FSO, 'Filter', 'F2.is_working', 'VF2_RUN', [iaRead], varBoolean);
  AddTagData(35, SIGNAL_FROM_FSO, 'Filter', 'F3.is_working', 'VF3_RUN', [iaRead], varBoolean);
  AddTagData(36, SIGNAL_FROM_FSO, 'Filter', 'F4.is_working', 'VF4_RUN', [iaRead], varBoolean);
  AddTagData(37, SIGNAL_FROM_FSO, 'Filter', 'F5.is_working', 'VF5_RUN', [iaRead], varBoolean);
  AddTagData(38, SIGNAL_FROM_FSO, 'Filter', 'F6.is_working', 'VF6_RUN', [iaRead], varBoolean);
  AddTagData(39, SIGNAL_FROM_FSO, 'Filter', 'F7.is_working', 'VF7_RUN', [iaRead], varBoolean);
  AddTagData(40, SIGNAL_FROM_FSO, 'Filter', 'F8.is_working', 'VF8_RUN', [iaRead], varBoolean);
  AddTagData(41, SIGNAL_FROM_FSO, 'Filter', 'F9.is_working', 'VF9_RUN', [iaRead], varBoolean);

  AddTagData(42, SIGNAL_FROM_FSO, 'Conveyor', 'C5.FeedRate', 'VES_KONV5', [iaRead], varDouble);
  AddTagData(43, SIGNAL_FROM_FSO, 'Conveyor', 'C6.FeedRate', 'VES_KONV6', [iaRead], varDouble);
  AddTagData(44, SIGNAL_FROM_FSO, 'Conveyor', 'C7.FeedRate', 'VES_KONV7', [iaRead], varDouble);
  AddTagData(45, SIGNAL_FROM_FSO, 'Conveyor', 'C8.FeedRate', 'VES_KONV8', [iaRead], varDouble);

  AddTagData(46, SIGNAL_FROM_FSO, 'Thickener', 'Thickener1.is_working', 'SG1_RUN', [iaRead], varBoolean);
  AddTagData(47, SIGNAL_FROM_FSO, 'Thickener', 'Thickener2.is_working', 'SG2_RUN', [iaRead], varBoolean);
  AddTagData(48, SIGNAL_FROM_FSO, 'Thickener', 'Thickener3.is_working', 'SG3_RUN', [iaRead], varBoolean);
  AddTagData(49, SIGNAL_FROM_FSO, 'Filter', 'F1.is_washing', 'VF1_PROMV', [iaRead], varBoolean);
  AddTagData(50, SIGNAL_FROM_FSO, 'Filter', 'F4.is_washing', 'VF4_PROMV', [iaRead], varBoolean);
  AddTagData(51, SIGNAL_FROM_FSO, 'Filter', 'F7.is_washing', 'VF7_PROMV', [iaRead], varBoolean);
  AddTagData(52, SIGNAL_FROM_FSO, 'Filter', 'F1.must_be_washed', 'VF1_SIGN', [iaRead], varBoolean);
  AddTagData(53, SIGNAL_FROM_FSO, 'Filter', 'F7.must_be_washed', 'VF7_SIGN', [iaRead], varBoolean);
  AddTagData(54, SIGNAL_FROM_FSO, 'Filter', 'F4.must_be_washed', 'VF4_SIGN', [iaRead], varBoolean);

  AddTagData(55, SIGNAL_FROM_FSO, 'Filter', 'F1.water_pressure', 'VF1_P_H2O', [iaRead], varDouble);
  AddTagData(56, SIGNAL_FROM_FSO, 'Filter', 'F4.water_pressure', 'VF4_P_H2O', [iaRead], varDouble);
  AddTagData(57, SIGNAL_FROM_FSO, 'Filter', 'F7.water_pressure', 'VF7_P_H2O', [iaRead], varDouble);
  AddTagData(58, SIGNAL_FROM_FSO, 'Filter', 't_water_tank', 'T_VODA_BAK', [iaRead], varDouble);
  AddTagData(59, SIGNAL_FROM_FSO, 'Drum', 'Drum3.QM', 'FSO_QM3P', [iaRead], varDouble);
  AddTagData(60, SIGNAL_FROM_FSO, 'Filter', 'F1.vacuum', 'VF1_VAKUUM', [iaRead], varDouble);
  AddTagData(61, SIGNAL_FROM_FSO, 'Filter', 'F4.vacuum', 'VF4_VAKUUM', [iaRead], varDouble);
  AddTagData(62, SIGNAL_FROM_FSO, 'Filter', 'F7.vacuum', 'VF7_VAKUUM', [iaRead], varDouble);
  AddTagData(63, SIGNAL_FROM_FSO, 'Conveyor', 'C7.total', 'SCHET7', [iaRead], varDouble);
  AddTagData(64, SIGNAL_FROM_FSO, 'Conveyor', 'C8.total', 'SCHET8', [iaRead], varDouble);

  AddTagData(65, SIGNAL_FROM_JOF123, 'ALL', 'MINDIFF', 'MINDIFF', [iaRead], varInteger);

  k := 66;
  for i := 0 to 23 do
    for j := 0 to 7 do
    begin
      if i < 10 then
        tagName := 'S10' + IntToStr(i) + '_' + IntToStr(j)
      else
        tagName := 'S1' + IntToStr(i) + '_' + IntToStr(j);

      AddTagData(k, SIGNAL_FROM_JOF123, 'ALL', tagName, tagName, [iaRead], varBoolean);
      k := k + 1;
    end;

  AddTagData(258, CUSTOM_VALUE, 'Parameter', 'Date1', '', [iaRead, iaWrite], varOleStr);
  AddTagData(259, CUSTOM_VALUE, 'Parameter', 'Time1', '', [iaRead, iaWrite], varOleStr);
  AddTagData(260, CUSTOM_VALUE, 'Parameter', 'Date2', '', [iaRead, iaWrite], varOleStr);
  AddTagData(261, CUSTOM_VALUE, 'Parameter', 'Time2', '', [iaRead, iaWrite], varOleStr);


end;

procedure TDM.InitIni;
var
  appINI: TIniFile;
begin
  appINI := TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));
  try
    folderName := appINI.ReadString('DBF', 'folderName', '');
    if folderName = '' then
      folderName := ExtractFileDir(Application.ExeName);
    fileName := appINI.ReadString('DBF', 'fileName', '');
    if fileName = '' then
      fileName := 'mnem_fso_cpsh.dbf';
  finally
    appINI.Free;
  end;
end;

procedure TDM.SaveIni;
var
  appINI: TIniFile;
begin
  appINI := TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));
  try
    appINI.WriteString('DBF', 'folderName', folderName);
    appINI.WriteString('DBF', 'fileName ', fileName);
  finally
    appINI.Free;
  end;
end;

function TDM.OpenDBF(folderName: string; fileName: string): boolean;
begin
  try
    result := true;
    if not ADOConnectionDBF.Connected then
    begin
      ADOConnectionDBF.LoginPrompt := false;
      ADOConnectionDBF.ConnectionString :=
        Format('Provider=VFPOLEDB.1;Data Source=%s;Password="";Collating Sequence=MACHINE', [folderName]);
      ADOConnectionDBF.Connected := true;
    end;
    ADOQuery.close;
    ADOQuery.CommandText := 'Select * from ' + fileName;
    ADOQuery.Open;
  except
    on E: Exception do
    begin
      result := false;
      DMUtil.ExceptionLogger(E, 'OpenDBF');
    end;
  end;
end;

procedure TDM.DataModuleCreate(Sender: TObject);
begin
  InitIni;
  InitDic;
  Timer_getDataFromDBF.Enabled := true;
  Timer_getDataFromDBF.OnTimer(self);
end;

procedure TDM.DataModuleDestroy(Sender: TObject);
begin
  SaveIni;
  TagDic.Free;
end;

procedure TDM.GetData;
begin
  FSO.dbf_read_status := true;
  try
    ADOQuery.First;
    try
      ReadTagData1();
    except
      on E: Exception do
      begin
        FSO.dbf_read_status := false;
        DMUtil.ExceptionLogger(E, 'GetData');
      end;
    end;

  finally
    ADOQuery.close;
    ADOConnectionDBF.Connected := false;
  end;

end;

procedure TDM.getDataFromDBF;

begin
  if FileExists(folderName + '\' + fileName) then
  BEGIN
    if DM.OpenDBF(folderName, fileName) then
      GetData
    else
      FSO.dbf_read_status := false;
  END
  ELSE
  begin
    FSO.dbf_read_status := false;
    DMUtil.ExceptionLogger(nil, 'File: ' + fileName + ' not exists');
  end;
end;

end.
