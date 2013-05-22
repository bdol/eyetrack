raw_dir = '/Applications/RGBDemo/lowrestest';
out_dir = '~/Desktop/lowrestest';
D_rgb = rdir([raw_dir '/*/*/*/color.png']);
D_depth = rdir([raw_dir '/*/*/*/depth.raw']);

fprintf('Converting images...\n');

c = 0;
for i=1:numel(D_rgb)
    I_rgb = imread(D_rgb(i).name);
    I_depth = convert_rgbdemo_raw(D_depth(i).name);
    
    rgb_fname = [out_dir '/tv_rgb_' num2str(c) '.png'];
    depth_fname = [out_dir '/tv_depth_' num2str(c) '.raw'];

    imwrite(I_rgb, rgb_fname);
    copyfile(D_depth(i).name, depth_fname);
    
    c = c+1;
end

fprintf('Done!\n');