{$ifdef Interface}

{ Booleans }

type
  TLispBoolean = class(LV)
  end;

function LispBoolean(X: Boolean): TLispBoolean;
function LispIsTrue(X: LV): Boolean;

{ Numbers }

type
  TLispNumber = class(LV)
  end;
  
  TLispFixnum = class(TLispNumber)
  private
    FValue: Integer;
  public
    property Value: Integer read FValue;

    function ToWrite: string; override;
    function Equals(X: LV): Boolean; override;
    constructor Create(AValue: Integer);
  end;

  TLispReal = class(TLispNumber)
  private
    FValue: Real;
  public
    property Value: Real read FValue;

    function ToWrite: string; override;
    function Equals(X: LV): Boolean; override;
    constructor Create(AValue: Real);
  end;

function LispNumber(N: Integer): TLispNumber; overload;
function LispNumber(N: Real): TLispNumber; overload;
function LispToInteger(X: LV): Integer;
function LispToReal(X: LV): Real;

{ Chars and Strings }

type
  TLispChar = class(LV)
  private
    FValue: Char;
  public
    property Value: Char read FValue;

    function ToWrite: string; override;
    function ToDisplay: string; override;
    constructor Create(AValue: Char);    
  end;
  
  TLispString = class(LV)
  private
    FValue: string;
  public
    property Value: string read FValue;

    function Equals(X: LV): Boolean; override;
    function ToWrite: string; override;
    function ToDisplay: string; override;
    constructor Create(AValue: string);
  end;

function LispChar(C: Char): LV;
function LispToChar(X: LV): Char;
function LispString(S: string): LV;
function LispToString(X: LV): string;

{ Symbols }

type
  TLispSymbol = class(LV)
  private
    FId: Integer;
  protected
    function GetName: string; virtual;
  public
    property Name: string read GetName;
    
    function ToWrite: string; override;
    constructor Create(Id: Integer);
  end;
  
  TLispGensym = class(TLispSymbol)
  protected
    function GetName: string; override;
  public
    constructor Create;
  end;
  
function LispSymbol(Name: string): TLispSymbol;
function LispGensym: TLispGensym;
function LispSymbolName(X: LV): string;
  
{ Pairs, Vectors, Hash tables }

type
  TLispPair = class(LV)
  public
    A, D: LV;

    function ToWrite: string; override;
    function ToDisplay: string; override;
    constructor Create(AA, AD: LV);    
  end;
  
  
  {TLispVector = class(LV)
  private
    
  public
    constructor Create(Items: PLVArray; Length: Integer);
  end;}


function LispCons(A, D: LV): TLispPair;
function LispList(Items: array of LV): TLispPair;
function LispCar(X: LV): LV;
function LispCdr(X: LV): LV;
function LispLength(X: LV): Integer;
function LispRef(X: LV; Index: Integer): LV;
function LispAssoc(Needle, Haystack: LV): LV;
function LispAppend(L1, L2: LV): LV;

{ Ports -- IO }

type
  TLispPortState = (lpsStart, lpsMiddle, lpsEnd);
  TLispPortType = (lptAny, lptInput, lptOutput);

  TLispPort = class(LV)
  private
    FStream: TStream;
    FState: TLispPortState;
    FType: TLispPortType;
    FCache: Char;
    
    procedure SanityCheck(DesiredType: TLispPortType);
  public
    property Stream: TStream read FStream;

    function PeekChar: Char; 
    procedure NextChar; 
    function EOF: Boolean;
    procedure WriteChar(C: Char);
    procedure Close;
    function ToWrite: string; override;
    constructor Create(AStream: TStream; AType: TLispPortType);
  end;

function LispPortAsStream(X: LV): TStream;

{ Constructors }
function LispInputStream(S: TStream): LV;
function LispOutputStream(S: TStream): LV;
function LispInputFile(Path: string): LV;
function LispOutputFile(Path: string): LV;
function LispInputString(S: string): LV;

{ Input }
function LispReadChar(Port: LV): Char;
function LispPeekChar(Port: LV): Char;
procedure LispNextChar(Port: LV);
function LispEOF(Port: LV): Boolean;

{ Output }
procedure LispWriteChar(C: Char; Port: LV);
procedure LispWriteString(S: string; Port: LV);
procedure LispClosePort(Port: LV);
  
