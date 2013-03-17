for i = 0:14
    sprintf('Saving out image: %d\n',i);
    [rgb depth folder] = display_images(i);
    if(length(rgb)>0)
        imwrite(rgb, sprintf('%s\\Image_%d.png',folder, i), 'png');
    end
    if(length(depth)>0)
        imwrite(depth, sprintf('%s\\Depth_%d.png',folder, i), 'png');
    end
end