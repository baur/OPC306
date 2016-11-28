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
  SysUtils, Classes, prOpcServer, prOpcTypes, Generics.collections, prOpcDa;

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
    function GetItemValue(ItemHandle: TItemHandle; var Quality: word)
      : OleVariant; override;
    procedure SetItemValue(ItemHandle: TItemHandle;
      const Value: OleVariant); override;
  end;

implementation

uses
  prOpcError, Windows, MainUnit, uDM;

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
    end;
  end
end;

{$ELSE}

procedure TOPC306.ListItemIds(List: TItemIDList);
var
  key: string;
begin
  { why this is duplicates with above? }
  List.AddItemId('FSO.Drum.Drum1.T_Burner', [iaRead], varDouble);
  List.AddItemId('FSO.Drum.Drum2.T_Burner', [iaRead], varDouble);
  List.AddItemId('FSO.Drum.Drum3.T_Burner', [iaRead], varDouble);
  List.AddItemId('FSO.Drum.Drum1.T_Output', [iaRead], varDouble);
  List.AddItemId('FSO.Drum.Drum2.T_Output', [iaRead], varDouble);
  List.AddItemId('FSO.Drum.Drum3.T_Output', [iaRead], varDouble);
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
  else
    raise EOpcError.create(OPC_E_INVALIDITEMID)

end;

procedure TOPC306.ReleaseHandle(ItemHandle: TItemHandle);
begin
  { Release the handle previously returned by GetItemInfo }
end;

function TOPC306.GetItemValue(ItemHandle: TItemHandle; var Quality: word)
  : OleVariant;
begin
  { return the value of the item identified by ItemHandle }
  SetItemQuality(ItemHandle, $08);
  SetItemTimestamp(ItemHandle, DateTimeToFileTime(now()));
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
  else
    raise EOpcError.create(OPC_E_INVALIDHANDLE)
  end
end;

procedure TOPC306.SetItemValue(ItemHandle: TItemHandle;
  const Value: OleVariant);
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

RegisterOPCServer(ServerGuid, ServerVersion, ServerDesc, ServerVendor,
  TOPC306.create)

end.
