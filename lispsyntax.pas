unit LispSyntax;

interface

uses
  SysUtils, Classes, LispTypes;

{ S-Exprs }

function LispRead(Port: LV): LV;
function LispReadString(S: string): LV;
procedure LispWrite(X, Port: LV);

{ Syntax-rules }



implementation

const
  LispWhitespace = [#9, #10, #13, #32];

{ Reading S-Exprs }

function ReadOver(var C: Char; Port: LV): Boolean;
begin
  if LispEOF(Port) then
  begin
    Result := True;
  end
  else
  begin
    C := LispPeekChar(Port);
    if (C = ')') or (C in LispWhitespace) then
    begin
      Result := True;
    end
    else
    begin
      LispNextChar(Port);
      Result := False;
    end;
  end;
end;

function ReadSymbol(First: string; Port: LV): LV;
var
  Name: string;
  C: Char;
begin
  Name := First;

  while not ReadOver(C, Port) do
  begin
    Name := Name + C;
  end;

  Result := LispSymbol(Name);
end;

function ReadNumber(First: string; Port: LV): LV;
var
  Str: string;
  C: Char;
  Fixnum: Boolean;
begin
  Str := First;
  Fixnum := True;

  while not ReadOver(C, Port) do
  begin
    Str := Str + C;
    if C = '.' then
    begin
      if Fixnum then
      begin
        Fixnum := False;
      end
      else
      begin
        Result := ReadSymbol(Str, Port);
        exit;
      end;
    end
    else if not (C in ['0' .. '9']) then
    begin
      Result := ReadSymbol(Str, Port);
      exit;
    end;
  end;

  if Fixnum then
  begin
    Result := TLispFixnum.Create(StrToInt(Str));
  end
  else 
  begin
    Result := TLispReal.Create(StrToFloat(Str));
  end;
end;

function ReadString(Port: LV): LV;
var
  Str: string;
  C: Char;
begin
  Str := '';
  C := LispReadChar(Port);

  while not (C = '"') do
  begin
    Str := Str + C;
    C := LispReadChar(Port);
  end;

  Result := TLispString.Create(Str);
end;

function ReadHash(Port: LV): LV;
var
  C: Char;
begin
  C := LispReadChar(Port);
  case C of
  
    't': Result := LispTrue;

    'f': Result := LispFalse;

    'v': Result := LispVoid;

    '\': Result := LispChar(LispReadChar(Port));

    else raise ELispError.Create('Unknown use of hash syntax', nil);

  end;
end;

function ReadWithWrapper(Name: string; Port: LV): LV;
var
  Rest: LV;
begin
  Rest := TLispPair.Create(LispRead(Port), LispEmpty);
  Result := TLispPair.Create(LispSymbol(Name), Rest);
end;

function ReadList(Port: LV): LV; forward;

function ReadWithChar(C: Char; Port: LV): LV;
begin
  if LispEOF(Port) then
  begin
    Result := LispEOFObject;
    exit;
  end;

  while C in LispWhitespace do
  begin
    C := LispReadChar(Port);

    if LispEOF(Port) then
    begin
      Result := LispEOFObject;
      exit;
    end;
  end;

  case C of 

    '0' .. '9': Result := ReadNumber(C, Port);

    '"': Result := ReadString(Port);

    '#': Result := ReadHash(Port);

    '(': Result := ReadList(Port);

    ')': raise ELispError.Create('Unexpected ")"', nil);

    '''': Result := ReadWithWrapper('quote', Port);

    '`': Result := ReadWithWrapper('quasiquote', Port);

    ',':  if LispPeekChar(Port) = '@' then
          begin
            LispNextChar(Port);
            Result := ReadWithWrapper('unquote-splicing', Port);
          end
          else
          begin
            Result := ReadWithWrapper('unquote', Port);
          end;

    else Result := ReadSymbol(C, Port);
  end;
end;

function ReadList(Port: LV): LV;
var
  Cur, Next: TLispPair;
  C: Char;
  ExpectingCons: Boolean;
begin
  Result := LispEmpty;
  ExpectingCons := False;
  while True do
  begin
    repeat
      C := LispReadChar(Port);
    until not (C in LispWhitespace);
    if C = ')' then
    begin
      exit;
    end
    else
    if C = '.' then
    begin
      if (Result = LispEmpty) or ExpectingCons then
      begin
        raise ELispError.Create('Invalid cons', nil);
      end
      else
      begin
        Cur.D := LispRead(Port);
        ExpectingCons := True;
      end;
    end
    else
    begin
      if ExpectingCons then
      begin
        raise ELispError.Create('Invalid cons', nil);        
      end
      else if Result = LispEmpty then
      begin
        Next := TLispPair.Create(ReadWithChar(C, Port), LispEmpty);
        Cur := Next;
        Result := Next;
      end
      else
      begin
        Next := TLispPair.Create(ReadWithChar(C, Port), LispEmpty);
        Cur.D := Next;
        Cur := Next;
      end;
    end;
  end;
end;

function LispRead(Port: LV): LV;
begin
  Result := ReadWithChar(LispReadChar(Port), Port);
end;

function LispReadString(S: string): LV;
begin
  Result := LispRead(TLispPort.Create(TStringStream.Create(S)));
end;

{ Writing S-Exprs }

procedure LispWrite(X, Port: LV);
begin
  if X <> LispVoid then
  begin
    LispWriteString(LispToWrite(X), Port);
  end;
end;



end.

