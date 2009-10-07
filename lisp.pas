uses
  LispTypes, IOStream, LispIO, Interp;

procedure REPL(LI: TLispInterpreter);
var
  Port: LV;
  C: Char;
begin
  Port := TLispPort.Create(TIOStream.Create(iosInput));
{  while True do
  begin
    C := LispReadChar(Port);
    Write(C);
  end;}
  while not LispEOF(Port) do
  begin
    Write(LispToString(LI.Eval(LispRead(Port), nil)), #10);
  end;
end;

var
  Code, Result: LV;
  Lisp: TLispInterpreter;
begin
  Lisp := TLispInterpreter.Create(LispEmpty);
  REPL(Lisp);
  
  //Code := LispReadString('''(1 2 3)');
end.

