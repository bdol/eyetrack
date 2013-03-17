function I = convert_image(fName)

xres = 1280;
yres = 1024;

fp=fopen(fName, 'rb');
d = fread(fp, prod([xres yres 3]));
red = d(1:3:end);
green = d(2:3:end);
blue = d(3:3:end);
red = reshape(red,[xres yres]);
blue = reshape(blue,[xres yres]);
green = reshape(green,[xres yres]);

im = zeros(xres, yres, 3);
im(:,:,1) = red;
im(:,:,2) = green;
im(:,:,3) = blue;
im = im./255;
im_image = zeros(yres, xres, 3);
im_image(:,:,1) = im(:,:,1)';
im_image(:,:,2) = im(:,:,2)';
im_image(:,:,3) = im(:,:,3)';

I = im_image;

fclose(fp);

end