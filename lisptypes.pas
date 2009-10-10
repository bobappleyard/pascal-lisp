unit LispTypes;

interface

uses
  SysUtils, Classes;

type

{ Base Types }

  LV = class
  public
    function ToWrite: string; virtual;
    function ToDisplay: string; virtual;
    function Equals(X: LV): Boolean; virtual;
  end;

  TLispType = class of LV;
  PLV = ^LV;

  ELispError = class(Exception)
  public
    constructor Create(Msg: string; What: LV);
  end;

{ Data }
  
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

  TLispSymbol = class(LV)
  private
    FId: Integer;
  public
    function ToWrite: string; override;
    constructor Create(Id: Integer);
  end;
  
  TLispPair = class(LV)
  public
    A, D: LV;

    function ToWrite: string; override;
    function ToDisplay: string; override;
    constructor Create(AA, AD: LV);    
  end;

  TLispPortState = (lpsStart, lpsMiddle, lpsEnd);

  TLispPort = class(LV)
  private
    FStream: TStream;
    FState: TLispPortState;
    FCache: Char;
    procedure SanityCheck;
  public
    property Stream: TStream read FStream;

    function PeekChar: Char;
    procedure NextChar;
    function EOF: Boolean;
    procedure WriteChar(C: Char);
    procedure Close;
    function ToWrite: string; override;
    constructor Create(AStream: TStream);
  end;
  
{ Code }

  TLispProcedure = class(LV)
  protected
    FName: string;
  public
    function WithName(AName: string): LV; virtual;
    property Name: string read FName;
  end;
  
  TLispPrimitiveFunc = function(Args: LV): LV;
  TLispPrimitiveMethod = function(Args: LV): LV of object;
  
  TLispPrimitive = class(TLispProcedure)
  private
    FImpl: TLispPrimitiveFunc;
  public
    function ToWrite: string; override;
    function WithName(AName: string): LV; override;
    function Exec(Args: LV): LV; virtual;
    constructor Create(AImpl: TLispPrimitiveFunc); overload;
    constructor Create(AName: string; AImpl: TLispPrimitiveFunc); overload;
  end;

  TLispObjectPrimitive = class(TLispPrimitive)
  private
    FImpl: TLispPrimitiveMethod;
  public
    function WithName(AName: string): LV; override;
    function Exec(Args: LV): LV; override;
    constructor Create(AImpl: TLispPrimitiveMethod); overload;
    constructor Create(AName: string; AImpl: TLispPrimitiveMethod); overload;
  end;
  
  TLispClosure = class(TLispProcedure)
  private
    FCode, FArgs, FEnv: LV;
  public
    property Code: LV read FCode;
    property Args: LV read FArgs;
    property Env: LV read FEnv;

    function ToWrite: string; override;
    function WithName(AName: string): LV; override;
    constructor Create(AName: string; AArgs, ACode, AEnv: LV);
  end;

{ Multiple Values }

  TLispMultipleValues = class(LV)
  private
    FFirst, FRest: LV;
  public
    property First: LV read FFirst;
    property Rest: LV read FRest;

    function ToWrite: string; override;
    function ToDisplay: string; override;
    constructor Create(AFirst, ARest: LV);
  end;

var
  LispEmpty, LispVoid, LispTrue, LispFalse, LispEOFObject: LV;

{ Constructors }

function LispSymbol(Name: string): LV;
function BooleanToLisp(X: Boolean): LV;
function LispChar(C: Char): LV;
  
{ List functions }

function LispCar(X: LV): LV;
function LispCdr(X: LV): LV;
function LispLength(X: LV): Integer;
function LispRef(X: LV; Index: Integer): LV;
function LispAppend(L1, L2: LV): LV;

{ Port Routines }

function LispReadChar(Port: LV): Char;
function LispPeekChar(Port: LV): Char;
procedure LispNextChar(Port: LV);
function LispEOF(Port: LV): Boolean;

procedure LispWriteChar(C: Char; Port: LV);
procedure LispWriteString(S: string; Port: LV);
procedure LispClosePort(Port: LV);

{ Misc Routines }


function LispToWrite(X: LV): string;
function LispToDisplay(X: LV): string;
procedure LispTypeCheck(X: LV; Expected: TLispType; Msg: string);
procedure LispParseArgs(Src: LV; Args: array of PLV; Variadic: Boolean = False);

