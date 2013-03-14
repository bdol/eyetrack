function show_outline(I, D)

xres = 1280; yres = 1024;
D(D>0) = 1;
imshow(D);
E = edge(D, 'canny');
E = imresize(E, [yres xres]);
r = I(:, :, 1);
g = I(:, :, 2);
b = I(:, :, 3);
r(E>0) = 0;
g(E>0) = 0;
b(E>0) = 255;
I(:, :, 1) = r;
I(:, :, 2) = g;
I(:, :, 3) = b;
imshow(I);

end