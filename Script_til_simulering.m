T_load        = readtable('Energi_data_velux_clean.xlsx','Sheet','Timeserie');
T_pv          = readtable('PV_clean.xlsx');
Spotpris_load = readtable('Spotpris_2022_2023.xlsx');

%% Faste parametre
E_max             = 1000;   % kWh
SOC_min           = 0.2;
SOC_max           = 0.8;
P_net_max_eksport = 3000;   % kW

% Strategi-grænser (fundet i Script_strategi_sweep.m)
p_low_strategi  = 0.5544;   % kr/kWh, lad fra nettet under denne købspris
p_high_strategi = 0.6337;   % kr/kWh, aflad over denne købspris
%% simuleringsparametre
kWp_liste = [500:250:5000];
bat_liste = [0:250:2000];
E_max_liste = [0:250:5000];
resultater = [];

for kwp = kWp_liste
    for bat = bat_liste
        for emax = E_max_liste
            [cost_ref, cost_pv, cost_bat, spild, selvf] = simuler_energisystem( ...
                                T_load, T_pv, Spotpris_load, kwp, bat, emax, SOC_min, SOC_max, P_net_max_eksport, inf, p_low_strategi, p_high_strategi);     
      
   
       besparelse = cost_ref - cost_bat;
resultater = [resultater; kwp, bat, emax, besparelse, spild, selvf];
        end 
    end 
end

%% Repraesentativ stoerrelse til at finde strategi
kWp_test   = 5000;
P_bat_test = 600;    % kW, daekker typisk spids (95-percentil - median)
E_max_test = 7800;   % kWh, 600 kW * 13 timers median-varighed

%% 1. Økonomiske antagelser 
pris_pv_eur_kwp    = 460;   % eur./kWp, fra Energistyrelsens teknologikatalog
EUR_DKK = 7.46;
pris_pv_kr_kwp = pris_pv_eur_kwp * EUR_DKK;   % omregnet til kr./kWp
pris_bat_effekt   = 90;   % eur./kW, effektkomponent
pris_bat_effekt_kr = pris_bat_effekt * EUR_DKK % omregnet til kr./kW
pris_bat_energi   = 100;   % eur./kWh, energikomponent + andre omk.
pris_bat_energi_kr = pris_bat_energi * EUR_DKK % omregnet til kr./kWh
r                 = 0.07;  % afkastkrav (7 %, jf. Energistyrelsens rentabilitetsvurdering)
levetid           = 20;    % år
opex_pv_eur_kwp_aar   = 10.76;   % jeres fundne tal, PV, €/kWp/år 
opex_bat_eur_kw_aar   = 7.8;   % jeres fundne tal, batteri effekt, €/kW/år

opex_pv_kr_kwp_aar = opex_pv_eur_kwp_aar * EUR_DKK;    % kr./kWp/år
opex_bat_kr_kw_aar = opex_bat_eur_kw_aar * EUR_DKK;    % kr./kW/år
tabel = array2table(resultater, ...
    'VariableNames', {'kWp','P_bat_max','E_max','besparelse_kr','spild_kWh','selvforsyning'});
disp(tabel)

%% 2. CAPEX, OPEX, payback og NPV
kWp_col  = resultater(:,1);
Pbat_col = resultater(:,2);
Emax_col = resultater(:,3);
besp_col = resultater(:,4);

CAPEX = kWp_col*pris_pv_kr_kwp + Pbat_col*pris_bat_effekt_kr + Emax_col*pris_bat_energi_kr;

OPEX_aar = kWp_col*opex_pv_kr_kwp_aar + Pbat_col*opex_bat_kr_kw_aar;   % kr./år

netto_aar = besp_col - OPEX_aar;      % årlig nettogevinst efter drift

payback = CAPEX ./ netto_aar;
AF  = (1 - (1+r)^(-levetid)) / r;
NPV = -CAPEX + netto_aar * AF;

%% Validering: batteri sat til nul skal ikke ændre noget
[~, cost_pv_test, cost_bat_test, ~, ~] = simuler_energisystem( ...
    T_load, T_pv, Spotpris_load, 3000, 0, 0, 0.2, 0.8, 3000, inf, -inf, -inf);
fprintf('VALIDERING - forskel: %.4f kr (skal vaere ca. 0)\n', cost_pv_test - cost_bat_test);

%% 3. Saml det i tabellen
resultater = [resultater, CAPEX, payback, NPV];
tabel = array2table(resultater, 'VariableNames', ...
    {'kWp','P_bat_max','E_max','besparelse_kr','spild_kWh','selvforsyning','CAPEX','payback_aar','NPV'});
disp(tabel)

%% 4. Finder optimum
[~, i_bedst_npv] = max(tabel.NPV);
fprintf('Bedste NPV: kWp=%.0f, P_bat_max=%.0f kW, E_max=%.0f kWh, NPV=%.0f kr, payback=%.1f aar\n', ...
    tabel.kWp(i_bedst_npv), tabel.P_bat_max(i_bedst_npv), tabel.E_max(i_bedst_npv), ...
    tabel.NPV(i_bedst_npv), tabel.payback_aar(i_bedst_npv));

figure;
scatter(tabel.selvforsyning, tabel.NPV, 15, tabel.CAPEX, 'filled');
colorbar; xlabel('Selvforsyningsgrad'); ylabel('NPV [kr]');
title('Afvejning mellem selvforsyning og okonomi (farve = CAPEX)');

[sf_sorted, idx] = sort(tabel.selvforsyning);
npv_sorted = tabel.NPV(idx);
%% laver pareto
is_pareto = false(height(tabel),1);
loebende_max = -inf;
for i = 1:length(sf_sorted)
    if npv_sorted(i) >= loebende_max
        is_pareto(idx(i)) = true;
        loebende_max = npv_sorted(i);
    end
end

pareto_tabel = tabel(is_pareto, :);
disp(pareto_tabel)

hold on;
plot(pareto_tabel.selvforsyning, pareto_tabel.NPV, 'r-', 'LineWidth', 2);
legend('Alle kombinationer','Pareto-front');

mulige = pareto_tabel(pareto_tabel.selvforsyning >= 0.4, :);
bedste = mulige(mulige.NPV == max(mulige.NPV), :)



%% Gem resultater til grafer
save('resultater_tabel.mat', 'tabel', 'kWp_liste', 'bat_liste', 'E_max_liste');