%Script_til_simulering;

Forbrug = T_load.Total_forbrug_kWh;

gennemsnit = zeros(24,1);

for time = 1:24;
    gennemsnit(time) = mean(Forbrug(time:24:end), 'omitnan');
end;

figure;
plot(1:24, gennemsnit, '-o');

xlabel('Time på døgnet');
ylabel('Gennemsnitligt forbrug [kWh]');
title('Gennemsnitligt elforbrug pr. time');
xticks(1:24);
grid on;