{ Bottom Values }

var
  LispEmpty, LispVoid, LispEOFObject: LV;
  LispTrue, LispFalse: TLispBoolean;

{ String representations }

function LispDataToString(X: LV; Display: Boolean): string;
function LispToWrite(X: LV): string;
function LispToDisplay(X: LV): string;

{$else}

function LispDataToString(X: LV; Display: Boolean): string;
begin
  if X = LispEmpty then
  begin
    Result := '()';
  end
  else if X = LispVoid then
  begin
    Result := '#v';
  end
  else if X = LispTrue then
  begin
    Result := '#t';
  end
  else if X = LispFalse then
  begin
    Result := '#f';
  end
  else if X = LispEOFObject then
  begin
    Result := '#eof-object'
  end
  else if Display then
  begin
    Result := X.ToDisplay;
  end
  else
  begin
    Result := X.ToWrite;
  end;
end;

function LispToWrite(X: LV): string;
begin
  Result := LispDataToString(X, False);
end;

function LispToDisplay(X: LV): string;
begin
  Result := LispDataToString(X, True);
end;

{ Booleans }

function LispBoolean(X: Boolean): TLispBoolean;
begin
  if X then
  begin
    Result := LispTrue;
  end
  else
  begin
    Result := LispFalse;
  end;
end;

function LispIsTrue(X: LV): Boolean;
begin
  Result := X <> LispFalse;
end;

{ TLispFixnum }

function TLispFixnum.ToWrite: string; 
begin
  Result := IntToStr(Value);
end;

function TLispFixnum.Equals(X: LV): Boolean;
begin
  Result := (X is TLispFixnum) and (TLispFixnum(X).Value = Value);
end;

constructor TLispFixnum.Create(AValue: Integer);
begin
  FValue := AValue;
end;

function LispNumber(N: Integer): TLispNumber;
begin
  Result := TLispFixnum.Create(N);
end;

function LispToInteger(X: LV): Integer;
begin
  LispTypeCheck(X, TLispFixnum, 'not a fixnum');
  Result := TLispFixnum(X).Value;
end;

{ TLispReal }

function TLispReal.ToWrite: string; 
begin
  Result := FloatToStr(Value);
end;

function TLispReal.Equals(X: LV): Boolean;
begin
  Result := (X is TLispReal) and (TLispReal(X).Value = Value);
end;

constructor TLispReal.Create(AValue: Real);
begin
  FValue := AValue;
end;

function LispNumber(N: Real): TLispNumber;
begin
  Result := TLispReal.Create(N);
end;

function LispToReal(X: LV): Real;
begin
  if X is TLispFixnum then
  begin
    Result := LispToInteger(X);
  end
  else
  begin
    LispTypeCheck(X, TLispReal, 'not a real');
    Result := TLispReal(X).Value;
  end;
end;

{ TLispChar }

function TLispChar.ToWrite: string; 
begin
  Result := '#\' + Value;
end;

function TLispChar.ToDisplay: string; 
begin
  Result := Value;
end;

constructor TLispChar.Create(AValue: Char);
begin
  FValue := AValue;
end;

var 
  LispChars: array[Char] of LV;

function LispChar(C: Char): LV;
begin
  Result := LispChars[C];
end;

procedure InitChars;
var
  I: Char;
begin
  for I := #0 to #255 do
  begin
    LispChars[I] := TLispChar.Create(I);
  end;
end;

function LispToChar(X: LV): Char;
begin
  LispTypeCheck(X, TLispChar, 'not a char');
  Result := TLispChar(X).Value;
end;

{ TLispString }

function TLispString.Equals(X: LV): Boolean;
begin
  Result := (X is TLispString) and (TLispString(X).Value = Value);
end;
  
function TLispString.ToWrite: string; 
begin
  Result := '"' + Value + '"';
end;

function TLispString.ToDisplay: string; 
begin
  Result := Value;
end;

constructor TLispString.Create(AValue: string);
begin
  FValue := AValue;
end;

function LispString(S: string): LV;
begin
  Result := TLispString.Create(S);
end;

function LispToString(X: LV): string;
begin
  if X is TLispChar then
  begin
    Result := TLispChar(X).Value;
  end
  else
  begin
    LispTypeCheck(X, TLispString, 'not a string');
    Result := TLispString(X).Value;
  end;
