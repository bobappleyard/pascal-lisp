interface

uses
  LispCode;

type

{ Base Type }

  LV = class
  public
    function ToString: string; virtual;
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
    FCode, FEnv: LV;
  public
    property Code: LV read FCode;
    property Env: LV read FEnv;

    function ToString: string; override;
    constructor Create(AName: string; ACode: TLispCode; AEnv: LV);
  end;

implementation

{ LV }

function LV.ToString: string;
begin
  Result := '';
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
    Rest := SubString(D.ToString, 1, MaxInt);
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

{ TLispPrimitive }

function ToString: string;
begin
  Result := '#<primitive ' + FName + '>';
end;

function Exec(Args: LV): LV;
begin
  Result := FImpl(Args);
end;

constructor Create(AName: string; Impl: TLispPrimitiveProcedure);
begin
  FName := AName;
  FImpl := Impl;
end;

{ TLispClosure }

function ToString: string;
begin
  Result := '#<closure ' + FName + '>';
end;

constructor Create(AName: string; ACode, AEnv: LV);
begin
  FName := AName;
  FCode := ACode;
  FEnv := AEnv;
end;

end.
