uses robot;
procedure Row;
begin
while freefromright do
begin paint; right;  end;
paint;
while FreeFromLeft do left;
end;
begin
field(9,9);
while FreeFromLeft do left;
while FreeFromup do up;
while FreeFromdown do begin row; down; down; end;
while freeFromRight do begin paint; right; end;
paint;
end.
