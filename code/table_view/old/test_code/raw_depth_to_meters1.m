function M = raw_depth_to_meters1(D)

valid_idx = D<2047;
M = 1./(-0.0030711016*double(D)+ 3.3309495161);
M(~valid_idx) = 2047;