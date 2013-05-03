function corr = gen_canon_corresp_points(w, h, xp, yp)
% Generates 6 correspondence points that fill the entire hxw image. These
% points are then used to transform an original eye to the canonical
% shape. You can specify a padding p. Note that these are in MATLAB's
% terrible indexing system, where array indices start at 1. They are given
% in [x y] format.

corr = zeros(6, 2);
if xp>0 || yp>0
    corr = gen_canon_corresp_points(w-2*xp, h-2*yp, 0, 0);
else
    corr(1, :) = [1 floor(h/2)];
    corr(2, :) = [floor(w/3) 1];
    corr(3, :) = [floor(2*w/3) 1];
    corr(4, :) = [w floor(h/2)];
    corr(5, :) = [floor(2*w/3) h];
    corr(6, :) = [floor(w/3) h];
    corr = floor(bsxfun(@minus, corr, [w/2 h/2]));
end


end