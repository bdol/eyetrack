function Iwarp = tps_warp(st, I, centroid, w, h)
% Takes an input image I and a thin plate smoothing structure st, and
% returns the warped image.

imh = size(I, 1);
imw = size(I, 2);

% Iwarp = zeros(h, w, 3);
% for x=1:w
%     for y=1:h
%         xi = x-w/2;
%         yi = y-h/2;
%         p = fnval(st, [xi; yi]);
%         p = floor(p+centroid');
%         
%         
%         if p(1)>1 && p(1)<=imw && p(2)>1 && p(2)<=imh
%             Iwarp(y, x, :) = I(p(2), p(1), :);
%         end
%     end
% end

[xx yy] = meshgrid(-w/2+1:w/2, -h/2+1:h/2);
 X = xx(:); Y = yy(:);
P_orig = [X'; Y'];
P_warp = floor(bsxfun(@plus, fnval(st, P_orig), centroid'));

idx = sub2ind([imh imw], P_warp(2, :)', P_warp(1, :)');
I_r = I(:, :, 1);
I_r = I_r(:);
I_g = I(:, :, 2);
I_g = I_g(:);
I_b = I(:, :, 3);
I_b = I_b(:);

Iwarp_r = I_r(idx);
Iwarp_r = reshape(Iwarp_r, [h w]);
Iwarp_g = I_g(idx);
Iwarp_g = reshape(Iwarp_g, [h w]);
Iwarp_b = I_b(idx);
Iwarp_b = reshape(Iwarp_b, [h w]);
Iwarp = zeros(h, w, 3);
Iwarp(:, :, 1) = Iwarp_r;
Iwarp(:, :, 2) = Iwarp_g;
Iwarp(:, :, 3) = Iwarp_b;

end