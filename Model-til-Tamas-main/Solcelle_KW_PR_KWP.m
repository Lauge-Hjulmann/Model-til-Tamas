

%Okay, først angives anlæggesstørrelse i kWp, som en variabel vi altid kan
%ændre i:
kWp_installeret = 650; % Antaglse for nu

%Indlæser nu vores data fra excelfilen:
data = readtable('PV_clean.xlsx', Sheet='PV_data');
PV_pr_kWp = data.P_W_per_kWp;

%Gennemsnit produktion af solcelle pr time over et døgn over et år. Taget
%fra første model:
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

%Effekt for hele anlægget i watt:
P_pv_W = avg_sol * kWp_installeret;

%Skal have en tidtager, som gøres over hver time i sekunder eftersom
%data er opdelt i time ark:
T_time = 0.2; %Simuleret tid pr time [S]
tid_24 = [0:23]' * T_time;

%Opretter et timeseries-objekt, som simulink kan forstå:
pv_signal = timeseries(P_pv_W, tid_24);

V_nom = 230 % Den nomnielle spæding mellem fase og jord som er 230V

E_batt_Wh = 1e3;   % batteriets kapacitet [Wh], her 1 MWh
SOC0      = 0.1;   % start-ladning (10 %)