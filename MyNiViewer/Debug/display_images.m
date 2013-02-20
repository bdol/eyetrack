% Those images are stored as raw data, meaning no header.
% The actual format depends on the configuration being used, but if you 
% haven't changed it, then the color image is saved as 3 bytes per pixel 
%(Red, Green, Blue), and the depth map is stored as 16-bit values 
%(2 bytes per pixel) representing depth in millimeters.

folder = 'brian_head_pointed';
% for i=0:14
    i=0;
    str = sprintf('%s\\Image_%d.raw',folder, i);
    fp=fopen(str, 'rb');
    d = fread(fp, prod([640 480 3]));
    red = d(1:3:end);
    green = d(2:3:end);
    blue = d(3:3:end);
    red = reshape(red,[640 480]);
    blue = reshape(blue,[640 480]);
    green = reshape(green,[640 480]);
    red = red./255;
    blue = blue./255;
    green = green./255;

    im = zeros(640, 480, 3);
    im(:,:,1) = red;
    im(:,:,2) = green;
    im(:,:,3) = blue;
    im_image = zeros(480, 640, 3);
    im_image(:,:,1) = im(:,:,1)';
    im_image(:,:,2) = im(:,:,2)';
    im_image(:,:,3) = im(:,:,3)';
%     subplot(1,2,1);
    imshow(im_image);
    fclose(fp);
    
    % Read Depth images
%     str = sprintf('%s\\Depth_%d.raw',folder, i);
%     fp=fopen(str, 'rb');
%     d = fread(fp, prod([640 480 2]));
%     c = bitor(bitshift(bitor(uint16(0),uint16(d(2:2:end))),8),uint16(d(1:2:end)));
%     c = reshape(c,640,480);
%     c = fliplr(imrotate(c,-90));
%     subplot(1,2,2);
%     imagesc(c);
%     fclose(fp);
    
%     k = waitforbuttonpress;
%     i
% end