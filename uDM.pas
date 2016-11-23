unit uDM;

interface

uses
  System.SysUtils, System.Classes, Data.DB, Data.Win.ADODB, Vcl.ExtCtrls,
  Vcl.Dialogs, IOUtils, Vcl.Graphics, IniFiles, Vcl.forms;

type

  TDM = class(TDataModule)
    UpdateTimer: TTimer;
    ADOConnectionDBF: TADOConnection;
    ADOQuery: TADODataSet;
    procedure DataModuleCreate(Sender: TObject);
    procedure UpdateTimerTimer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure OpenDBF(folderName: string; fileName: string);
    procedure GetData;
    procedure SetOPCData;
  end;

  TAppData = record
    path: string;
  end;

  TFilterParam = record
    is_working: boolean;
    water_pressure: Double;
    vacuum: Double;
    must_be_washed: boolean;
    is_washing: boolean;
  end;

  TFilter = record
    F1: TFilterParam;
    F2: TFilterParam;
    F3: TFilterParam;
    F4: TFilterParam;
    F5: TFilterParam;
    F6: TFilterParam;
    F7: TFilterParam;
    F8: TFilterParam;
    F9: TFilterParam;
    t_water_tank: Double;
  end;

  TDrumParam = record
    is_working: boolean;
    T_Pillow_block1: Double;
    T_Pillow_block2: Double;
    T_Burner: Double;
    T_Output: Double;
    QM: Double;
  end;

  TThickenerParam = record
    is_working: boolean;
  end;

  TThickener = record
    Thickener1: TThickenerParam;
    Thickener2: TThickenerParam;
    Thickener3: TThickenerParam;
  end;

  TDrum = record
    Drum1: TDrumParam;
    Drum2: TDrumParam;
    Drum3: TDrumParam;
  end;

  TConvParam = record
    is_working: boolean;
    FeedRate: Double;
  end;

  TConveyor = record
    C1: TConvParam;
    C2: TConvParam;
    C3: TConvParam;
    C4: TConvParam;
    C4A: TConvParam;
    C5: TConvParam;
    C5B: TConvParam;
    C6: TConvParam;
    C6A: TConvParam;
    C7: TConvParam;
    C7A: TConvParam;
    C8: TConvParam;
    C8A: TConvParam;
    C9: TConvParam;
    C10: TConvParam;
  end;

  TControls = record
    IsEnabled: boolean;
  end;

  TMetaD = record
    ID: integer;
    TIME: string;
    DATE: string;
    FontColor: Tcolor;
    visible: boolean;
    Controls: TControls;
    isArchive: boolean;
    outdatedIndex: integer;
    WarningText: string;
  end;

  TFSO = record

    MetaD: TMetaD;
    Filter: TFilter;
    Conveyor: TConveyor;
    Drum: TDrum;
    Thickener: TThickener;
  end;


var
  DM: TDM;
  FSO: TFSO;
  folderName, fileName: string;

implementation

{ %CLASSGROUP 'Vcl.Controls.TControl' }

uses uDMUtil, OpcServerUnit;

{$R *.dfm}

procedure TDM.OpenDBF(folderName: string; fileName: string);
begin
  try
    if not ADOConnectionDBF.Connected then
    begin
      ADOConnectionDBF.LoginPrompt := false;
      ADOConnectionDBF.ConnectionString :=
        Format('Provider=VFPOLEDB.1;Data Source=%s;Password="";Collating Sequence=MACHINE',
        [folderName]);
      ADOConnectionDBF.Connected := True;
    end;
    ADOQuery.close;
    ADOQuery.CommandText := 'Select * from ' + fileName;
    ADOQuery.Open;
  except
    on E: Exception do
      DMUtil.ExceptionLogger(E, '');
  end;
end;

procedure TDM.DataModuleCreate(Sender: TObject);
var
  Ini: TIniFile;
begin
//  folderName := 'c:\Users\DASUP\Documents\Embarcadero\Studio\Projects\OPC306\Win32\Release';
  folderName := ExtractFileDir(Application.ExeName);
  fileName := 'mnem_fso_cpsh.dbf';
end;

