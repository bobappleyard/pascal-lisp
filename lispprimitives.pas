unit LispPrimitives;

interface

uses
  LispTypes, LispInterpreter;

procedure RegisterPrimitives(I: TLispInterpreter);

implementation

function TestType(Args: LV; T: TLispType): LV;
var
  X: LV;
begin
  LispParseArgs(Args, [@X]);
  Result := BooleanToLisp(X is T);
end;

{ General Stuff }

function EqP(Args: LV): LV;
var 
  A, B: LV;
begin
  LispParseArgs(Args, [@A, @B]);
  Result := BooleanToLisp(A = B);
end;

function EqvP(Args: LV): LV;
var 
  A, B: LV;
begin
  LispParseArgs(Args, [@A, @B]);
  Result := BooleanToLisp(A.Equals(B));
end;

function NumberP(Args: LV): LV;
begin
  Result := TestType(Args, TLispNumber);
end;

function Gensym(Args: LV): LV;
begin
  LispParseArgs(Args, []);
  Result := LispSymbol('');
end;

{ Control }

function ProcedureP(Args: LV): LV;
begin
  Result := TestType(Args, TLispProcedure);
end;

function Values(Args: LV): LV;
var
  First, Rest: LV;
begin
  LispParseArgs(Args, [@First, @Rest], True);
  Result := TLispMultipleValues.Create(First, Rest);
end;

type
  TControlPrimitives = class
  private
    Lisp: TLispInterpreter;
  public
    function Apply(Args: LV): LV;
    function CallWithValues(Args: LV): LV;
    function AddDefinition(Args: LV): LV;

    constructor Create(Interpreter: TLispInterpreter);
  end;

function TControlPrimitives.Apply(Args: LV): LV;
var
  Proc, ArgLst: LV;
  First, This, Next: TLispPair;
begin
  LispParseArgs(Args, [@Proc, @ArgLst], True);
  if ArgLst = LispEmpty then
  begin
    Result := Lisp.Apply(Proc, ArgLst);
  end 
  else if LispCdr(ArgLst) = LispEmpty then
  begin
    Result := Lisp.Apply(Proc, LispCar(ArgLst));
  end
  else
  begin
    First := TLispPair.Create(LispCar(ArgLst), LispEmpty);
    This := First;
    ArgLst := LispCdr(ArgLst);
    while LispCdr(ArgLst) <> LispEmpty do
    begin
      Next := TLispPair.Create(LispCar(ArgLst), LispEmpty);
      This.D := Next;
      This := Next;
      ArgLst := LispCdr(ArgLst);
    end;
    This.D := LispCar(ArgLst);
    Result := Lisp.Apply(Proc, First);
  end;
end;

function TControlPrimitives.CallWithValues(Args: LV): LV;
var
  Producer, Consumer, Produced: LV;
  Vals: TLispMultipleValues;
begin
  LispParseArgs(Args, [@Producer, @Consumer]);
  Produced := Lisp.Apply(Producer, LispEmpty);
  if Produced is TLispMultipleValues then
  begin
    Vals := TLispMultipleValues(Produced);
    Result := Lisp.Apply(Consumer, TLispPair.Create(Vals.First, Vals.Rest));
  end
  else
  begin
    Result := Lisp.Apply(Consumer, TLispPair.Create(Produced, LispEmpty));
  end;
end;

function TControlPrimitives.AddDefinition(Args: LV): LV;
var
  Name, Value: LV;
begin
  LispParseArgs(Args, [@Name, @Value]);
  Lisp.RegisterGlobal(Name, Value);
  Result := LispVoid;
end;  
  
constructor TControlPrimitives.Create(Interpreter: TLispInterpreter);
begin
  Lisp := Interpreter;
end;

{ Fixnums }

procedure CheckFixnum(X: LV);
begin
  LispTypeCheck(X, TLispFixnum, 'Not a fixnum');
end;

function FixnumP(Args: LV): LV;
begin
  Result := TestType(Args, TLispFixnum);
end;

function FixnumAdd(Args: LV): LV;
var
  A, B: TLispFixnum;
begin
  LispParseArgs(Args,[@A, @B]);
  CheckFixnum(A);
  CheckFixnum(B);

  Result := TLispFixnum.Create(A.Value + B.Value);
end;

function FixnumSubtract(Args: LV): LV;
var
  A, B: TLispFixnum;
begin
  LispParseArgs(Args, [@A, @B]);
  CheckFixnum(A);
  CheckFixnum(B);

  Result := TLispFixnum.Create(A.Value - B.Value);
end;

function FixnumMultiply(Args: LV): LV;
var
  A, B: TLispFixnum;
begin
  LispParseArgs(Args, [@A, @B]);
  CheckFixnum(A);
  CheckFixnum(B);

  Result := TLispFixnum.Create(A.Value * B.Value);
end;

function FixnumQuotient(Args: LV): LV;
var
  A, B: TLispFixnum;
