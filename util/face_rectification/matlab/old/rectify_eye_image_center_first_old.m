function rect = rectify_eye_image_center_first(imorig, crop_x, crop_y, rw, rh, H, dc)
    rect = zeros(rh, rw, 3);
    imh = size(imorig, 1);
    imw = size(imorig, 2);
    for x=1:rw
        for y=1:rh
            pr = [x+crop_x; y+crop_y; 1];
            po = H*pr;
            po = floor(po./po(3));
            po = po+dc;
            
            if (po(1)>1 && po(1)<=imw && po(2)>1 && po(2)<=imh)
               rect(y, x, :) = imorig(po(2), po(1), :); 
            end
        end
    end


end