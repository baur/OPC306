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
    function GetItemInfo(const ItemID: String; var AccessPath: string; var AccessRights: TAccessRights)
      : integer; override;
    procedure ReleaseHandle(ItemHandle: TItemHandle); override;
    procedure ListItemIds(List: TItemIDList); override;
    function GetItemVQT(ItemHandle: TItemHandle; var Quality: Word; var Timestamp: TFileTime): OleVariant; override;
    procedure SetItemValue(ItemHandle: TItemHandle; const Value: OleVariant); override;
    function getTagQuality(Branch: string;TagDT:TDateTime): Word;
  end;

const
  FIVE_MIN = 300;

implementation

uses
  prOpcError, MainUnit, uDM, uDMUtil;

{$IFDEF NewBranch}

procedure TOPC306.ListItemIds(List: TItemIDList);
  procedure ListBranchItems(BranchName: string);
  begin
    with AddBranch(BranchName) do
    begin
      for i := 0 to TAGCOUNT do
      begin
        td := DM.GetTagData(ATagList[i]);
        if td.SubBranch = BranchName then
          AddItemId(td.BranchName, td.AccessRights, td.VarType);
      end;
    end;
  end;

var
  i: integer;
begin
  with List.AddBranch(SIGAL_FROM_FSO) do
  begin
    ListBranchItems('Drum');
    ListBranchItems('Conveyor');
    ListBranchItems('Filter');
  end

  with List.AddBranch(SIGAL_FROM_JOF123) do
  begin
    ListBranchItems('ALL');
  end

  with List.AddBranch(CUSTOM_VALUE) do
  begin
    ListBranchItems'Parameter');
  end

end;

{$ELSE}

procedure TOPC306.ListItemIds(List: TItemIDList);
var
  i: integer;
begin
  for i := Low(ATagList) to High(ATagList) do
  begin
    td := DM.GetTagData(ATagList[i].KeyLabel);
    List.AddItemId(td.Branch + '.' + td.SubBranch + '.' + td.BranchName, td.AccessRights, td.VarType);
  end;
end;

{$ENDIF}

function TOPC306.GetItemInfo(const ItemID: String; var AccessPath: string; var AccessRights: TAccessRights): integer;
begin
  { Return a handle that will subsequently identify ItemID }
  { raise exception of type EOpcError if Item ID not recognised }
  if SameText(ItemID, DM.ATagList_IndexOf(ItemID).KeyLabel) then
    result := DM.ATagList_IndexOf(ItemID).KeyIndex
  else
    raise EOpcError.create(OPC_E_INVALIDITEMID)
end;

function TOPC306.getTagQuality(Branch: string;TagDT:TDateTime): Word;
var
  tagQuality: Word;
begin
  tagQuality := OPC_QUALITY_GOOD;

  if Branch = SIGNAL_FROM_FSO then
  begin
    if (secondsBetween(TagDT, now()) > FIVE_MIN) then
    begin
      tagQuality := OPC_QUALITY_BAD;
      DMUtil.ExceptionLogger(nil, 'Данные не обновляется ...');
    end;
    if (FSO.dbf_read_status = false) then
    begin
      tagQuality := OPC_QUALITY_BAD;
      DMUtil.ExceptionLogger(nil, 'Ошибка при чтении данных из BDF файла ...');
    end;
  end;

  result := tagQuality;
end;

procedure TOPC306.ReleaseHandle(ItemHandle: TItemHandle);
begin
  { Release the handle previously returned by GetItemInfo }
end;

function TOPC306.GetItemVQT(ItemHandle: TItemHandle; var Quality: Word; var Timestamp: TFileTime): OleVariant;
begin
  case ItemHandle of
    Low(ATagList) .. High(ATagList):
      begin
        td := DM.GetTagData(ATagList[ItemHandle].KeyLabel);
        Quality := getTagQuality(td.Branch,td.TagDateTime);
        Timestamp := DateTimeToFileTime(td.TagDateTime);
        result := td.TagValue;
      end
  else
    raise EOpcError.create(OPC_E_INVALIDHANDLE)
  end

end;

procedure TOPC306.SetItemValue(ItemHandle: TItemHandle; const Value: OleVariant);
begin
  { set the value of the item identified by ItemHandle }
  case ItemHandle of
    Low(ATagList) .. High(ATagList):
      DM.SetTagData(ATagList[ItemHandle].KeyLabel, Value,Now());
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

end.
