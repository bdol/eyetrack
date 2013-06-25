function I = get_raw_image(fName)

xres_im = 1280;
yres_im = 1024;
xres_dp = 640;
yres_dp = 480;

fp=fopen(fName, 'rb');
d = fread(fp);

if numel(d)>xres_dp*yres_dp*2 % We're processing an RGB image
    red = d(1:3:end);
    green = d(2:3:end);
    blue = d(3:3:end);
    red = reshape(red,[xres_im yres_im]);
    blue = reshape(blue,[xres_im yres_im]);
    green = reshape(green,[xres_im yres_im]);
    
    im = zeros(xres_im, yres_im, 3);
    im(:,:,1) = red;
    im(:,:,2) = green;
    im(:,:,3) = blue;
    im = im./255;
    im_image = zeros(yres_im, xres_im, 3);
    im_image(:,:,1) = im(:,:,1)';
    im_image(:,:,2) = im(:,:,2)';
    im_image(:,:,3) = im(:,:,3)';

    I = im_image/max(max(max(im_image)));    
else % We're processing a depth image
    depth = 256*d(2:2:end)+d(1:2:end);
    depth = reshape(depth, [xres_dp, yres_dp])';
    I = depth;
end

fclose(fp);

end