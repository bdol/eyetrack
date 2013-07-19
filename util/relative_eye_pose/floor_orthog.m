function vf = floor_orthog(v0)

vf = cross(v0, [1 0 0]);
vf = vf/norm(vf);

end