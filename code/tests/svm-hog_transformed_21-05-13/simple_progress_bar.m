function simple_progress_bar(varargin) %loop_time, N)

num_bars = 10;
persistent every_how_many_Ns;
persistent currentCount;
persistent startTime;
persistent loop_time;
persistent N;
if(nargin==1)
    % initialise
    N = varargin{1};
    currentCount = 0;
    every_how_many_Ns = round(N/num_bars);
    if(N<num_bars)
        every_how_many_Ns = N;
    end
    tic;
    fprintf(sprintf('\n=*'));
elseif(currentCount<1)
    loop_time = toc;
    currentCount = currentCount + 1;
else
    if(mod(currentCount, every_how_many_Ns)==0)
%        fprintf(sprintf('%.2f=',(loop_time/60)*(N - currentCount)));
        fprintf('=*');
    end
    currentCount = currentCount + 1;
end