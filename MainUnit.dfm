object MainForm: TMainForm
  Left = 544
  Top = 392
  BorderIcons = [biSystemMenu]
  Caption = 'OPC Server - '#1046#1054#1060' / '#1060#1057#1054' [306 Team]'
  ClientHeight = 142
  ClientWidth = 518
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCloseQuery = FormCloseQuery
  PixelsPerInch = 120
  TextHeight = 16
  object ActionMainMenuBar1: TActionMainMenuBar
    Left = 0
    Top = 0
    Width = 518
    Height = 30
    ActionManager = ActionManager1
    Caption = 'ActionMainMenuBar1'
    Color = clMenuBar
    ColorMap.DisabledFontColor = 7171437
    ColorMap.HighlightColor = clWhite
    ColorMap.BtnSelectedFont = clBlack
    ColorMap.UnusedColor = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clMenuText
    Font.Height = -15
    Font.Name = 'Segoe UI'
    Font.Style = []
    Spacing = 0
    ExplicitLeft = 472
    ExplicitTop = 168
    ExplicitWidth = 150
    ExplicitHeight = 29
  end
  object ActionManager1: TActionManager
    ActionBars = <
      item
        Items = <
          item
            Action = Action1
          end>
        ActionBar = ActionMainMenuBar1
      end>
    Left = 216
    Top = 48
    StyleName = 'Platform Default'
    object Action1: TAction
      Caption = #1042#1099#1093#1086#1076
      OnExecute = Action1Execute
    end
  end
end
