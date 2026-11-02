T_load        = readtable('Energi_data_velux_clean.xlsx','Sheet','Timeserie');
% sheet og Timeserie er fanerne i filen

T_pv          = readtable('PV_clean.xlsx');


PV_pr_kWp = T_pv.P_W_per_kWp;
%sol indstrålign 


Forbrug  = T_load.Total_forbrug_kWh;   % positivt forbrug [kWh]
% kode definer p_load, ved først at gå i


avg_forbrug = zeros(24,1);


for dag = 1:365
    start_index = (dag-1)*24;
    %dag-1 tager højde for for matlab 1 indexing
    for m = 1:24
        prod_den_time = Forbrug(start_index + m);
        avg_forbrug(m) = avg_forbrug(m) + prod_den_time;
    end
end

avg_forbrug = avg_forbrug ./ 365

plot(1:24, avg_forbrug, '-o');
%x-akse , y-akse
xlabel('Tidspunkt [Klokkeslæt]')
ylabel('avg forbrug [kWh]')
title('Gennemsnitsforbrug over et år')
grid on;

%Gennemsnit pr time over et døgn
avg_sol = zeros(24,1);

for dag = 1:365
    start_index = (dag-1)*24;
    %dag-1 tager højde for for matlab 1 indexing
    for m = 1:24
        sol_den = PV_pr_kWp(start_index + m);
        avg_sol(m) = avg_sol(m) + sol_den;
    end
end
avg_sol = avg_sol ./ 365



plot(1:24, avg_sol, '-o')
%x-akse , y-akse
xlabel('Tidspunkt [Klokkeslæt]')
ylabel('Effekt pr solcelle kapacitet [W/kWp]')
title('Gennemsnitsforbrug over et år')
grid on

figure;

% Venstre y-akse: fabrikkens forbrug
yyaxis left
plot(1:24, avg_forbrug, '-o', ...
    'LineWidth', 1.5, 'MarkerSize', 5);
ylabel('Gennemsnitligt forbrug [kWh]');

% Højre y-akse: solindstråling/solcelleproduktion
yyaxis right
plot(1:24, avg_sol, '-s', ...
    'LineWidth', 1.5, 'MarkerSize', 5);
ylabel('Gennemsnitlig PV-produktion [W/kWp]');

xlabel('Tidspunkt [time på døgnet]');
title('Gennemsnitligt fabriksforbrug og PV-produktion');
xlim([1 24]);
xticks(1:24);
grid on;

legend('Fabrikkens forbrug', 'PV-produktion', ...
    'Location', 'best');