unit Primitives;

interface

uses
  LispTypes;

procedure RegisterPrimitive(Name: string; Count: Integer; Variadic: Boolean; Proc: TLispPrimitiveProcedure; var Env: LV);
function PrimitiveEnvironment: LV;

implementation

procedure RegisterPrimitive(Name: string; Count: Integer; Variadic: Boolean; Proc: TLispPrimitiveProcedure; var Env: LV);
var
  Binding, P: LV;
begin
  P := TLispPrimitive.Create(Name, Count, Variadic, Proc);
  Binding := TLispPair.Create(TLispSymbol.Create(Name), P);
  Env := TLispPair.Create(Binding, Env);
end;

{ General Stuff }

function EqP(Args: LV): LV;
var 
  A, B: LV;
begin
  A := LispRef(Args, 0);
  B := LispRef(Args, 1);

  Result := BooleanToLisp(A.Equals(B));
end;

{ Fixnums }

procedure CheckFixnum(X: LV);
begin
  LispTypeCheck(X, TLispFixnum, 'Not a fixnum');
end;

function FixnumP(Args: LV): LV;
begin
  if LispRef(Args, 0) is TLispFixnum then
  begin
    Result := LispTrue;
  end
  else
  begin
    Result := LispFalse;
  end;
end;

function FixnumAdd(Args: LV): LV;
var
  A, B: TLispFixnum;
begin
  A := TLispFixnum(LispRef(Args, 0));
  B := TLispFixnum(LispRef(Args, 1));
  CheckFixnum(A);
  CheckFixnum(B);

  Result := TLispFixnum.Create(A.Value + B.Value);
end;

function FixnumSubtract(Args: LV): LV;
var
  A, B: TLispFixnum;
begin
  A := TLispFixnum(LispRef(Args, 0));
  B := TLispFixnum(LispRef(Args, 1));
  CheckFixnum(A);
  CheckFixnum(B);

  Result := TLispFixnum.Create(A.Value - B.Value);
end;

function FixnumMultiply(Args: LV): LV;
var
  A, B: TLispFixnum;
begin
  A := TLispFixnum(LispRef(Args, 0));
  B := TLispFixnum(LispRef(Args, 1));
  CheckFixnum(A);
  CheckFixnum(B);

  Result := TLispFixnum.Create(A.Value * B.Value);
end;

function FixnumQuotient(Args: LV): LV;
var
  A, B: TLispFixnum;
begin
  A := TLispFixnum(LispRef(Args, 0));
  B := TLispFixnum(LispRef(Args, 1));
  CheckFixnum(A);
  CheckFixnum(B);

  Result := TLispFixnum.Create(A.Value div B.Value);
end;

function FixnumToReal(Args: LV): LV;
var
  X: TLispFixnum;
begin
  X := TLispFixnum(LispRef(Args, 0));
  Result := TLispReal.Create(X.Value);
  Result := TLispReal.Create(X.Value);
end;

{ Reals }

procedure CheckReal(X: LV);
begin
  LispTypeCheck(X, TLispReal, 'Not a Real');
end;

function RealP(Args: LV): LV;
begin
  if LispRef(Args, 0) is TLispReal then
  begin
    Result := LispTrue;
  end
  else
  begin
    Result := LispFalse;
  end;
end;

function RealAdd(Args: LV): LV;
var
  A, B: TLispReal;
begin
  A := TLispReal(LispRef(Args, 0));
  B := TLispReal(LispRef(Args, 1));
  CheckReal(A);
  CheckReal(B);

  Result := TLispReal.Create(A.Value + B.Value);
end;

function RealSubtract(Args: LV): LV;
var
  A, B: TLispReal;
begin
  A := TLispReal(LispRef(Args, 0));
  B := TLispReal(LispRef(Args, 1));
  CheckReal(A);
  CheckReal(B);

  Result := TLispReal.Create(A.Value - B.Value);
end;

function RealMultiply(Args: LV): LV;
var
  A, B: TLispReal;
begin
  A := TLispReal(LispRef(Args, 0));
  B := TLispReal(LispRef(Args, 1));
  CheckReal(A);
  CheckReal(B);

  Result := TLispReal.Create(A.Value * B.Value);
end;

function RealDivide(Args: LV): LV;
var
  A, B: TLispReal;
begin
  A := TLispReal(LispRef(Args, 0));
  B := TLispReal(LispRef(Args, 1));
  CheckReal(A);
  CheckReal(B);

  Result := TLispReal.Create(A.Value / B.Value);
end;

{ Pairs }

function PairP(Args: LV): LV;
begin
  if LispRef(Args, 0) is TLispPair then
  begin
    Result := LispTrue;
  end
  else
  begin
    Result := LispFalse;
  end;  
end;

function Cons(Args: LV): LV;
begin
  Result := TLispPair.Create(LispRef(Args, 0), LispRef(Args, 1));
end;

function Car(Args: LV): LV;
begin
  Result := LispCar(LispRef(Args, 0));
end;

function Cdr(Args: LV): LV;
begin
  Result := LispCdr(LispRef(Args, 0));
end;

function PrimitiveEnvironment: LV;
var
  Env: LV;
begin
  Env := LispEmpty;

  { General stuff }
  RegisterPrimitive('eq?', 2, False, @EqP, Env);

  { Fixnums }
  RegisterPrimitive('fixnum-add', 2, False, @FixnumAdd, Env);
  RegisterPrimitive('fixnum-subtract', 2, False, @FixnumSubtract, Env);
  RegisterPrimitive('fixnum-multiply', 2, False, @FixnumMultiply, Env);
  RegisterPrimitive('fixnum-quotient', 2, False, @FixnumQuotient, Env);

  { Reals }
  RegisterPrimitive('real-add', 2, False, @RealAdd, Env);
  RegisterPrimitive('real-subtract', 2, False, @RealSubtract, Env);
  RegisterPrimitive('real-multiply', 2, False, @RealMultiply, Env);
  RegisterPrimitive('real-divide', 2, False, @RealDivide, Env);

  { Pairs }
  RegisterPrimitive('pair?', 1, False, @PairP, Env);
  RegisterPrimitive('cons', 2, False, @Cons, Env);
  RegisterPrimitive('car', 1, False, @Car, Env);
  RegisterPrimitive('cdr', 1, False, @Cdr, Env);

  Result := Env;
end;


end.












