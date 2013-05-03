function T = transformEye(w, h, centroid, imorig, H)

imh = size(imorig, 1);
imw = size(imorig, 2);

T = zeros(h, w, 3);

for xs=1:w
    for ys=1:h
        x = xs-w/2;
        y = ys-h/2;
        
        ps = [x; y; 1];
        pim = H*ps;
        pim = pim./pim(3);
        pim(1) = floor(pim(1)+centroid(1));
        pim(2) = floor(pim(2)+centroid(2));
                
        if (pim(1)>1 && pim(1)<imw && pim(2)>1 && pim(2)<imh)
            T(ys, xs, :) = imorig(pim(2), pim(1), :);
        end
            
    end
end


end