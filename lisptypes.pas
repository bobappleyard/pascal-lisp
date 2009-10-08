unit LispTypes;

interface

uses
  SysUtils, Classes;

type

{ Base Types }

  LV = class
  public
    function ToString: string; virtual;
    function Equals(X: LV): Boolean; virtual;
  end;

  TLispType = class of LV;

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

    function ToString: string; override;
    function Equals(X: LV): Boolean; override;
    constructor Create(AValue: Integer);
  end;

  TLispReal = class(TLispNumber)
  private
    FValue: Real;
  public
    property Value: Real read FValue;

    function ToString: string; override;
    function Equals(X: LV): Boolean; override;
    constructor Create(AValue: Real);
  end;

  TLispChar = class(LV)
  private
    FValue: Char;
  public
    property Value: Char read FValue;

    function ToString: string; override;
    function Equals(X: LV): Boolean; override;
    constructor Create(AValue: Char);    
  end;
  
  TLispString = class(LV)
  private
    FValue: string;
  public
    property Value: string read FValue;

    function ToString: string; override;
    constructor Create(AValue: string);
  end;

  TLispSymbol = class(LV)
  private
    FIdent: Integer;
  public
    property Ident: Integer read FIdent;

    function ToString: string; override;
    function Equals(X: LV): Boolean; override;
    constructor Create(AName: string);
  end;
  
  TLispPair = class(LV)
  public
    A, D: LV;

    function ToString: string; override;
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
    function ToString: string; override;
    constructor Create(AStream: TStream);
  end;
  
{ Code }

  TLispProcedure = class(LV)
  protected
    FName: string;
  public
  end;
  
  TLispPrimitiveProcedure = function(Args: LV): LV;
  
  TLispPrimitive = class(TLispProcedure)
  private
    FImpl: TLispPrimitiveProcedure;
    FArgCount: Integer;
    FVariadic: Boolean;
  public
    function ToString: string; override;
    function Exec(Args: LV): LV;
    constructor Create(Impl: TLispPrimitiveProcedure); overload;
    constructor Create(AName: string; ACount: Integer; AVar: Boolean; Impl: TLispPrimitiveProcedure); overload;
  end;
  
  TLispClosure = class(TLispProcedure)
  private
    FCode, FArgs, FEnv: LV;
  public
    property Code: LV read FCode;
    property Args: LV read FArgs;
    property Env: LV read FEnv;

    function ToString: string; override;
    constructor Create(AName: string; AArgs, ACode, AEnv: LV);
  end;

var
  LispEmpty, LispVoid, LispTrue, LispFalse, LispEOFObject: LV;

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

function LispToString(X: LV): string;
procedure LispTypeCheck(X: LV; Expected: TLispType; Msg: string);
function BooleanToLisp(X: Boolean): LV;

implementation

function LispToString(X: LV): string;
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
  else
  begin
    Result := X.ToString;
  end;
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

{ LV }

function LV.ToString: string;
begin
  Result := '';
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
    inherited Create(Msg + ': ' + LispToString(What));
  end;
end;
  
{ TLispFixnum }

function TLispFixnum.ToString: string; 
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

function TLispReal.ToString: string; 
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

function TLispChar.ToString: string; 
begin
  Result := Value;
end;

function TLispChar.Equals(X: LV): Boolean;
begin
  Result := (X is TLispChar) and (TLispChar(X).Value = Value);
end;

constructor TLispChar.Create(AValue: Char);
begin
  FValue := AValue;
end;

{ TLispString }

function TLispString.ToString: string; 
begin
  Result := Value;
end;

constructor TLispString.Create(AValue: string);
begin
  FValue := AValue;
end;

{ TLispSymbol }

var
  SymList: array of string;

function TLispSymbol.ToString: string;
begin
  Result := SymList[Ident];
end;

function TLispSymbol.Equals(X: LV): Boolean;
begin
  Result := (X is TLispSymbol) and (TLispSymbol(X).Ident = Ident);
end;

constructor TLispSymbol.Create(AName: string);
var
  I, L: Integer;
begin
  L := Length(SymList);

  for I := 0 to L - 1 do
  begin
    if AName = SymList[I] then
    begin
      FIdent := I;
      exit;
    end;
  end;

  SetLength(SymList, L + 1);
  SymList[L] := AName;
  FIdent := L;
end;

{ TLispPair }

function TLispPair.ToString: string; 
var
  Rest: string;
begin
  if D is TLispPair then
  begin
    Rest := ' ' + Copy(D.ToString, 2, MaxInt);
  end
  else if D = LispEmpty then
  begin
    Rest := ')';
  end
  else
  begin
    Rest := ' . ' + D.ToString + ')';
  end;

  Result := '(' + A.ToString + Rest;
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

function TLispPort.ToString: string; 
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

{ TLispPrimitive }

function TLispPrimitive.ToString: string;
begin
  Result := '#<primitive ' + FName + '>';
end;

function TLispPrimitive.Exec(Args: LV): LV;
var
  L: Integer;
begin
  L := LispLength(Args);
  if FVariadic then
  begin
    if L < FArgCount then
    begin
      raise ELispError.Create('Wrong number of arguments', Self);
    end;
  end
  else
  begin
    if L <> FArgCount then
    begin
      raise ELispError.Create('Wrong number of arguments', Self);      
    end;
  end;

  Result := FImpl(Args);
end;

constructor TLispPrimitive.Create(Impl: TLispPrimitiveProcedure);
begin
  FName := '';
  FArgCount := 0;
  FVariadic := True;
  FImpl := Impl;
end;

constructor TLispPrimitive.Create(AName: string; ACount: Integer; AVar: Boolean; Impl: TLispPrimitiveProcedure);
begin
  FName := AName;
  FArgCount := ACount;
  FVariadic := AVar;
  FImpl := Impl;
end;

{ TLispClosure }

function TLispClosure.ToString: string;
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

  Result := '#<closure ' + N + LispToString(Args) + '>';
end;

constructor TLispClosure.Create(AName: string; AArgs, ACode, AEnv: LV);
begin
  FName := AName;
  FArgs := AArgs;
  FCode := ACode;
  FEnv := AEnv;
end;

initialization

  LispEmpty := LV.Create;
  LispVoid := LV.Create;
  LispTrue := LV.Create;
  LispFalse := LV.Create;
  LispEOFObject := LV.Create;

end.
