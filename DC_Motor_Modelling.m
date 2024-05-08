dt = 0.01;
t = 0:dt:10;

J = 0.01;
b = 0.1;
K = 0.01;
R = 1;
L = 0.5;
u=10;
A = [-b/J, K/J; -K/L,-R/L];
B = [0; 1/L];
C = [1, 0];
D = 0;

x0 = [0; 0];
xd0 = [0; 0];

x = zeros(2, length(t));
xd = zeros(2, length(t));
y = zeros(size(t));

%axis([0 10 0 0.3]);% xlim ylim
hold on
for i = 1:1:length(t)
    if i == 1
        x(:,i) = x0;
        xd(:,i) = A*x0+B*0; % Initial condition for u
        y(i) = C*x0 + D*0;   % Initial condition for u
    else          
        % Update the system state
        x(:,i) = x(:,i-1) + dt * xd(:,i-1);
        xd(:,i) = A * x(:,i) + B *u;
        y(i) = C * x(:,i);
      % plot(t(1:i), y(1:i), 'Color', 'r');
    end  
end
s = tf('s');
P_motor = K*u/((J*s+b)*(L*s+R)+K^2);
motorts=ss(P_motor);
stepplot(motorts,t);
plot(t(1:i), y(1:i), 'Color', 'r');
title('Motor transfer function with Ts=0.01s & U=10V');
ylabel('Speed (rad/s)');
legend('Frequency domain','Time domain')