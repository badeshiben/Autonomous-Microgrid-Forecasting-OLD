function targetSOC = targetSOC_from_forecast(forecast, U_rated, GHI_rated, Pmax_WT, Pmax_PV, U_min, nomSOC)
%Calculates the battery target SOC, based on the forecasted renewable
%surplus/defecit over the next three hours
%   Input: forecast matrix. First row is time, second GHI, third wind
%   speed, fourth load

U    = forecast(:,3);
GHI  = forecast(:,2);
load = forecast(:,4);

U=U.*(U>U_min);  % above cutin wind speed
P_WT = U.^3/U_rated^3*Pmax_WT;
P_PV = GHI/GHI_rated*Pmax_PV;
balance = sum((P_WT + P_PV - load)/60e3);  % W-min to kWh
dSOC = -balance*0.001;  % 0.001 change in target SOC per kWh
dSOC = min(max(dSOC, 0), 0.2)
targetSOC = nomSOC + dSOC;

end

