function plot_corresp(C, fstring)

for j=1:size(C, 1)
    plot(C(j, 1), C(j, 2), fstring); hold on;
end

end