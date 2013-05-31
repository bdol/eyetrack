function W = get_warp_map(h, w, D, K_ir, K_rgb, R, T)
% TODO: fix this 
% [yy xx] = meshgrid(1:h, 1:w);
% X = xx(:); Y = yy(:);
% Z = D(:);
% P = [X Y Z]';
% P(1, :) = (P(1, :)-K_ir(1, 3)).*P(3, :)/K_ir(1, 1);
% P(2, :) = (P(2, :)-K_ir(2, 3)).*P(3, :)/K_ir(2, 2);
% P_rgb = K_rgb*bsxfun(@minus, R'*P, T);
% P_rgb = bsxfun(@rdivide, P_rgb, P_rgb(3, :));
% W = P_rgb(1:2, :)';

W = zeros(size(D));
for x=1:w
    for y=1:h
        p = [x; y; D(y, x)];
        p_w = p;
        p_w(1) = (p(1) - K_ir(1, 3))*p(3)/K_ir(1, 1);
        p_w(2) = (p(2) - K_ir(2, 3))*p(3)/K_ir(2, 2);
        p_w = R'*p_w - T;
        p_rgb = K_rgb*p_w;
        p_rgb = floor(p_rgb./p_rgb(3));
        
        if (p_rgb(1)>1 && p_rgb(1)<=w && p_rgb(2)>1 && p_rgb(2)<=h)
            W(p_rgb(2), p_rgb(1)) = D(y, x);
        end
    end
end


end