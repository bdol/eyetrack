function corr = gen_canon_corresp_points(w, h, p)
% Generates 6 correspondence points that fill the entire hxw image. These
% points are then used to transform an original eye to the canonical
% shape. You can specify a padding p. Note that these are in MATLAB's
% terrible indexing system, where array indices start at 1. They are given
% in [x y] format.

corr = zeros(6, 2);
if p>0
    corr = gen_canon_corresp_points(w-2*p, h-2*p, 0);
    corr = corr+p;
else
    corr(1, :) = [1 floor(h/2)];
    corr(2, :) = [floor(w/3) 1];
    corr(3, :) = [floor(2*w/3) 1];
    corr(4, :) = [w floor(h/2)];
    corr(5, :) = [floor(2*w/3) h];
    corr(6, :) = [floor(w/3) h];
end

end