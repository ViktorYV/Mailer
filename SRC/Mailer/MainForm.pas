unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, ShellApi,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.CheckLst, SettingsFrm, StartForm,
  Vcl.Menus, Vcl.Buttons, Vcl.Imaging.pngimage, Log, RegularExpressions,
  IniFiles,
  Vcl.ComCtrls;

const
  DOGCHAR = '@';

type
  TMainFms = class(TForm)
    Panel1: TPanel;
    Splitter1: TSplitter;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    clbMails: TCheckListBox;
    Label1: TLabel;
    edFilePath: TEdit;
    MainMenu1: TMainMenu;
    mSettings: TMenuItem;
    imgOpenFile: TImage;
    sbtnFind: TSpeedButton;
    sbtnSelAll: TSpeedButton;
    sbtnDeselect: TSpeedButton;
    sbtnInvert: TSpeedButton;
    PageControl1: TPageControl;
    tshInput: TTabSheet;
    tshResult: TTabSheet;
    Memo1: TMemo;
    Panel6: TPanel;
    Splitter3: TSplitter;
    sbtnSend: TSpeedButton;
    sbtnSave: TSpeedButton;
    GroupBox1: TGroupBox;
    chbFilter: TCheckBox;
    cbDomains: TComboBox;
    procedure mSettingsClick(Sender: TObject);
    procedure sbtnOpenFileClick(Sender: TObject);
    procedure imgOpenFileClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Memo1MouseEnter(Sender: TObject);
    procedure sbtnFindClick(Sender: TObject);
    procedure PageControl1Change(Sender: TObject);
    procedure clbMailsClickCheck(Sender: TObject);
    procedure sbtnSelAllClick(Sender: TObject);
    procedure sbtnDeselectClick(Sender: TObject);
    procedure sbtnInvertClick(Sender: TObject);
    procedure sbtnSendClick(Sender: TObject);
    procedure sbtnSaveClick(Sender: TObject);
    procedure chbFilterClick(Sender: TObject);
    procedure cbDomainsChange(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    { Private declarations }
    myLog: TLog;
    _FilePath: string;
    _Login: string;
    _Pass: string;
    _Subj: string;
    _Body: string;
    strlMails: TStringList;
    // function RegExpFind(strLogPath, strFirs, strMask: string;
    // var strl: TStringList): integer;
    procedure SetMailButtons;
    procedure SendMail(strTo, strSubj, strBody: string);
    procedure FilterMails(strDomain: string; flFill: boolean = false);
  public
    { Public declarations }
    property Login: string read _Login write _Login;
    property Pass: string read _Pass write _Pass;
    property Subj: string read _Subj write _Subj;
    property Body: string read _Body write _Body;
    property FilePath: string read _FilePath write _FilePath;
  end;

var
  MainFms: TMainFms;

implementation

{$R *.dfm}

function CheckAllowed(const s: string; IsDomain: boolean = false): boolean;
var
  i: integer;
  flag: boolean;
begin
  Result := false;
  flag := false;

  for i := 1 to Length(s) do
  begin
    if not(s[i] in ['a' .. 'z', 'A' .. 'Z', '0' .. '9', '_', '-', '.']) then
    begin
      Exit;
    end;

    if s[i] in ['_', '-', '.'] then
    begin
      if ((i = 1) or (i = Length(s))) then
      begin
        flag := true;
      end;

      if not flag then
      begin
        flag := true;
      end
      else
      begin
        Exit;
      end;
    end
    else
    begin
      flag := false
    end;
  end;

  if IsDomain then
  begin
    for i := LastDelimiter('.', s) to Length(s) do
      if not(s[i] in ['a' .. 'z', 'A' .. 'Z']) then
      begin
        Exit;
      end;
  end;

  Result := true;
end;

function IsValidEmail(const Value: string): boolean;
var
  i: integer;
  namePart, serverPart: string;
begin
  Result := false;
  i := Pos('@', Value);
  if (i < 2) or (i > (Length(Value) - 4)) then
  begin
    Exit;
  end;

  namePart := Copy(Value, 1, i - 1);
  serverPart := Copy(Value, i + 1, Length(Value));

  // if (Length(namePart) = 0) or ((Length(serverPart) < 4)) then
  // begin
  // Exit;
  // end;

  i := Pos('.', serverPart);

  if (i = 0) or (LastDelimiter('.', serverPart) > (Length(serverPart) - 2)) then
  // (i > (Length(serverPart) - 2)) then
  begin
    Exit;
  end;
  Result := CheckAllowed(namePart) and CheckAllowed(serverPart);
end;

function GetMails(var words: TStringList; strLine: string): boolean;
var
  i, col: integer;
  tmpWords: TStringList;
begin
  Result := false;
  i := Pos('@', strLine);

  if (i = 0) or (i > Length(strLine) - 4) then
  begin
    Exit;
  end;

  tmpWords := TStringList.Create;
  tmpWords.Delimiter := ' ';;
  tmpWords.StrictDelimiter := true;
  strLine := trim(strLine);
  tmpWords.DelimitedText := strLine;
  col := tmpWords.Count;

  if words = nil then
  begin
    words := TStringList.Create();
  end;

  words.Sorted := true;
  words.Duplicates := dupIgnore;

  for i := 0 to col - 1 do
  begin
    if IsValidEmail(tmpWords[i]) then
    begin
      words.Add(tmpWords[i]);
    end;
  end;
  tmpWords.Clear;
  tmpWords.Destroy;

  Result := words.Count > 0;
end;

procedure TMainFms.SendMail(strTo, strSubj, strBody: string);
var
  StrMsg: string;
  i: integer;
begin
  myLog.Write('SendMail to ' + strTo);
  // установить основную информацию
  StrMsg := 'mailto:' + strTo + '?Subject=' + strSubj + '&Body=' + strBody;
  // + #13#10 + strBody;

  // отправить сообщение
  ShellExecute(Handle, 'open', pChar(StrMsg), '', '', SW_SHOW);
end;

procedure TMainFms.cbDomainsChange(Sender: TObject);
begin
  FilterMails(cbDomains.Text);
end;

procedure TMainFms.chbFilterClick(Sender: TObject);
begin
  cbDomains.Enabled := chbFilter.Checked;
  FilterMails(cbDomains.Text, not chbFilter.Checked);

end;

procedure TMainFms.clbMailsClickCheck(Sender: TObject);
begin
  SetMailButtons;
end;

procedure TMainFms.FormActivate(Sender: TObject);
var
  StartFrm: TStartFrm;
begin
  StartFrm := TStartFrm.Create(self);
  self.WindowState := wsMinimized;
  if StartFrm.ShowModal = mrCancel then
  begin
    Application.Terminate;
  end;
  self.WindowState := wsNormal; // Разворачиваем
  Login := StartFrm.User;
  Pass := StartFrm.Pass;
  FilePath := StartFrm.FilePath;
  Subj := StartFrm.Subj;
  Body := StartFrm.Body;
end;

procedure TMainFms.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  myLog.Write('======= Stop =======');
end;

procedure TMainFms.FormCreate(Sender: TObject);
begin
  strlMails := nil;
  myLog := TLog.Create;
  myLog.Write('====== Start =======', true);

  PageControl1.ActivePageIndex := 0;
end;

procedure TMainFms.imgOpenFileClick(Sender: TObject);
var
  OpenFileDlg: TOpenDialog;
  F: TextFile;
  s: string;
begin
  OpenFileDlg := TOpenDialog.Create(nil);
  // OpenFileDlg.Filter := 'Текстовые файлы|*.txt; *.doc|Все файлы|*.*';
  OpenFileDlg.Filter := 'Текстовые файлы|*.txt|Все файлы|*.*';
  if OpenFileDlg.Execute then
  begin
    Memo1.Clear;
    edFilePath.Text := OpenFileDlg.FileName;
    myLog.Write('Open file ' + edFilePath.Text);

    try
      AssignFile(F, OpenFileDlg.FileName, CP_UTF8);
      // AssignFile(F, OpenFileDlg.FileName);
      FileMode := fmOpenRead;
      reset(F);

      while not Eof(F) do
      begin
        Readln(F, s);
        Memo1.Lines.Add(s);
      end;
      CloseFile(F);
    except
      on E: Exception do
      begin
        myLog.Write('!!!Error : ' + E.Message);
        ShowMessage('Ошибка!!! ' + E.Message);
      end;
    end;
  end;

end;

procedure TMainFms.Memo1MouseEnter(Sender: TObject);
begin
  // BalloonHint1.Title := 'Hint Title';
  // BalloonHint1.Description := Memo1.Hint;
  // balloonhint1.ShowHint(Memo1.ClientToScreen(TPoint.Create(X,Y)));
end;

procedure TMainFms.mSettingsClick(Sender: TObject);
Var
  SettingsFrm: TSetFrm;
  templ: RTempl;
begin
  myLog.Write('Settings menu ');
  SettingsFrm := TSetFrm.Create(self);
  SettingsFrm.Login := Login;
  SettingsFrm.Pass := Pass;
  SettingsFrm.Subj := Subj;
  SettingsFrm.Body := Body;
  SettingsFrm.FileName := FilePath;
  if SettingsFrm.ShowModal = mrOk then
  begin
    Login := SettingsFrm.Login;
    Pass := SettingsFrm.Pass;
    FilePath := StartFrm.FilePath;
    Subj := SettingsFrm.Subj;
    Body := SettingsFrm.Body;
  end;
end;

procedure TMainFms.SetMailButtons;
var
  i: integer;
  flAll: boolean;
begin
  sbtnSelAll.Enabled := false;
  sbtnDeselect.Enabled := false;
  sbtnInvert.Enabled := false;
  sbtnSave.Enabled := false;
  if clbMails.Items.Count = 0 then
  begin
    Exit;
  end;

  for i := 0 to clbMails.Items.Count - 1 do
  begin
    if clbMails.Checked[i] then
    begin
      sbtnDeselect.Enabled := true;
    end
    else
    begin
      sbtnSelAll.Enabled := true;
    end;

    if sbtnDeselect.Enabled and sbtnSelAll.Enabled then
    begin
      break;
    end;

  end;

  sbtnInvert.Enabled := sbtnDeselect.Enabled and sbtnSelAll.Enabled;
  sbtnSend.Enabled := sbtnDeselect.Enabled;
  sbtnSave.Enabled := sbtnSend.Enabled;
end;

procedure TMainFms.PageControl1Change(Sender: TObject);
begin
  if PageControl1.ActivePageIndex = 1 then
  begin
    SetMailButtons
  end;

end;

procedure TMainFms.sbtnFindClick(Sender: TObject);
var
  i: integer;
  strlDomains: TStringList;
  strResult: string;
begin
  if (Memo1.Lines.Count = 0) then
  begin
    // ShowMessage('No text found!!!');
    MessageDlg('Отсутствует текст для поиска!' + #13#10 +
      'Откройте файл или вставьте текст из буфера', mtInformation, [mbOK], 0);
    Exit;
  end;
  clbMails.Clear;
  cbDomains.Clear;

  strlDomains := TStringList.Create;
  strlDomains.Sorted := true;
  strlDomains.Duplicates := dupIgnore;

  for i := 0 to Memo1.Lines.Count - 1 do
  begin
    GetMails(strlMails, Memo1.Lines[i]);
  end;

  if strlMails.Count < 1 then
  begin
    ShowMessage('No mails found');
    Exit;
  end;

  for i := 0 to strlMails.Count - 1 do
  begin
    // strResult := strResult + strlMails[i] + #10#13;
    clbMails.Items.Add(strlMails[i]);
    strlDomains.Add(Copy(strlMails[i], Pos('@', strlMails[i]) + 1,
      Length(strlMails[i]) - Pos('@', strlMails[i])));
  end;
  for i := 0 to strlDomains.Count - 1 do
  begin
    cbDomains.Items.Add(strlDomains[i]);
  end;
  if cbDomains.Items.Count > 0 then
  begin
    cbDomains.ItemIndex := 0;
  end;
  PageControl1.ActivePageIndex := 1;
  PageControl1.OnChange(PageControl1);
  strResult := Format('Найдено %d уникальных адресов', [strlMails.Count]);
  myLog.Write(strResult);
  ShowMessage(strResult);
end;

procedure TMainFms.FilterMails(strDomain: string; flFill: boolean = false);
var
  i: integer;
begin
  if ((strlMails = nil) or (strlMails.Count < 1)) then
    Exit;

  clbMails.Clear;
  if flFill then
  begin
    myLog.Write('Reset filter');
  end
  else
  begin
    myLog.Write('Set filter ' + strDomain);
  end;

  for i := 0 to strlMails.Count - 1 do
  begin
    if flFill then
    begin
      clbMails.Items.Add(strlMails[i]);
    end
    else if strlMails[i].EndsWith(strDomain) then
    begin
      clbMails.Items.Add(strlMails[i]);
    end;
  end;
  SetMailButtons;
end;

procedure TMainFms.sbtnOpenFileClick(Sender: TObject);
var
  OpenFileDlg: TOpenDialog;
begin
  OpenFileDlg := TOpenDialog.Create(nil);
  // OpenFileDlg.Filter := 'Текстовые файлы|*.txt; *.doc|Все файлы|*.*';
  OpenFileDlg.Filter := 'Текстовые файлы|*.txt|Все файлы|*.*';
  if OpenFileDlg.Execute then
  begin
    edFilePath.Text := OpenFileDlg.FileName;
  end;

end;

procedure TMainFms.sbtnSaveClick(Sender: TObject);
var
  F: TextFile;
  saveDialog: TSaveDialog;
  i: integer;

begin
  saveDialog := TSaveDialog.Create(self);
  saveDialog.Title := 'Save your text file';
  saveDialog.Filter := 'Текстовые файлы|*.txt|Все файлы|*.*';
  saveDialog.DefaultExt := 'txt';
  if saveDialog.Execute then
  begin
    try
      AssignFile(F, saveDialog.FileName);
      if FileExists(saveDialog.FileName) then
      begin
        Append(F);
      end
      else
      begin
        Rewrite(F);
      end;

      for i := 0 to clbMails.Count - 1 do
      begin
        if clbMails.Checked[i] then
        begin
          Writeln(F, clbMails.Items[i]);
        end;
      end;

      Flush(F);
      CloseFile(F);
      MessageDlg('Сохранено успешно!!!', mtInformation, [mbOK], 0);
    except
      on E: Exception do
      begin
        MessageDlg('Ошибка!!! ' + E.Message, mtError, [mbOK], 0)
      end;

    end;
  end;
end;

procedure TMainFms.sbtnSelAllClick(Sender: TObject);
begin
  clbMails.CheckAll(cbChecked, false, true);
  sbtnDeselect.Enabled := true;
  sbtnSelAll.Enabled := false;
  sbtnSend.Enabled := true;
  sbtnSave.Enabled := sbtnSend.Enabled;
  // SetMailButtons;
end;

procedure TMainFms.sbtnSendClick(Sender: TObject);
var
  i: integer;
begin
  for i := 0 to clbMails.Count - 1 do
  begin
    if clbMails.Checked[i] then
    begin
      SendMail(clbMails.Items[i], Subj, Body);
    end;
  end;

end;

procedure TMainFms.sbtnDeselectClick(Sender: TObject);
begin
  clbMails.CheckAll(cbUnchecked, true, false);
  sbtnDeselect.Enabled := false;
  sbtnSelAll.Enabled := true;
  sbtnSend.Enabled := false;
  sbtnSave.Enabled := sbtnSend.Enabled;
  // sbtnInvert.Enabled := true;
end;

procedure TMainFms.sbtnInvertClick(Sender: TObject);
var
  i: integer;
begin
  for i := 0 to clbMails.Count - 1 do
  begin
    clbMails.Checked[i] := not clbMails.Checked[i];
  end;
  SetMailButtons;
end;

// function TMainFms.RegExpFind(strLogPath, strFirs, strMask: string;
// var strl: TStringList): integer;
// var
// s: string;
// // strMask: string;
// RegEx: TRegEx;
// flFirst: boolean;
// F: TextFile;
// position, npos: integer;
// begin
//
// try
// try
// AssignFile(F, strLogPath);
// FileMode := fmOpenRead or fmShareDenyNone;
// reset(F);
// except
// on E: Exception do
// begin
// if myLog = nil then
// begin
// myLog := TLog.Create;
// end;
// myLog.Write(E.Message, true);
// flFirst := false;
// Result := -1;
// end;
// end;
// position := 0;
//
// RegEx := TRegEx.Create(strMask);
//
// flFirst := strFirs = '';
//
// if strl = nil then
// begin
// strl := TStringList.Create;
// end
// else
// begin
// strl.Clear;
// end;
//
// while not Eof(F) do
// begin
// Readln(F, s);
// position := position + sizeof(s);
//
// if not flFirst then
// begin
// flFirst := (Pos(strFirs, s) > 0);
// continue;
// end;
//
// if Pos(DOGCHAR, s) > 0 then
// begin
// if (RegEx.IsMatch(s)) then
// begin
// npos := Pos(#9, s) + 1;
// strl.Add(Copy(s, npos, Length(s) - npos));
//
// // if _strDateTime = '' then
// // begin
// // _strDateTime := GetDateTime(strl[strl.Count - 1]);
// // end;
// end;
//
// end;
// end;
// // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// finally
// // if isFileOpen() then
// // begin
// // CloseFile(F);
// // FileMode := 2;
// // end;
// end;
// //
// // if not flFirst then
// // begin
// // RegExpFind(strLogPath, '', strMask, strl);
// // end;
// if flFirst then
// begin
// Result := strl.Count;
// end
// else
// begin
// Result := -1;
// end;
// end;

end.
