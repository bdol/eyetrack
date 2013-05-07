function [rgb_success ir_success] = convert_raw_images(ir_prefix, ir_nums, image_prefix, image_nums, folder)

% Those images are stored as raw data, meaning no header.
% The actual format depends on the configuration being used, but if you 
% haven't changed it, then the color image is saved as 3 bytes per pixel 
%(Red, Green, Blue), and the depth map is stored as 16-bit values 
%(2 bytes per pixel) representing depth in millimeters.

image_xRes = 1280;
image_yRes = 1024;
ir_xRes = 640;
ir_yRes = 480;

% read rgb images
rgb_success = [];
count = 1;
for image_num = image_nums
    str = sprintf('%s/%s%d.raw',folder, image_prefix, image_num);
    fprintf('%s\n',str);
        try
            fp=fopen(str, 'rb');
            d = fread(fp, prod([image_xRes image_yRes 3]));
            red = d(1:3:end);
            green = d(2:3:end);
            blue = d(3:3:end);
            red = reshape(red,[image_xRes image_yRes]);
            blue = reshape(blue,[image_xRes image_yRes]);
            green = reshape(green,[image_xRes image_yRes]);
            red = red./255;
            blue = blue./255;
            green = green./255;

            im = zeros(image_xRes, image_yRes, 3);
            im(:,:,1) = red;
            im(:,:,2) = green;
            im(:,:,3) = blue;
            rgb = zeros(image_yRes, image_xRes, 3);
            rgb(:,:,1) = im(:,:,1)';
            rgb(:,:,2) = im(:,:,2)';
            rgb(:,:,3) = im(:,:,3)';
            imwrite(rgb, sprintf('%s/%s%d.jpg',folder, image_prefix, count), 'jpg');
            rgb_success = [rgb_success 1];
            count = count + 1;
%             print('-djpeg', filename);
            fclose(fp);
        catch exception
            rgb_success = [rgb_success 0];
        end 
end
    
% Read IR images
ir_success = [];
count = 1;
for ir_num = ir_nums
    str = sprintf('%s/%s%d.raw',folder, ir_prefix, ir_num);
    fprintf('%s\n',str);
        try
            fp=fopen(str, 'rb');
            d = fread(fp, prod([ir_xRes ir_yRes 2]));
            ir = bitor(bitshift(bitor(uint16(0),uint16(d(2:2:end))),8),uint16(d(1:2:end)));
            ir = reshape(ir,ir_xRes,ir_yRes);
    %         depth = fliplr(imrotate(depth,-90));
            ir = fliplr(imrotate(ir, -90));
            fclose(fp);
            ir = double(ir)./double(max(ir(:)));
            imwrite(ir, sprintf('%s/%s%d.jpg',folder, ir_prefix, count), 'jpg');
            ir_success = [ir_success 1];
            count = count + 1;
        catch exception
            ir_success = [ir_success 0];
        end 
end