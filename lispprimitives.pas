unit LispPrimitives;

interface

uses
  LispTypes, LispInterpreter;

procedure RegisterPrimitives(I: TLispInterpreter);

implementation

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

procedure RegisterPrimitives(I: TLispInterpreter);
begin
  { General stuff }
  I.RegisterGlobal('eq?', TLispPrimitive.Create('eq?', 2, False, @EqP));

 { Fixnums }
  I.RegisterGlobal('fixnum-add', TLispPrimitive.Create('fixnum-add', 2, False, @FixnumAdd));
  I.RegisterGlobal('fixnum-subtract', TLispPrimitive.Create('fixnum-subtract', 2, False, @FixnumSubtract));
  I.RegisterGlobal('fixnum-multiply', TLispPrimitive.Create('fixnum-multiply', 2, False, @FixnumMultiply));
  I.RegisterGlobal('fixnum-quotient', TLispPrimitive.Create('fixnum-quotient', 2, False, @FixnumQuotient));

  { Reals }
  I.RegisterGlobal('real-add', TLispPrimitive.Create('real-add', 2, False, @RealAdd));
  I.RegisterGlobal('real-subtract', TLispPrimitive.Create('real-subtract', 2, False, @RealSubtract));
  I.RegisterGlobal('real-multiply', TLispPrimitive.Create('real-multiply', 2, False, @RealMultiply));
  I.RegisterGlobal('real-divide', TLispPrimitive.Create('real-divide', 2, False, @RealDivide));

  { Pairs }
  I.RegisterGlobal('pair?', TLispPrimitive.Create('pair?', 1, False, @PairP));
  I.RegisterGlobal('cons', TLispPrimitive.Create('cons', 2, False, @Cons));
  I.RegisterGlobal('car', TLispPrimitive.Create('car', 1, False, @Car));
  I.RegisterGlobal('cdr', TLispPrimitive.Create('cdr', 1, False, @Cdr));
end;


end.












