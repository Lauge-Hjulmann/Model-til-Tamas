
% Første step er at opsætte fabrikkens last:
P_max_fabrik = 650000; % I Watt (Find præcise max effekt senere)
pf_fabrik = 0.85;      % Effektfaktor indtil videre, men er lagging


n = numel(tid_24); %Anvendes 
Profil_pu = ones(n,1);  %Står for Per unit som går fra 0-1 og afgøre hvor
% meget af fabrikkens maximale forbrug den bruge i den bestemte time,
% Lige nu konstant 1 pu, men senere når data fra fabrikken indsættes vil
% den variere i forhold til hvornår på døgnet.

P_last_W = gennemsnit(:)*1000;
tid_24 = (0:23)' * T_time;

%Last signal 1 da det er til første fabrik:
last_signal1 = timeseries(P_last_W, tid_24);
 