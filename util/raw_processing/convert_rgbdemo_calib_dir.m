raw_dir = '~/Desktop/grab1';
out_dir = '~/Desktop/out';
D_rgb = rdir([raw_dir '/*/*/*/color.png']);
D_ir = rdir([raw_dir '/*/*/*/intensity.raw']);

fprintf('Converting images...\n');

c = 0;
for i=1:numel(D_rgb)
    I_rgb = imread(D_rgb(i).name);
    I_ir = convert_rgbdemo_raw(D_ir(i).name);
    
    rgb_fname = [out_dir '/rgb_' num2str(c) '.png'];
    ir_fname = [out_dir '/ir_' num2str(c) '.png'];
    imwrite(I_rgb, rgb_fname);
    imwrite(I_ir, ir_fname);
    
    c = c+1;
end

fprintf('Done!\n');