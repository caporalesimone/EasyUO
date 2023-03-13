object TextForm: TTextForm
  Left = 940
  Top = 307
  Width = 416
  Height = 339
  BorderIcons = [biSystemMenu, biMaximize]
  Caption = 'Text Window'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Arial'
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 14
  object BottomLabel: TLabel
    Left = 0
    Top = 246
    Width = 408
    Height = 14
    Align = alBottom
    Alignment = taCenter
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    WordWrap = True
  end
  object TextMemo: TMemo
    Left = 0
    Top = 0
    Width = 408
    Height = 246
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 0
    WantTabs = True
    WordWrap = False
  end
  object BottomPanel: TPanel
    Left = 0
    Top = 260
    Width = 408
    Height = 45
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object ButtonPanel: TPanel
      Left = 88
      Top = 0
      Width = 233
      Height = 41
      BevelOuter = bvNone
      TabOrder = 0
      object OKButton: TButton
        Left = 8
        Top = 6
        Width = 105
        Height = 25
        Caption = '&OK'
        ModalResult = 1
        TabOrder = 0
      end
      object CancelButton: TButton
        Left = 120
        Top = 6
        Width = 105
        Height = 25
        Caption = '&Cancel'
        ModalResult = 2
        TabOrder = 1
      end
    end
  end
end