implementation

function LispToString(X: LV; Display: Boolean): string;
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
  Result := LispToString(X, False);
end;

function LispToDisplay(X: LV): string;
begin
  Result := LispToString(X, True);
end;

procedure LispTypeCheck(X: LV; Expected: TLispType; Msg: string);
begin
  if not (X is Expected) then
  begin
    raise ELispError.Create(Msg, X);
  end;
end;

function BooleanToLisp(X: Boolean): LV;
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

procedure LispParseArgs(Src: LV; Args: array of PLV; Variadic: Boolean = False);
var
  I, C: Integer;
  Cur: LV;
begin
  Cur := Src;

  if Variadic then
  begin
    C := Length(Args) - 1;
  end
  else
  begin
    C := Length(Args);
  end;

  for I := 0 to C - 1  do
  begin
    if Cur = LispEmpty then
    begin
      raise ELispError.Create('Not enough arguments', nil);
    end;
    Args[I]^ := LispCar(Cur);
    Cur := LispCdr(Cur);
  end;

  if Variadic then
  begin
    Args[C]^ := Cur;
  end
  else if Cur <> LispEmpty then
  begin
    raise ELispError.Create('Too many arguments', nil);
  end;
end;

{ LV }

function LV.ToWrite: string;
begin
  Result := '';
end;

function LV.ToDisplay: string;
begin
  Result := ToWrite;
end;

function LV.Equals(X: LV): Boolean;
begin
  Result := X = Self;
end;

{ ELispError }

constructor ELispError.Create(Msg: string; What: LV);
begin
  if What = nil then
  begin
    inherited Create(Msg);
  end
  else
  begin
    inherited Create(Msg + ': ' + LispToWrite(What));
  end;
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

{ TLispSymbol }

var
  SymList: TStrings;
  Gensyms: Integer;

function TLispSymbol.ToWrite: string;
begin
  if FId < 0 then
  begin
    Result := '#<gensym ' + IntToStr(-FId) + '>';
  end
  else
  begin
    Result := SymList.Strings[FId];
  end;
end;

constructor TLispSymbol.Create(Id: Integer);
begin
  FId := Id;
end;

function LispSymbol(Name: string): LV;
var
  Id: Integer;
begin
  if Name = '' then
  begin
    Inc(Gensyms);
    Id := -Gensyms;
    Result := TLispSymbol.Create(Id);
  end
  else
  begin
    Id := SymList.IndexOf(Name);
    if Id = -1 then
    begin
      Id := SymList.Add(Name);
      SymList.Objects[Id] := TLispSymbol.Create(Id);
    end;
    Result := LV(SymList.Objects[Id]);
  end;
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
    Result := Result + LispToString(Cur.A, Display); 
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
      Result := Result + ' . ' + LispToString(Cur.D, Display) + ')';
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

function LispCar(X: LV): LV;
begin
  LispTypeCheck(X, TLispPair, 'Not a pair');

  Result := TLispPair(X).A;
end;

function LispCdr(X: LV): LV;
begin
  LispTypeCheck(X, TLispPair, 'Not a pair');

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

procedure TLispPort.SanityCheck;
begin
  if FStream = nil then
  begin
    raise ELispError.Create('Port closed', Self);
  end;
end;

function TLispPort.PeekChar: Char;
begin
  SanityCheck;

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
  SanityCheck;

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
  SanityCheck;

  Result := FState = lpsEnd;
end;

procedure TLispPort.WriteChar(C: Char);
begin
  SanityCheck;

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
  SanityCheck;

  FreeAndNil(FStream);
end;

function TLispPort.ToWrite: string; 
begin
  Result := '#<port>';
end;

constructor TLispPort.Create(AStream: TStream);
begin
  FStream := AStream;
  FState := lpsStart;
end;

function LispReadChar(Port: LV): Char;
begin
  Result := LispPeekChar(Port);
  LispNextChar(Port);
end;

function LispPeekChar(Port: LV): Char;
var
  P: TLispPort;
begin
  LispTypeCheck(Port, TLispPort, 'Not a port');
  P := TLispPort(Port);
  Result := P.PeekChar;
