function depth = load_raw_depth(fName)

xres = 640;
yres = 480;
fp = fopen(fName, 'rb');
d = fread(fp);
depth = 256*d(2:2:end)+d(1:2:end);
% Raw depth is in mm, convert to m
depth = reshape(depth, [xres yres])'/1000; 

end