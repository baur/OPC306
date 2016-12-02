{ ------------------------------------------------------------ }
{ The MIT License (MIT)

  prOpc Toolkit
  Copyright (c) 2000, 2001 Production Robots Engineering Ltd

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE. }
{ ------------------------------------------------------------ }
unit OpcServerUnit;

interface

uses
  SysUtils, Classes, prOpcServer, prOpcTypes, Generics.collections, prOpcDa, Windows, DateUtils;

type
  TOPC306 = class(TOpcItemServer)

  private
  protected
    function Options: TServerOptions; override;
  public
    function GetItemInfo(const ItemID: String; var AccessPath: string;
      var AccessRights: TAccessRights): integer; override;
    procedure ReleaseHandle(ItemHandle: TItemHandle); override;
    procedure ListItemIds(List: TItemIDList); override;
    function GetItemVQT(ItemHandle: TItemHandle; var Quality: Word; var Timestamp: TFileTime)
      : OleVariant; override;
    procedure SetItemValue(ItemHandle: TItemHandle; const Value: OleVariant); override;
    function getTagQuality(): Word;
    function getTagDateTime(): TDateTime;
  end;

const
  FIVE_MIN = 300;

implementation

uses
  prOpcError, MainUnit, uDM, uDMUtil;

{$IFDEF NewBranch}

procedure TOPC306.ListItemIds(List: TItemIDList);
begin
  InitTagList;
  with List.AddBranch('FSO') do
  begin
    with AddBranch('Drum') do
    begin
      AddItemId('Drum1.T_Burner', [iaRead], varDouble);
      AddItemId('Drum2.T_Burner', [iaRead], varDouble);
      AddItemId('Drum3.T_Burner', [iaRead], varDouble);
      AddItemId('Drum1.T_Output', [iaRead], varDouble);
      AddItemId('Drum2.T_Output', [iaRead], varDouble);
      AddItemId('Drum3.T_Output', [iaRead], varDouble);
      AddItemId('Drum1.is_working', [iaRead], varBoolean);
      AddItemId('Drum2.is_working', [iaRead], varBoolean);
      AddItemId('Drum3.is_working', [iaRead], varBoolean);
    end;
  end
end;

{$ELSE}

procedure TOPC306.ListItemIds(List: TItemIDList);
begin
  List.AddItemId('FSO.Drum.Drum1.T_Burner', [iaRead], varDouble);
  List.AddItemId('FSO.Drum.Drum2.T_Burner', [iaRead], varDouble);
  List.AddItemId('FSO.Drum.Drum3.T_Burner', [iaRead], varDouble);
  List.AddItemId('FSO.Drum.Drum1.T_Output', [iaRead], varDouble);
  List.AddItemId('FSO.Drum.Drum2.T_Output', [iaRead], varDouble);
  List.AddItemId('FSO.Drum.Drum3.T_Output', [iaRead], varDouble);
  List.AddItemId('FSO.Drum.Drum1.is_working', [iaRead], varBoolean);
  List.AddItemId('FSO.Drum.Drum2.is_working', [iaRead], varBoolean);
  List.AddItemId('FSO.Drum.Drum3.is_working', [iaRead], varBoolean);
end;

{$ENDIF}

function TOPC306.GetItemInfo(const ItemID: String; var AccessPath: string;
  var AccessRights: TAccessRights): integer;
begin
  { Return a handle that will subsequently identify ItemID }
  { raise exception of type EOpcError if Item ID not recognised }
  if SameText(ItemID, 'FSO.Drum.Drum1.T_Burner') then
    result := 0
  else if SameText(ItemID, 'FSO.Drum.Drum2.T_Burner') then
    result := 1
  else if SameText(ItemID, 'FSO.Drum.Drum3.T_Burner') then
    result := 2
  else if SameText(ItemID, 'FSO.Drum.Drum1.T_Output') then
    result := 3
  else if SameText(ItemID, 'FSO.Drum.Drum2.T_Output') then
    result := 4
  else if SameText(ItemID, 'FSO.Drum.Drum3.T_Output') then
    result := 5
  else if SameText(ItemID, 'FSO.Drum.Drum1.is_working') then
    result := 6
  else if SameText(ItemID, 'FSO.Drum.Drum2.is_working') then
    result := 7
  else if SameText(ItemID, 'FSO.Drum.Drum3.is_working') then
    result := 8
  else
    raise EOpcError.create(OPC_E_INVALIDITEMID)