procedure TDM.GetData;
begin
  FSO.MetaD.FontColor := clRed;
  try
    ADOQuery.First;
    begin
      { *ћета - данные* }
      FSO.MetaD.ID := ADOQuery.FieldByName('NOM').AsInteger;
      FSO.MetaD.TIME := ADOQuery.FieldByName('TIMER').asstring;
      FSO.MetaD.DATE := ADOQuery.FieldByName('DAT').asstring;

      { *‘ильтры Ц состо€ние* }
      FSO.Filter.F1.is_working := (ADOQuery.FieldByName('VF1_RUN').Value) or
        (ADOQuery.FieldByName('LENTK1_4').Value);
      FSO.Filter.F2.is_working := (ADOQuery.FieldByName('VF2_RUN').Value) or
        (ADOQuery.FieldByName('LENTK2_4').Value);
      FSO.Filter.F3.is_working := (ADOQuery.FieldByName('VF3_RUN').Value) or
        (ADOQuery.FieldByName('LENTK3_4').Value);
      FSO.Filter.F4.is_working := ADOQuery.FieldByName('VF4_RUN').Value;
      FSO.Filter.F5.is_working := ADOQuery.FieldByName('VF5_RUN').Value;
      FSO.Filter.F6.is_working := ADOQuery.FieldByName('VF6_RUN').Value;
      FSO.Filter.F7.is_working := ADOQuery.FieldByName('VF7_RUN').Value;
      FSO.Filter.F8.is_working := ADOQuery.FieldByName('VF8_RUN').Value;
      FSO.Filter.F9.is_working := ADOQuery.FieldByName('VF9_RUN').Value;

      FSO.Filter.F1.vacuum := ADOQuery.FieldByName('VF1_VAKUUM').Value;
      FSO.Filter.F1.water_pressure := ADOQuery.FieldByName('VF1_P_H2O').Value;
      FSO.Filter.F1.must_be_washed := ADOQuery.FieldByName('VF1_SIGN').Value;
      FSO.Filter.F1.is_washing := ADOQuery.FieldByName('VF1_PROMV').Value;

      FSO.Filter.F4.vacuum := ADOQuery.FieldByName('VF4_VAKUUM').Value;
      FSO.Filter.F4.water_pressure := ADOQuery.FieldByName('VF4_P_H2O').Value;
      FSO.Filter.F4.must_be_washed := ADOQuery.FieldByName('VF4_SIGN').Value;
      FSO.Filter.F4.is_washing := ADOQuery.FieldByName('VF4_PROMV').Value;

      FSO.Filter.F7.vacuum := ADOQuery.FieldByName('VF7_VAKUUM').Value;
      FSO.Filter.F7.water_pressure := ADOQuery.FieldByName('VF7_P_H2O').Value;
      FSO.Filter.F7.must_be_washed := ADOQuery.FieldByName('VF7_SIGN').Value;
      FSO.Filter.F7.is_washing := ADOQuery.FieldByName('VF7_PROMV').Value;
      FSO.Filter.t_water_tank := ADOQuery.FieldByName('T_VODA_BAK').Value;

      { * онвейеры - состо€ние* }
      FSO.Conveyor.C1.is_working := ADOQuery.FieldByName('LENTK1_SB').Value;
      FSO.Conveyor.C2.is_working := ADOQuery.FieldByName('LENTK2_SB').Value;
      FSO.Conveyor.C3.is_working := ADOQuery.FieldByName('LENTK3_SB').Value;
      FSO.Conveyor.C4.is_working := ADOQuery.FieldByName('LENTK4').Value;
      FSO.Conveyor.C4A.is_working := ADOQuery.FieldByName('LENTK4A').Value;
      FSO.Conveyor.C5.is_working := ADOQuery.FieldByName('LENTK5').Value;
      FSO.Conveyor.C5B.is_working := ADOQuery.FieldByName('LENTK6B').Value;
      FSO.Conveyor.C6.is_working := ADOQuery.FieldByName('LENTK6').Value;
      FSO.Conveyor.C6A.is_working := ADOQuery.FieldByName('LENTKV6A').Value;
      FSO.Conveyor.C7.is_working := ADOQuery.FieldByName('LENTK7').Value;
      FSO.Conveyor.C7A.is_working := ADOQuery.FieldByName('LENTK7A').Value;
      FSO.Conveyor.C8.is_working := ADOQuery.FieldByName('LENTK8').Value;
      FSO.Conveyor.C8A.is_working := ADOQuery.FieldByName('LENTK8A').Value;
      FSO.Conveyor.C9.is_working := false;
      FSO.Conveyor.C10.is_working := false;

      { * онвейеры - скорость подачи руды* }
      FSO.Conveyor.C5.FeedRate := ADOQuery.FieldByName('VES_KONV5').Value;
      FSO.Conveyor.C6.FeedRate := ADOQuery.FieldByName('VES_KONV6').Value;
      FSO.Conveyor.C7.FeedRate := ADOQuery.FieldByName('VES_KONV7').Value;
      FSO.Conveyor.C8.FeedRate := ADOQuery.FieldByName('VES_KONV8').Value;

      { *—ушильные барабаны Ц состо€ние* }
      FSO.Drum.Drum1.is_working := ADOQuery.FieldByName('SBARABAN1').Value;
      FSO.Drum.Drum2.is_working := ADOQuery.FieldByName('SBARABAN2').Value;
      FSO.Drum.Drum3.is_working := ADOQuery.FieldByName('SBARABAN3').Value;

      { *—ушильные барабаны Ц расход мзута* }
      FSO.Drum.Drum3.QM := ADOQuery.FieldByName('FSO_QM3P').Value;

      { *—ушильные барабаны Ц температура в топке* }
      FSO.Drum.Drum1.T_Burner := ADOQuery.FieldByName('T_TOPKI1').Value;
      FSO.Drum.Drum2.T_Burner := ADOQuery.FieldByName('T_TOPKI2').Value;
      FSO.Drum.Drum3.T_Burner := ADOQuery.FieldByName('T_TOPKI3').Value;

      { *—ушильные барабаны Ц температура на выходе печи* }
      FSO.Drum.Drum1.T_Output := ADOQuery.FieldByName('T_VIH_P1').Value;
      FSO.Drum.Drum2.T_Output := ADOQuery.FieldByName('T_VIH_P2').Value;
      FSO.Drum.Drum3.T_Output := ADOQuery.FieldByName('T_VIH_P3').Value;

      { *—ушильные барабаны Ц “емпература подшипников* }
      FSO.Drum.Drum1.T_Pillow_block1 := ADOQuery.FieldByName('T_D1_1').Value;
      FSO.Drum.Drum1.T_Pillow_block2 := ADOQuery.FieldByName('T_D1_2').Value;
      FSO.Drum.Drum2.T_Pillow_block1 := ADOQuery.FieldByName('T_D2_1').Value;
      FSO.Drum.Drum2.T_Pillow_block2 := ADOQuery.FieldByName('T_D2_2').Value;
      FSO.Drum.Drum3.T_Pillow_block1 := ADOQuery.FieldByName('T_D3_1').Value;
      FSO.Drum.Drum3.T_Pillow_block2 := ADOQuery.FieldByName('T_D3_2').Value;

      { *—густители - состо€ние* }
      FSO.Thickener.Thickener1.is_working :=
        ADOQuery.FieldByName('SG1_RUN').Value;
      FSO.Thickener.Thickener2.is_working :=
        ADOQuery.FieldByName('SG2_RUN').Value;
      FSO.Thickener.Thickener3.is_working :=
        ADOQuery.FieldByName('SG3_RUN').Value;
    end;

  finally
    ADOQuery.close;
    ADOConnectionDBF.Connected := false;
    FSO.MetaD.isArchive := false;
  end;

end;

procedure TDM.SetOPCData;
begin
//  tdemo16.SetItemValue(0,FSO.Drum.Drum1.T_Burner);
//  tdemo16.SetItemValue(1,FSO.Drum.Drum2.T_Burner);
//  tdemo16.SetItemValue(2,FSO.Drum.Drum3.T_Burner);
//  tdemo16.SetItemValue(3,FSO.Drum.Drum1.T_Output);
//  tdemo16.SetItemValue(4,FSO.Drum.Drum2.T_Output);
//  tdemo16.SetItemValue(5,FSO.Drum.Drum3.T_Output);
end;

procedure TDM.UpdateTimerTimer(Sender: TObject);
begin
  DM.OpenDBF(folderName, fileName);
  GetData;
  SetOPCData;
  UpdateTimer.Interval := 1000;
end;

end.
