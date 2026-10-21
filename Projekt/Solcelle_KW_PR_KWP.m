

%Okay, først angives anlæggesstørrelse i kWp, som en variabel vi altid kan
%ændre i:
kWp_installeret = 650; 

%Indlæser nu vores data fra excelfilen:
data = readtable('PV_clean.xlsx', Sheet='PV_data');

%Udtrækker den specifikke effekt i det her tilfælde P_W_per_kWp og ganger
% med 1000 for at få min enhed i Watt:
P_tot_W = data.P_W_per_kWp * kWp_installeret;

%Skal have en tidtager, som gøres over hver time i sekunder eftersom
%data er opdelt i time ark:
T_time = 0.2; %Simuleret tid pr time [S]
tid_sek = (0:height(data)-1)' * T_time;

%Opretter et timeseries-objekt, som simulink kan forstå:
pv_signal = timeseries(P_tot_W,tid_sek);