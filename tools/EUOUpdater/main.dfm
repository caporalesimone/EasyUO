object MainForm: TMainForm
  Left = 193
  Top = 114
  Width = 744
  Height = 516
  Caption = 'EUO Updtr'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Arial'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 16
  object MainPanel: TPanel
    Left = 0
    Top = 0
    Width = 736
    Height = 482
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    Visible = False
    object MainSplitter: TSplitter
      Left = 363
      Top = 0
      Height = 408
      Align = alRight
    end
    object ScanMemo: TMemo
      Left = 0
      Top = 0
      Width = 363
      Height = 408
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
    object ResMemo: TMemo
      Left = 366
      Top = 0
      Width = 370
      Height = 408
      Align = alRight
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Courier New'
      Font.Style = []
      ParentFont = False
      ScrollBars = ssBoth
      TabOrder = 1
      WordWrap = False
    end
    object BottomPanel: TPanel
      Left = 0
      Top = 408
      Width = 736
      Height = 74
      Align = alBottom
      TabOrder = 2
      DesignSize = (
        736
        74)
      object ScanLabel: TLabel
        Left = 8
        Top = 8
        Width = 79
        Height = 16
        Caption = 'Scan Strings:'
      end
      object ResLabel: TLabel
        Left = 365
        Top = 8
        Width = 66
        Height = 16
        Anchors = [akTop, akRight]
        Caption = 'Result List:'
      end
      object StartButton: TButton
        Left = 8
        Top = 32
        Width = 97
        Height = 25
        Caption = 'Start'
        TabOrder = 0
        OnClick = StartButtonClick
      end
    end
  end
  object SysTimer: TTimer
    Interval = 250
    OnTimer = SysTimerTimer
    Left = 8
    Top = 8
  end
end
