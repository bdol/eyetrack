close all;
figure;
w = 10;
h = 9;
for i=1:h
    D = rdir(['~/Desktop/cropped_eyes/*/' num2str(i) '/*.png']);
    icount = 50;
    for j=1:w
        cont = 1;
        name = '';
        while cont
            if ~isempty(strfind(D(icount).name, '3_left'))
                name = D(icount).name;
                cont = 0;
            end
            icount = icount+1;
        end
        subplot(h, w, (i-1)*w+j);
        imshow(name);
        
    end
end
tightfig;