end;

procedure LispNextChar(Port: LV);
var
  P: TLispPort;
begin
  LispTypeCheck(Port, TLispPort, 'Not a port');
  P := TLispPort(Port);
  P.NextChar;
end;

function LispEOF(Port: LV): Boolean;
var
  P: TLispPort;
begin
  LispTypeCheck(Port, TLispPort, 'Not a port');
  P := TLispPort(Port);
  Result := P.EOF;
end;

procedure LispWriteChar(C: Char; Port: LV);
var
  P: TLispPort;
begin
  LispTypeCheck(Port, TLispPort, 'Not a port');
  P := TLispPort(Port);
  P.WriteChar(C);
end;

procedure LispClosePort(Port: LV);
var
  P: TLispPort;
begin
  LispTypeCheck(Port, TLispPort, 'Not a port');
  P := TLispPort(Port);
  P.Close;
end;

{ TLispProcedure }

function TLispProcedure.WithName(AName: string): LV;
var
  P: TLispProcedure;
begin
  P := TLispProcedure.Create;
  P.FName := AName;
  Result := P;
end;

{ TLispPrimitive }

function TLispPrimitive.ToWrite: string;
begin
  Result := '#<primitive ' + FName + '>';
end;

function TLispPrimitive.WithName(AName: string): LV;
begin
  Result := TLispPrimitive.Create(AName, FImpl);
end;

function TLispPrimitive.Exec(Args: LV): LV;
begin
  Result := FImpl(Args);
end;

constructor TLispPrimitive.Create(AImpl: TLispPrimitiveFunc);
begin
  FName := '';
  FImpl := AImpl;
end;

constructor TLispPrimitive.Create(AName: string; AImpl: TLispPrimitiveFunc);
begin
  FName := AName;
  FImpl := AImpl;
end;

{ TLispObjectPrimitive }

function TLispObjectPrimitive.Exec(Args: LV): LV; 
begin
  Result := FImpl(Args);
end;

function TLispObjectPrimitive.WithName(AName: string): LV;
begin
  Result := TLispObjectPrimitive.Create(AName, FImpl);
end;

constructor TLispObjectPrimitive.Create(AImpl: TLispPrimitiveMethod);
begin
  FName := '';
  FImpl := AImpl;
end;

constructor TLispObjectPrimitive.Create(AName: string; AImpl: TLispPrimitiveMethod);
begin
  FName := AName;
  FImpl := AImpl;
end;

{ TLispClosure }

function TLispClosure.ToWrite: string;
var
  N: string;
begin
  if FName = '' then
  begin
    N := '';
  end
  else
  begin
    N := FName + ' ';
  end;

  Result := '#<closure ' + N + LispToWrite(Args) + '>';
end;

function TLispClosure.WithName(AName: string): LV;
begin
  Result := TLispClosure.Create(AName, Args, Code, Env);
end;

constructor TLispClosure.Create(AName: string; AArgs, ACode, AEnv: LV);
begin
  FName := AName;
  FArgs := AArgs;
  FCode := ACode;
  FEnv := AEnv;
end;

{ TLispMultipleValues }

const
  LineFeed = #10;

function MultivalToString(X: TLispMultipleValues; Display: Boolean): string;
var
  Cur: LV;
begin
  Result := LispToString(X.First, Display);
  Cur := X.Rest;
  while Cur <> LispEmpty do
  begin
    Result := Result + LineFeed + LispToString(LispCar(Cur), Display);
    Cur := LispCdr(Cur);
  end;
end;

function TLispMultipleValues.ToWrite: string;
begin
  Result := MultivalToString(Self, False);
end;

function TLispMultipleValues.ToDisplay: string;
begin
  Result := MultivalToString(Self, True);
end;

constructor TLispMultipleValues.Create(AFirst, ARest: LV);
begin
  FFirst := AFirst;
  FRest := ARest;
end;

initialization

  { Base values }
  LispEmpty := LV.Create;
  LispVoid := LV.Create;
  LispTrue := LV.Create;
  LispFalse := LV.Create;
  LispEOFObject := LV.Create;
  { Symbols }
  SymList := TStringList.Create;
  Gensyms := 0;
  { Characters }
  InitChars;

end.
