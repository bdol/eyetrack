function histogram_3d(X)

xd = X(:, 1);
yd = X(:, 2);

xi = 0:2:40;
yi = 0:2:32;

xr = interp1(xi, 1:numel(xi), xd, 'nearest');
yr = interp1(yi, 1:numel(yi), yd, 'nearest');

Z = accumarray([xr yr], 1, [numel(xi) numel(yi)]);
surf(Z);


end