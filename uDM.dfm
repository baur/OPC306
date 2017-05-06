object DM: TDM
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Height = 430
  Width = 508
  object ADOConnectionDBF: TADOConnection
    ConnectionString = 
      'Provider=VFPOLEDB.1;Data Source=C:\ASUTP\001.WORK\'#1055#1088#1086#1077#1082#1090#1099'\'#1046#1054#1060'\'#1055#1077 +
      #1088#1077#1076#1072#1095#1072' '#1090#1077#1093#1085#1086#1083#1086#1075#1080#1095#1077#1089#1082#1080#1093' '#1076#1072#1085#1085#1099#1093' '#1060#1057#1054'\delphi\SCADA_FSO_DBF\Win32\Deb' +
      'ug\data;Collating Sequence=MACHINE;'
    LoginPrompt = False
    Mode = cmShareDenyNone
    Provider = 'VFPOLEDB.1'
    Left = 87
    Top = 48
  end
  object ADOQuery: TADODataSet
    Connection = ADOConnectionDBF
    Parameters = <>
    Left = 240
    Top = 136
  end
  object Timer_getDataFromDBF: TTimer
    Interval = 15000
    OnTimer = Timer_getDataFromDBFTimer
    Left = 144
    Top = 216
  end
  object ADOConnection: TADOConnection
    LoginPrompt = False
    Provider = 'SQLOLEDB.1'
    Left = 320
    Top = 56
  end
  object ADOQuery_TSIGNAL: TADOQuery
    Connection = ADOConnection
    Parameters = <>
    SQL.Strings = (
      'SELECT * FROM [ASUTP].[SCADA].[vJOF123_TSIGNAL]')
    Left = 352
    Top = 328
  end
end
