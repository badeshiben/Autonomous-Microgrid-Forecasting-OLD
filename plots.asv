% plots 
loads = xlsread('2021_07_22_Building_Loads.xlsx', 'Sheet1');

figure(1)
plot(loads(:,1), loads(:,2))
hold on
plot(loads(:,1), loads(:,3))
legend('real', 'reactive')
xlabel('m')
ylabel('W')