begin
  LispParseArgs(Args, [@A, @B]);
  CheckFixnum(A);
  CheckFixnum(B);

  Result := TLispFixnum.Create(A.Value div B.Value);
end;

function FixnumToReal(Args: LV): LV;
var
  X: TLispFixnum;
begin
  LispParseArgs(Args, [@X]);
  CheckFixnum(X);
  Result := TLispReal.Create(X.Value);
  Result := TLispReal.Create(X.Value);
end;

{ Reals }

procedure CheckReal(X: LV);
begin
  LispTypeCheck(X, TLispReal, 'Not a Real');
end;

function RealP(Args: LV): LV;
var
  X: LV;
begin
  LispParseArgs(Args, [@X]);  
  Result := BooleanToLisp(X is TLispReal);
end;

function RealAdd(Args: LV): LV;
var
  A, B: TLispReal;
begin
  LispParseArgs(Args, [@A, @B]);
  CheckReal(A);
  CheckReal(B);

  Result := TLispReal.Create(A.Value + B.Value);
end;

function RealSubtract(Args: LV): LV;
var
  A, B: TLispReal;
begin
  LispParseArgs(Args, [@A, @B]);
  CheckReal(A);
  CheckReal(B);

  Result := TLispReal.Create(A.Value - B.Value);
end;

function RealMultiply(Args: LV): LV;
var
  A, B: TLispReal;
begin
  LispParseArgs(Args, [@A, @B]);
  CheckReal(A);
  CheckReal(B);

  Result := TLispReal.Create(A.Value * B.Value);
end;

function RealDivide(Args: LV): LV;
var
  A, B: TLispReal;
begin
  LispParseArgs(Args, [@A, @B]);
  CheckReal(A);
  CheckReal(B);

  Result := TLispReal.Create(A.Value / B.Value);
end;

{ Pairs }

function PairP(Args: LV): LV;
var
  X: LV;
begin
  LispParseArgs(Args, [@X]);  
  Result := BooleanToLisp(X is TLispPair);
end;

function Cons(Args: LV): LV;
var
  A, D: TLispReal;
begin
  LispParseArgs(Args, [@A, @D]);
  Result := TLispPair.Create(A, D);
end;

function Car(Args: LV): LV;
var
  P: LV;
begin
  LispParseArgs(Args, [@P]);  
  Result := LispCar(P);
end;

function Cdr(Args: LV): LV;
var
  P: LV;
begin
  LispParseArgs(Args, [@P]);  
  Result := LispCdr(P);
end;

procedure RegisterPrimitives(I: TLispInterpreter);
var
  Control: TControlPrimitives;
begin
  Control := TControlPrimitives.Create(I);

  { General stuff }
  I.RegisterGlobal('eq?', TLispPrimitive.Create(@EqP));
  I.RegisterGlobal('eqv?', TLispPrimitive.Create(@EqvP));
  I.RegisterGlobal('number?', TLispPrimitive.Create(@NumberP));
  I.RegisterGlobal('gensym', TLispPrimitive.Create(@Gensym));

  { Control }
  I.RegisterGlobal('procedure?', TLispPrimitive.Create(@ProcedureP));
  I.RegisterGlobal('apply', TLispObjectPrimitive.Create(Control.Apply));
  I.RegisterGlobal('values', TLispPrimitive.Create(@Values));
  I.RegisterGlobal('call-with-values', TLispObjectPrimitive.Create(Control.CallWithValues));
  I.RegisterGlobal('add-definition', TLispObjectPrimitive.Create(Control.AddDefinition));
  

  { Fixnums }
  I.RegisterGlobal('fixnum?', TLispPrimitive.Create(@FixnumP));
  I.RegisterGlobal('fixnum-add', TLispPrimitive.Create(@FixnumAdd));
  I.RegisterGlobal('fixnum-subtract', TLispPrimitive.Create(@FixnumSubtract));
  I.RegisterGlobal('fixnum-multiply', TLispPrimitive.Create(@FixnumMultiply));
  I.RegisterGlobal('fixnum-quotient', TLispPrimitive.Create(@FixnumQuotient));
  I.RegisterGlobal('fixnum->real', TLispPrimitive.Create(@FixnumToReal));

  { Reals }
  I.RegisterGlobal('real?', TLispPrimitive.Create(@RealP));
  I.RegisterGlobal('real-add', TLispPrimitive.Create(@RealAdd));
  I.RegisterGlobal('real-subtract', TLispPrimitive.Create(@RealSubtract));
  I.RegisterGlobal('real-multiply', TLispPrimitive.Create(@RealMultiply));
  I.RegisterGlobal('real-divide', TLispPrimitive.Create(@RealDivide));

  { Pairs }
  I.RegisterGlobal('pair?', TLispPrimitive.Create(@PairP));
  I.RegisterGlobal('cons', TLispPrimitive.Create(@Cons));
  I.RegisterGlobal('car', TLispPrimitive.Create(@Car));
  I.RegisterGlobal('cdr', TLispPrimitive.Create(@Cdr));
end;


end.












