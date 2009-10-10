{$ifdef Interface}

{ Base Types }

type
  LV = class
  public
    function ToWrite: string; virtual;
    function ToDisplay: string; virtual;
    function Equals(X: LV): Boolean; virtual;
  end;

  TLispType = class of LV;
  PLV = ^LV;
  TLVArray = array[0..MaxInt div SizeOf(LV)] of LV;
  PLVArray = ^TLVArray;

  ELispError = class(Exception)
  public
    constructor Create(Msg: string; What: LV);
  end;

  {$include lispdata.pas}
  //{$include lispcode.pas}

{ Data }
  
{ Code }
type
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


{ Misc Routines }


function LispToWrite(X: LV): string;
function LispToDisplay(X: LV): string;
procedure LispTypeCheck(X: LV; Expected: TLispType; Msg: string);
procedure LispParseArgs(Src: LV; Args: array of PLV; Variadic: Boolean = False);

{$else}

{$include lispdata.pas}

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

procedure InitTypes;
begin
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
end;

{$endif}
