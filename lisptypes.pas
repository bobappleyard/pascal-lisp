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
  {$include lispcode.pas}

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


procedure LispTypeCheck(X: LV; Expected: TLispType; Msg: string);
function LispTypePredicate(T: TLispType): LV;
procedure LispParseArgs(Src: LV; Args: array of PLV; Variadic: Boolean = False);

{$else}

  {$include lispdata.pas}
  {$include lispcode.pas}

procedure LispTypeCheck(X: LV; Expected: TLispType; Msg: string);
begin
  if not (X is Expected) then
  begin
    raise ELispError.Create(Msg, X);
  end;
end;

type
  TLispTypePredicate = class
  private
    FType: TLispType;
  public
    function Check(Args: LV): LV;
    constructor Create(T: TLispType);
  end;
  
function TLispTypePredicate.Check(Args: LV): LV;
var
  X: LV;
begin
  LispParseArgs(Args, [@X]);
  Result := LispBoolean(X is FType);
end;

constructor TLispTypePredicate.Create(T: TLispType);
begin
  FType := T;
end;

function LispTypePredicate(T: TLispType): LV;
var
  Tester: TLispTypePredicate;
begin
  Tester := TLispTypePredicate.Create(T);
  Result := LispPrimitive(Tester.Check);
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
  if (What = nil) or (What = LispVoid) then
  begin
    inherited Create(Msg);
  end
  else
  begin
    inherited Create(Msg + ': ' + LispToWrite(What));
  end;
end;

{ TLispMultipleValues }

const
  LineFeed = #10;

function MultivalToString(X: TLispMultipleValues; Display: Boolean): string;
var
  Cur: LV;
begin
  Result := LispDataToString(X.First, Display);
  Cur := X.Rest;
  while Cur <> LispEmpty do
  begin
    Result := Result + LineFeed + LispDataToString(LispCar(Cur), Display);
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
 
{$endif}
