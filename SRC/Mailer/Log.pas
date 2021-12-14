unit Log;

interface
uses SyncObjs, Windows, Dialogs, SysUtils, Forms;
type
  TLog = class (TObject)
    hFile : THandle;
//   Overlapped : TOverlapped;
    I : integer;
    bContentPrinted : boolean;
    dw : DWORD;
    public
    constructor Create;overload;
    constructor Create(fileName:string); overload;
    destructor Free;
    function DoCreateMutex(AName: string): Cardinal;
    procedure Write(strText:string; flIsFirst:boolean=false);
  end;
var
 //  MySection:TCriticalSection;
 Mutex: THandle;
implementation

constructor TLog.Create;
begin
  hFile:= CreateFile(PChar(ExtractFilePath(Application.ExeName)+
'Log.txt') , // pointer to name of the file
GENERIC_READ or GENERIC_WRITE , // access (read-write) mode
FILE_SHARE_WRITE or FILE_SHARE_READ , // share mode
nil, // pointer to security attributes
OPEN_ALWAYS , // how to create
{FILE_FLAG_OVERLAPPED, //}FILE_ATTRIBUTE_NORMAL, // file attributes
0 // handle to file with attributes to copy
);

if hFile =  INVALID_HANDLE_VALUE  then ShowMessage('Ошибка создания лога');

 //MySection:= TCriticalSection.Create;
  //Mutex := CreateMutex(NIL, FALSE, 'TabelMutex');
    Mutex := DoCreateMutex('TabelMutex');
if Mutex = 0 then
    RaiseLastWin32Error;

end;

constructor TLog.Create(fileName:string);
begin
  hFile:= CreateFile(
PChar(fileName), // pointer to name of the file
GENERIC_READ or GENERIC_WRITE , // access (read-write) mode
FILE_SHARE_WRITE or FILE_SHARE_READ , // share mode
nil, // pointer to security attributes
OPEN_ALWAYS , // how to create
{FILE_FLAG_OVERLAPPED, //}FILE_ATTRIBUTE_NORMAL, // file attributes
0 // handle to file with attributes to copy
);

if hFile =  INVALID_HANDLE_VALUE  then ShowMessage('Ошибка создания лога');

 //MySection:= TCriticalSection.Create;
  //Mutex := CreateMutex(NIL, FALSE, 'TabelMutex');
    Mutex := DoCreateMutex('Mailer');
if Mutex = 0 then
    RaiseLastWin32Error;

end;

destructor TLog.Free;
begin
//  Write('------------------ END SESSION ------------------') ;
   if hFile <> INVALID_HANDLE_VALUE then
      CloseHandle(hFile);
      CloseHandle(Mutex);

//   if Overlapped.hEvent <> 0 then
//        CloseHandle(Overlapped.hEvent);
  //      MySection.Free;
//   inherited Free;
end;

procedure TLog.Write(strText: string; flIsFirst:boolean=false);
var
strToWrite, strTmp: string;
begin
  strTmp:= #13#10;//+#13;
  strToWrite:= DateTimeToStr(Now) + ' --> ' +  strText + #13#10;
// if MySection.TryEnter then //.Acquire;
 //begin
 if WaitForSingleObject(Mutex, INFINITE) = WAIT_OBJECT_0 then
try
    SetFilePointer (hFile, 0, nil, FILE_END);
    if flIsFirst then
    begin
      WriteFile(hFile, strTmp[1], length(strTmp)*2, dw, nil{@Overlapped});
      SetEndOfFile(hFile);
      SetFilePointer (hFile, 0, nil, FILE_END);
    end;

    WriteFile(hFile, strToWrite[1], length(strToWrite)*2, dw, nil{@Overlapped});
    SetEndOfFile(hFile);
    SetFilePointer (hFile, 0, nil, FILE_END);
//    MySection.Leave; //.Release;
 //end;
finally
 ReleaseMutex(Mutex);
end else
 RaiseLastOsError();
end;

function TLog.DoCreateMutex(AName: string): Cardinal;
var
 SD:TSecurityDescriptor;
 SA:TSecurityAttributes;
 pSA: PSecurityAttributes;
begin
 if not InitializeSecurityDescriptor(@SD, SECURITY_DESCRIPTOR_REVISION) then
   raise Exception.CreateFmt('Error InitializeSecurityDescriptor: %s', [SysErrorMessage(GetLastError)]);

 SA.nLength:=SizeOf(TSecurityAttributes);
 SA.lpSecurityDescriptor:=@SD;
 SA.bInheritHandle:=False;

 if not SetSecurityDescriptorDacl(SA.lpSecurityDescriptor, True, nil, False) then
   raise Exception.CreateFmt('Error SetSecurityDescriptorDacl: %s', [SysErrorMessage(GetLastError)]);

 pSA := @SA;

 Result := CreateMutex(pSA, False, PChar(AName));

 if Result = 0 then
   raise Exception.CreateFmt('Error CreateMutex: %s', [SysErrorMessage(GetLastError)]);
end;
end.
