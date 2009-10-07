interface

uses
  SysUtils;

type

{ Base Types }

  LV = class
  public
    function ToString: string; virtual;
  end;

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
    constructor Create(AValue: Integer);
  end;

  TLispReal = class(TLispNumber)
  private
    FValue: Real;
  public
    property Value: Real read FValue;

    function ToString: string; override;
    constructor Create(AValue: Real);
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
    constructor Create(AName: string);
  end;
  
  TLispPair = class(LV)
  public
    A, D: LV;

    function ToString: string; override;
    constructor Create(AA, AD: LV);    
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
  public
    function ToString: string; override;
    function Exec(Args: LV): LV;
    constructor Create(AName: string; Impl: TLispPrimitiveProcedure);
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

{ List fun }

var
  LispEmpty: LV;

function LispCar(X: LV): LV;
function LispCdr(X: LV): LV;
function LispAppend(L1, L2: LV): LV;

implementation

{ LV }

function LV.ToString: string;
begin
  Result := '';
end;

{ ELispError }

constructor Create(Msg: string; What: LV);
begin
  if What = nil then
  begin
    inherited Create(Msg);
  end
  else
  begin
    inherited Create(Msg + ': ' + What.ToString);
  end;
end;
  
{ TLispFixnum }

function TLispFixnum.ToString: string; 
begin
  Result := IntToStr(Value);
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

constructor TLispReal.Create(AValue: Real);
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

{ TLispPair }

function TLispPair.ToString: string; 
var
  Rest: string;
begin
  if D is TLispPair then
  begin
    Rest := Copy(D.ToString, 2, MaxInt);
  end
  else
  begin
    Rest := '. ' + D.ToString;
  end;

  Result := '(' + A.ToString + ' ' + Rest;
end;

constructor TLispPair.Create(AA, AD: LV);    
begin
  A := AA;
  D := AD;
end;

function LispCar(X: LV): LV;
begin
  if not (X is TLispPair) then
  begin
    raise ELispError.Create('Not a pair', X);
  end;

  Result := TLispPair(X).A;
end;

function LispCdr(X: LV): LV;
begin
  if not (X is TLispPair) then
  begin
    raise ELispError.Create('Not a pair', X);
  end;

  Result := TLispPair(X).D;
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

{ TLispSymbol }

var
  SymList: array of string;

function TLispSymbol.ToString: string;
begin
  Result := SymList[Ident];
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

{ TLispPrimitive }

function TLispPrimitive.ToString: string;
begin
  Result := '#<primitive ' + FName + '>';
end;

function TLispPrimitive.Exec(Args: LV): LV;
begin
  Result := FImpl(Args);
end;

constructor TLispPrimitive.Create(AName: string; Impl: TLispPrimitiveProcedure);
begin
  FName := AName;
  FImpl := Impl;
end;

{ TLispClosure }

function TLispClosure.ToString: string;
begin
  Result := '#<closure ' + FName + '>';
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

end.