end;

{ TLispSymbol }

var
  SymList: TStrings;
  
function TLispSymbol.GetName: string;
begin
  Result := SymList.Strings[FId];
end;

function TLispSymbol.ToWrite: string;
begin
  Result := Name;
end;

constructor TLispSymbol.Create(Id: Integer);
begin
  FId := Id;
end;

function LispSymbol(Name: string): TLispSymbol;
var
  Id: Integer;
begin
  if Name = '' then
  begin
    raise ELispError.Create('Symbols must have names', nil);
  end;
  Id := SymList.IndexOf(Name);
  if Id = -1 then
  begin
    Id := SymList.Add(Name);
    SymList.Objects[Id] := TLispSymbol.Create(Id);
  end;
  Result := TLispSymbol(SymList.Objects[Id]);
end;

function LispSymbolName(X: LV): string;
begin
  LispTypeCheck(X, TLispSymbol, 'not a symbol');
  Result := TLispSymbol(X).Name;
end;

{ TLispGensym }

function TLispGensym.GetName: string; 
begin
  Result := '#<gensym ' + IntToHex(PtrInt(Self), 2 * SizeOf(TLispGensym)) + '>';
end;

constructor TLispGensym.Create;
begin
end;

function LispGensym: TLispGensym;
begin
  Result := TLispGensym.Create;
end;

{ TLispPair }

function PairToString(P: TLispPair; Display: Boolean): string;
var
  Cur: TLispPair;
  Done: Boolean;
begin
  Cur := P;
  Done := False;
  Result := '(';
  repeat
    Result := Result + LispDataToString(Cur.A, Display); 
    if Cur.D is TLispPair then
    begin
      Result := Result + ' ';
      Cur := TLispPair(Cur.D);
    end
    else if Cur.D = LispEmpty then
    begin
      Result := Result + ')';
      Done := True;
    end
    else
    begin
      Result := Result + ' . ' + LispDataToString(Cur.D, Display) + ')';
      Done := True;
    end;
  until Done;
end;

function TLispPair.ToWrite: string; 
begin
  Result := PairToString(Self, False);
end;

function TLispPair.ToDisplay: string; 
begin
  Result := PairToString(Self, True);
end;

constructor TLispPair.Create(AA, AD: LV);    
begin
  A := AA;
  D := AD;
end;

function LispCons(A, D: LV): TLispPair;
begin
  Result := TLispPair.Create(A, D);
end;

function LispList(Items: array of LV): TLispPair;
var
  I, L: Integer;
  Cur, Next: TLispPair;
begin
  L := Length(Items);
  if L = 0 then
  begin
    raise ELispError.Create('LispList: no empty lists!', nil);
  end;
  Next := LispCons(Items[0], LispEmpty);
  Cur := Next;
  Result := Cur;
  for I := 1 to Length(Items) - 1 do
  begin
    Next := LispCons(Items[I], LispEmpty);
    Cur.D := Next;
    Cur := Next;
  end;
end;

function LispCar(X: LV): LV;
begin
  LispTypeCheck(X, TLispPair, 'not a pair');

  Result := TLispPair(X).A;
end;

function LispCdr(X: LV): LV;
begin
  LispTypeCheck(X, TLispPair, 'not a pair');

  Result := TLispPair(X).D;
end;

function LispLength(X: LV): Integer;
var
  Cur: LV;
begin
  Result := 0;
  Cur := X;
  while Cur <> LispEmpty do
  begin
    Inc(Result);
    Cur := LispCdr(Cur);
  end;
end;

function LispRef(X: LV; Index: Integer): LV;
begin
  if Index = 0 then
  begin
    Result := LispCar(X);
  end
  else
  begin
    Result := LispRef(LispCdr(X), Index - 1);
  end;
end;

function LispAssoc(Needle, Haystack: LV): LV;
var
  Association: LV;
begin
  while Haystack <> LispEmpty do
  begin
    Association := LispCar(Haystack);
       
    if Needle.Equals((LispCar(Association))) then
    begin
      Result := Association;
      exit;
    end;

    Haystack := LispCdr(Haystack);
  end;
  Result := LispFalse;
end;

