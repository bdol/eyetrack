function R = determine_plane_rotation(v1)

% Start in the most orthogonal direction to the normal
[mval mind] = min(abs(v1));
v_start = -mval*v1;
v_start(mind) = 1;
v_start = v_start/norm(v_start);

v2 = cross(v1, v_start);
v2 = v2/norm(v2);
v3 = cross(v1, v2);
v3 = v3/norm(v3);

R = [v2 v3 v1];