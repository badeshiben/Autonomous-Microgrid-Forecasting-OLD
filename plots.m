% resource plots 


%Building loads
% data = xlsread('Building_Loads.xlsx', '032720-032820');
% %data = xlsread('20200105_to_0111_Building_Loads.xlsx', 'Sheet1');
% figure(1)
% plot(data(:,1), data(:,2))
% hold on
% plot(data(:,1), data(:,3))
% legend('real', 'reactive')
% xlabel('m')
% ylabel('W')
% 
%M2 wind speed, using 50m height
data = xlsread('WS.xlsx', '121916-122016');
figure(2)
WS = data(:,2)*(50/36.6)^0.14;
plot(data(:,1), WS)
legend('WS')
xlabel('m')
ylabel('m/s')

%M2 GHI only problem is that 1MW PV array is attached, so daytime data
%isn't good. Could try to correct it based on that day's GHI data...but
%that's hard.
% data = xlsread('GHI.xlsx', '082120-082220');
% figure(3)
% WS = data(:,2)*(50/36.6)^0.14;
% plot(data(:,1), WS)
% legend('WS')
% xlabel('m')
% ylabel('m/s')
