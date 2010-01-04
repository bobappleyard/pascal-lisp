uses
  Lisp, IOStream;

var
  Interpreter: TLispInterpreter;
  Input, Output: LV;
begin
  Interpreter := TLispInterpreter.Create(True);
  Input := LispInputStream(TIOStream.Create(iosInput));
  Output := LispOutputStream(TIOStream.Create(iosOutput));
  
  Interpreter.REPL(Input, Output);
end.