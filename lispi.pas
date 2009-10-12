uses
  Lisp, IOStream;

var
  Interpreter: TLispInterpreter;
  Input, Output: LV;
begin
  Interpreter := TLispInterpreter.Create(False);
  Input := LispInputStream(TIOStream.Create(iosInput));
  Output := LispOutputStream(TIOStream.Create(iosOutput));
  
  Interpreter.REPL(Input, Output);
end.