function I = convert_image(fName)

xres_im = 1280;
yres_im = 1024;
xres_dp = 640;
yres_dp = 480;
back_thresh = 850;

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
    r_depth = max(depth)-depth;
    r_depth(depth==0) = 0;
    r_depth = reshape(r_depth, [xres_dp yres_dp])';
    
    % Black out background
    r_depth(r_depth<back_thresh) = 0;
    % Bump the contrast of the figure
    min_val = min(r_depth(r_depth>0));
    max_val = max(max(r_depth));
    diff = max_val-min_val;
    r_depth(r_depth>0) = diff*(r_depth(r_depth>0)-min_val);
    
    I = r_depth/max(max(r_depth));   
end

fclose(fp);

end