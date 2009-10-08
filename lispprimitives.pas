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
  Result := BooleanToLisp(LispRef(Args, 0) is TLispFixnum);
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
  Result := BooleanToLisp(LispRef(Args, 0) is TLispReal);
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
  Result := BooleanToLisp(LispRef(Args, 0) is TLispPair);
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
  I.RegisterGlobal('eq?', TLispPrimitive.Create('', 2, False, @EqP));

 { Fixnums }
  I.RegisterGlobal('fixnum?', TLispPrimitive.Create('', 1, False, @FixnumP));
  I.RegisterGlobal('fixnum-add', TLispPrimitive.Create('', 2, False, @FixnumAdd));
  I.RegisterGlobal('fixnum-subtract', TLispPrimitive.Create('', 2, False, @FixnumSubtract));
  I.RegisterGlobal('fixnum-multiply', TLispPrimitive.Create('', 2, False, @FixnumMultiply));
  I.RegisterGlobal('fixnum-quotient', TLispPrimitive.Create('', 2, False, @FixnumQuotient));
  I.RegisterGlobal('fixnum->real', TLispPrimitive.Create('', 1, False, @FixnumToReal));

  { Reals }
  I.RegisterGlobal('real?', TLispPrimitive.Create('', 1, False, @RealP));
  I.RegisterGlobal('real-add', TLispPrimitive.Create('', 2, False, @RealAdd));
  I.RegisterGlobal('real-subtract', TLispPrimitive.Create('', 2, False, @RealSubtract));
  I.RegisterGlobal('real-multiply', TLispPrimitive.Create('', 2, False, @RealMultiply));
  I.RegisterGlobal('real-divide', TLispPrimitive.Create('', 2, False, @RealDivide));

  { Pairs }
  I.RegisterGlobal('pair?', TLispPrimitive.Create('', 1, False, @PairP));
  I.RegisterGlobal('cons', TLispPrimitive.Create('', 2, False, @Cons));
  I.RegisterGlobal('car', TLispPrimitive.Create('', 1, False, @Car));
  I.RegisterGlobal('cdr', TLispPrimitive.Create('', 1, False, @Cdr));
end;


end.












