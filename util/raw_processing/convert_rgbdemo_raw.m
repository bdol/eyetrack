function I = convert_rgbdemo_raw(fName)

xres = 640;
yres = 480;
fp=fopen(fName, 'rb');
d = fread(fp, 'float32');

vals = d(3:end);
I = reshape(vals, [xres yres])'./255;

fclose(fp);

end