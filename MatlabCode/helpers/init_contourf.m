function fig = init_contourf(titlename)

fig = figure("Units","inches", "Position",[1,1,6,5]);hold on;
ax = gca;
ax.FontSize = 12;
ax.FontName = "Times New Roman"; 

title(titlename,'Interpreter', 'latex',"FontSize",15)

% might change to others later...
xlabel("K_{shoe}(N/m)")
ylabel("max compression (m)")

colorbar
end