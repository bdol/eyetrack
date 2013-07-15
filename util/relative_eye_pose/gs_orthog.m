function [va vb] = gs_orthog(v0)

% Start in the most orthogonal direction to the normal
[mval mind] = min(abs(v0));
v_start = -mval*v0;
v_start(mind) = 1;
v_start = v_start/norm(v_start);

va = cross(v0, v_start);
va = va/norm(va);
vb = cross(v0, va);
vb = vb/norm(vb);

end