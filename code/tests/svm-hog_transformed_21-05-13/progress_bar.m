N = 3053;
num_bars = 10;
count = 1;

simple_progress_bar(N);
for i = 1:N
   % 1 operation
   for j = 1:100
       repmat([1:10],100,20);
   end
   simple_progress_bar;
end