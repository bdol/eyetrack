function [K_rgb K_ir R T] = parse_kinect_yaml(fName)
% Note: remove the %YAML 1.0 at the top of the file, and any !!opencv
% matrix comments.

raw = ReadYaml(fName);
K_rgb = zeros(3, 3);
for i=1:3
    for j=1:3
        K_rgb(i, j) = raw.rgb_intrinsics.data{(i-1)*3+j};
    end
end

K_ir = zeros(3, 3);
for i=1:3
    for j=1:3
        K_ir(i, j) = raw.depth_intrinsics.data{(i-1)*3+j};
    end
end

R = zeros(3, 3);
for i=1:3
    for j=1:3
        R(i, j) = raw.R.data{(i-1)*3+j};
    end
end

T = zeros(3, 1);
for i=1:3
    T(i) = raw.T.data{i};
end

end