function H = findHomography(X1, X2)

N = size(X1, 1);
M = zeros(N*2, 9);
for i=0:2:2*N-1
   x = X1(i/2+1, 1);
   y = X1((i)/2+1, 2);
   xp = X2(i/2+1, 1);
   yp = X2(i/2+1, 2);
   
   M((i+1), 1) = x;
   M((i+1), 2) = y;
   M((i+1), 3) = 1;
   M((i+1), 4) = 0;
   M((i+1), 5) = 0;
   M((i+1), 6) = 0;
   M((i+1), 7) = -x*xp;
   M((i+1), 8) = -y*xp;
   M((i+1), 9) = -xp;
   M(i+2, 1) = 0;
   M(i+2, 2) = 0;
   M(i+2, 3) = 0;
   M(i+2, 4) = x;
   M(i+2, 5) = y;
   M(i+2, 6) = 1;
   M(i+2, 7) = -x*yp;
   M(i+2, 8) = -y*yp;
   M(i+2, 9) = -yp;
end

H = minimizeAx(M);
H = H./H(9);
H = reshape(H, 3, 3)';


end