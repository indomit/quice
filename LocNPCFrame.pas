unit LocNPCFrame;

interface

uses
 JvToolEdit, ExtCtrls, Windows, Messages, SysUtils, StrUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, TextFieldEditorUnit, Mask, JvExMask, ZDataset;

type
TLabeledEdit = class(ExtCtrls.TLabeledEdit);

TNPCTextLoc = class(TFrame)
    gbNPCTextLoc: TGroupBox;
    Panel1: TPanel;
    edlxentry: TJvComboEdit;
    lblxentry: TLabel;
    btnpctext: TButton;
    procedure edlxentryButtonClick(Sender: TObject);
    procedure LoadLocalesNPCText(textentry: string);
    procedure FillLocFields(Query: TZQuery; pfx: string);
    procedure CompleteLocalesNPCText;
    function MakeUpdate(tn: string; pfx: string; KeyName: string; KeyValue: string): string;
    procedure btNPCTextClick(Sender: TObject);
  private
    { Private declarations }
  public
   procedure CreateLocalesNPCTextFields;
   procedure EditButtonClick(Sender: TObject);
  end;

implementation
uses MainUnit, MyDataModule, Functions;
{$R *.dfm}

procedure TNPCTextLoc.FillLocFields(Query: TZQuery; pfx: string);
var
  i, j: integer;
begin
  for i := 0 to ComponentCount - 1 do
  begin
   if (Components[i] is TCustomEdit) then
      for j := 0 to Query.Fields.Count - 1 do
        if LowerCase(Components[i].Name) = 'ed'+pfx+LowerCase(Query.Fields[j].FieldName) then
        begin
          if pfx = PFX_NPC_TEXT then
            TCustomEdit(Components[i]).Text := Query.Fields[j].AsString
          else
            TCustomEdit(Components[i]).Text := MainForm.DollToSym(Query.Fields[j].AsString);
        end;
  end;
end;

procedure TNPCTextLoc.LoadLocalesNPCText(textentry: string);
begin
  if trim(textentry) = '' then textentry := '-1';
  MainForm.MyQuery.SQL.Text := Format('SELECT * FROM `locales_npc_text` WHERE (`entry` = %s)',[textentry]);
  MainForm.MyQuery.Open;
  try
    FillLocFields(MainForm.MyQuery, PFX_LOCALES_NPC_TEXT);
    MainForm.MyQuery.Close;
  except
    on E: Exception do
      raise Exception.Create(dmMain.Text[145]+#10#13+E.Message);
  end;
end;

procedure TNPCTextLoc.CreateLocalesNPCTextFields;
var
  i, j, L: integer;
  ed: TCustomEdit;
  loc: string;
begin
  loc:= LoadLocales();
  for i := 0 to 7 do
  begin
    L := 8;
    for j := 0 to 1 do
    begin
      ed := TJvComboEdit.Create(self);
      ed.Parent := gbNPCTextLoc;
      case j of
        0: ed.Name := Format('edlxtext%d_0',[i])+loc;
        1: ed.Name := Format('edlxtext%d_1',[i])+loc;
      end;
      ed.Width := 415;
      if ed is TJvComboEdit then
      begin
        with TLabel.Create(Self) do
        begin
          Parent := gbNPCTextLoc;
          case j of
            0: Name := Format('lblxtext%d_0',[i])+loc;
            1: Name := Format('lblxtext%d_1',[i])+loc;
          end;
          Left := L;
          Top := 75 - 16 + i*(ed.Height + 24);
          Caption := MidStr(Name, 5, 20);
        end;
        TJvComboEdit(ed).Button.Glyph := MainForm.edqtZoneOrSort.Button.Glyph;
        TJvComboEdit(ed).OnButtonClick := EditButtonClick;
      end;

      ed.Text := '';
      ed.Top := 75 + i*(ed.Height + 24);
      ed.Left := L;
      L := L + ed.Width + 8;
    end;
  end;
end;

function TNPCTextLoc.MakeUpdate(tn: string; pfx: string; KeyName: string; KeyValue: string): string;
var
  i: integer;
  sets, FieldName, ValueFromBase, ValueFromEdit: string;
  C: TComponent;
begin
  Result := '';
  sets := '';
  MainForm.MyTempQuery.SQL.Text := Format('SELECT * FROM `%s` WHERE `%s` = %s',[tn, KeyName, KeyValue]);
  MainForm.MyTempQuery.Open;
  if not MainForm.MyTempQuery.Eof then
  begin

    for i := 0 to MainForm.MyTempQuery.Fields.Count - 1 do
    begin
      FieldName := MainForm.MyTempQuery.Fields[i].FieldName;
      ValueFromBase := MainForm.MyTempQuery.Fields[i].AsString;
      C := FindComponent('ed'+pfx+FieldName);
      if Assigned(C) and (C is TCustomEdit) then
      begin
        ValueFromEdit := MainForm.SymToDoll(TCustomEdit(C).Text);
        if ValueFromEdit <> ValueFromBase then
        begin
          if not MainForm.IsNumber(ValueFromEdit) then ValueFromEdit := QuotedStr(ValueFromEdit);
          if sets = '' then sets := Format('SET `%s` = %s',[FieldName, ValueFromEdit])
          else sets := Format('%s, `%s` = %s',[sets, FieldName, ValueFromEdit]);
        end;
      end
      else
      begin
        C := FindComponent('cb'+pfx+FieldName);
        if Assigned(C) and (C is TCheckBox) then
        begin
          if TCheckBox(C).Checked then ValueFromEdit := '1' else ValueFromEdit := '0';
          if ValueFromEdit <> ValueFromBase then
          begin
            if sets='' then sets := Format('SET `%s` = %s',[FieldName, ValueFromEdit])
            else sets := Format('%s, `%s` = %s',[sets, FieldName, ValueFromEdit]);
          end;
        end;
      end;
    end;
    if sets<>'' then
      Result := Format('UPDATE `%s` %s WHERE `%s` = %s;',[tn, sets, KeyName, KeyValue])
  end;
  MainForm.MyTempQuery.Close;
end;

procedure TNPCTextLoc.btNPCTextClick(Sender: TObject);
begin
  MainForm.PageControl3.ActivePageIndex := SCRIPT_TAB_NO_CREATURE;
  CompleteLocalesNPCText;
end;

procedure TNPCTextLoc.CompleteLocalesNPCText;
var
  lxentry : string;
begin
  MainForm.mectLog.Clear;
  lxentry:= edlxEntry.Text;
  if lxentry='' then exit;
  MainForm.mectScript.Text := MakeUpdate('locales_npc_text', PFX_LOCALES_NPC_TEXT, 'entry', lxentry);
end;

procedure TNPCTextLoc.edlxentryButtonClick(Sender: TObject);
begin
 LoadLocalesNPCText(TJvComboEdit(Sender).Text);
end;

procedure TNPCTextLoc.EditButtonClick(Sender: TObject);
var
  F: TTextFieldEditorForm;
begin
  F := TTextFieldEditorForm.Create(Self);
  try
    F.Memo.Text := MainForm.DollToSym(TCustomEdit(Sender).Text);
    if F.ShowModal = mrOk then
      TCustomEdit(Sender).Text := MainForm.SymToDoll(F.Memo.Text);
  finally
    F.Free;
  end;
end;

end.
