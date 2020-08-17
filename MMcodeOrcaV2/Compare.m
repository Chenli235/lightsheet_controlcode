a = magic(2048);
tic;
for ii = 1:100
    a = transpose(a);
    a = flipud(a);
end
toc
tic;
for ii = 1:100
    a = rot90(a);
end
toc