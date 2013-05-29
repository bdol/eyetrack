function [Xw Yw Zw] = im_to_world(x, y, Z, fx, fy, cx, cy)
Zw = Z;
Xw = (x-cx).*Z./fx;
Yw = (y-cy).*Z./fy;

end