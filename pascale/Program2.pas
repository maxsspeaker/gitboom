uses robot;
begin
task('cif1') ;

while freeFromRight do begin
right;
if wallFromup then paint;
end;
end.