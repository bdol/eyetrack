function I = convert_image(fName)

fp=fopen(fName, 'rb');
d = fread(fp, prod([640 480 3]));
red = d(1:3:end);
green = d(2:3:end);
blue = d(3:3:end);
red = reshape(red,[640 480]);
blue = reshape(blue,[640 480]);
green = reshape(green,[640 480]);

im = zeros(640, 480, 3);
im(:,:,1) = red;
im(:,:,2) = green;
im(:,:,3) = blue;
im = im./255;
im_image = zeros(480, 640, 3);
im_image(:,:,1) = im(:,:,1)';
im_image(:,:,2) = im(:,:,2)';
im_image(:,:,3) = im(:,:,3)';

I = im_image;

fclose(fp);

end