function LispAppend(L1, L2: LV): LV;
begin
  if L1 = LispEmpty then
  begin
    Result := L2;
  end
  else
  begin
    Result := TLispPair.Create(LispCar(L1), LispAppend(LispCdr(L1), L2));
  end;
end;

{ TLispPort }

function PortTypeToString(T: TLispPortType): string;
begin
  if T = lptInput then
  begin
    Result := 'input';
  end
  else
  begin
    Result := 'output';
  end;
end;

procedure TLispPort.SanityCheck(DesiredType: TLispPortType);
begin
  if FStream = nil then
  begin
    raise ELispError.Create('port closed', Self);
  end;
  if (DesiredType <> lptAny) and (FType <> DesiredType) then
  begin
    raise ELispError.Create('not an ' + PortTypeToString(DesiredType) + ' port.', Self);
  end;
end;

function TLispPort.PeekChar: Char;
begin
  SanityCheck(lptInput);

  if FState = lpsStart then
  begin
    NextChar;
  end;

  Result := FCache;
end;

procedure TLispPort.NextChar;
var
  Count: Integer;
begin
  SanityCheck(lptInput);

  if FState = lpsStart then
  begin
    FState := lpsMiddle;
  end;

  Count := FStream.Read(FCache, 1);

  if Count = 0 then
  begin
    FState := lpsEnd;
  end;
end;

function TLispPort.EOF: Boolean;
begin
  SanityCheck(lptInput);

  Result := FState = lpsEnd;
end;

procedure TLispPort.WriteChar(C: Char);
begin
  SanityCheck(lptOutput);
  FStream.Write(C, 1);
end;

procedure LispWriteString(S: string; Port: LV);
var
  I: Integer;
begin
  for I := 1 to Length(S) do
  begin
    LispWriteChar(S[I], Port);
  end;
end;

procedure TLispPort.Close;
begin
  SanityCheck(lptAny);
  FreeAndNil(FStream);
end;

function TLispPort.ToWrite: string; 
begin
  Result := '#<port>';
end;

constructor TLispPort.Create(AStream: TStream; AType: TLispPortType);
begin
  FStream := AStream;
  FState := lpsStart;
  FType := AType;
end;

function LispPortAsStream(X: LV): TStream;
begin
  LispTypeCheck(X, TLispPort, 'not a port');
  Result := TLispPort(X).Stream;
end;

function LispInputStream(S: TStream): LV;
begin
  Result := TLispPort.Create(S, lptInput);
end;

function LispOutputStream(S: TStream): LV;
begin
  Result := TLispPort.Create(S, lptOutput);
end;

function LispInputFile(Path: string): LV;
begin
  Result := LispInputStream(TFileStream.Create(Path, fmOpenRead));
end;

function LispOutputFile(Path: string): LV;
begin
  if FileExists(Path) then
  begin
    Result := LispOutputStream(TFileStream.Create(Path, fmOpenWrite));
  end
  else
  begin
    Result := LispOutputStream(TFileStream.Create(Path, fmCreate));
  end;
end;

function LispInputString(S: string): LV;
begin
  Result := LispInputStream(TStringStream.Create(S));
end;

function LispReadChar(Port: LV): Char;
begin
  Result := LispPeekChar(Port);
  LispNextChar(Port);
end;

function GetPort(Port: LV): TLispPort;
begin
  LispTypeCheck(Port, TLispPort, 'not a port');
  Result := TLispPort(Port);
end;

function LispPeekChar(Port: LV): Char;
begin
  Result := GetPort(Port).PeekChar;
end;

procedure LispNextChar(Port: LV);
begin
  GetPort(Port).NextChar;
end;

function LispEOF(Port: LV): Boolean;
begin
  Result := GetPort(Port).EOF;
end;

procedure LispWriteChar(C: Char; Port: LV);
begin
  GetPort(Port).WriteChar(C);
end;

procedure LispClosePort(Port: LV);
begin
  GetPort(Port).Close;
end;

procedure InitTypes;
begin
  { Bottom values }
  LispEmpty := LV.Create;
  LispVoid := LV.Create;
  LispEOFObject := LV.Create;
  LispTrue := TLispBoolean.Create;
  LispFalse := TLispBoolean.Create;
  { Symbols }
  SymList := TStringList.Create;
  { Characters }
  InitChars;
end;

{$endif}
