function rect = rectify_eye_image_center_first(imorig, rw, rh, H, centroid_orig)
    rect = zeros(rh, rw, 3);
    rcx = rw/2;
    rcy = rh/2;
    imh = size(imorig, 1);
    imw = size(imorig, 2);
    for x=1:rw
        for y=1:rh
            pr = [x-rcx; y-rcy; 1];
            po = H*pr;
            po = po./po(3);
            po = floor(po(1:2)'+centroid_orig);
            
            if (po(1)>1 && po(1)<=imw && po(2)>1 && po(2)<=imh)
               rect(y, x, :) = imorig(po(2), po(1), :); 
            end
        end
    end


end