end;

function TOPC306.getTagQuality(): Word;
var
  tagQuality: Word;
begin
  tagQuality := OPC_QUALITY_GOOD;

  if (secondsBetween(getTagDateTime, now()) > FIVE_MIN) then
  begin
    tagQuality := OPC_QUALITY_BAD;
    DMUtil.ExceptionLogger(nil, 'Данные не обновляется ...');
  end;
  if (FSO.MetaD.status = false) then
  begin
    tagQuality := OPC_QUALITY_BAD;
    DMUtil.ExceptionLogger(nil, 'Ошибка при чтении данных из BDF файла ...');
  end;

  result := tagQuality;
end;

function TOPC306.getTagDateTime(): TDateTime;
begin
  try
    FormatSettings.DateSeparator := '.';
    FormatSettings.TimeSeparator := ':';
    FormatSettings.ShortDateFormat := 'dd.mm.yyyy';
    FormatSettings.ShortTimeFormat := 'hh24:mi:ss';
    result := StrToDateTime(FSO.MetaD.DATE + ' ' + FSO.MetaD.TIME, FormatSettings);
  except
    on E: Exception do
    begin
      result := now() - 1;
      DMUtil.ExceptionLogger(nil, 'getTagDateTime: ' + FSO.MetaD.DATE + ' ' + FSO.MetaD.TIME);
    end;
  end;
end;

procedure TOPC306.ReleaseHandle(ItemHandle: TItemHandle);
begin
  { Release the handle previously returned by GetItemInfo }
end;

function TOPC306.GetItemVQT(ItemHandle: TItemHandle; var Quality: Word; var Timestamp: TFileTime)
  : OleVariant;
begin
  DM.getDataFromDBF;
  Quality := getTagQuality();
  Timestamp := DateTimeToFileTime(getTagDateTime());

  case ItemHandle of
    0:
      result := FSO.Drum.Drum1.T_Burner;
    1:
      result := FSO.Drum.Drum2.T_Burner;
    2:
      result := FSO.Drum.Drum3.T_Burner;
    3:
      result := FSO.Drum.Drum1.T_Output;
    4:
      result := FSO.Drum.Drum2.T_Output;
    5:
      result := FSO.Drum.Drum3.T_Output;
    6:
      result := FSO.Drum.Drum1.is_working;
    7:
      result := FSO.Drum.Drum2.is_working;
    8:
      result := FSO.Drum.Drum3.is_working;
  else
    raise EOpcError.create(OPC_E_INVALIDHANDLE)
  end

end;

procedure TOPC306.SetItemValue(ItemHandle: TItemHandle; const Value: OleVariant);
begin
  { set the value of the item identified by ItemHandle }
  case ItemHandle of
    0:
      FSO.Drum.Drum1.T_Burner := Value;
    1:
      FSO.Drum.Drum2.T_Burner := Value;
    2:
      FSO.Drum.Drum3.T_Burner := Value;
    3:
      FSO.Drum.Drum1.T_Output := Value;
    4:
      FSO.Drum.Drum2.T_Output := Value;
    5:
      FSO.Drum.Drum3.T_Output := Value;
  else
    raise EOpcError.create(OPC_E_INVALIDHANDLE)
  end
end;

const
  ServerGuid: TGUID = '{8D0B5528-F4B5-4FEE-84F2-4DA6735678ED}';
  ServerVersion = 1;
  ServerDesc = 'OPC306 - OPC Server';
  ServerVendor = 'TEAM306';

function TOPC306.Options: TServerOptions;
begin
  result := [soHierarchicalBrowsing, soAlwaysAllocateErrorArrays]
end;

initialization

RegisterOPCServer(ServerGuid, ServerVersion, ServerDesc, ServerVendor, TOPC306.create)

end.
