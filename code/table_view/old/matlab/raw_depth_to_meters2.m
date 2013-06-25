function M = raw_depth_to_meters2(D)

valid_idx = D<2047;
M = 0.1236 * tan(double(D)/2842.5 + 1.1863);
M(~valid_idx) = 2047;