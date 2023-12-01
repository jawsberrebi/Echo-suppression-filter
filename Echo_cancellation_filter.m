%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% Echo cancellation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; 
clear all;
close all;

[y, Fs] = audioread("Pa11.wav");

%%If we listen to the signal, we notice that the signal has been filtered
%%by an FIR filter of equation H(z) = 1 + alpha*z^-r.
%%This filter creates a delay (an echo) of one tap.
%%With the original signal (x(n) = s(n)), the output of this filter is:
%%y(n) = s(n) + alpha*s(n-r)
%%So we have, in the z domain:
%%H(z) = (S(z) + alpha*S(z)*z^-r)/S(z) = 1 + alpha*z^-r. r is the delay in
%%samples and alpha is the attenuation coefficient (between 0 and 1).
%%To cancel this echo, we can refilter y(n) by the inverse of the transfert
%%function: 1/H(z) = 1/(1 + alpha*z^-r). To calculate the value of r and
%%alpha, we have to do the autocorrelation of the signal.


%% Autocorrelation 
[Rmm,lags] = xcorr(y,'unbiased');

%%We keep the right part of the autocorrelation
Rmm = Rmm(lags>0);
lags = lags(lags>0);

%%We have to find the value of the amplitude of R(r) (the echo/delay peak)
%%and R(0) the central peak.

[R_r, dl] = findpeaks(Rmm,lags,'MinPeakHeight',0.01);                      %%Peak and lags of the echo/delay
R_0 = max(xcorr(y, 'unbiased'));                                           %%Maximum peak of the autocorrelation

%%Now, we have to find the value of alpha by finding an equation with R(r)
%%and R(0)
%%R(r) = E[(S(n) + alpha*S(n-r))*(S(n-r) + alpha*S(n-2r))]
%%R(r) = E[alpha*S(n-r)^2] = alpha*E[S(n-r)^2] = alpha*Ps (Ps is the power)
%%Ps = R(r)/alpha
%%R(0) = E[(s(n) + alpha*s(n-r))^2]
%%R(0) = E[s(n)^2 + 2*alpha*s(n)*s(n-r) + alpha^2*s(n-r)^2]
%%R(0) = E[s(n)^2 + alpha^2*s(n-r)^2] = E[s(n)^2] + alpha^2*E[s(n-r)^2]
%%R(0) = (1 + alpha^2)*Ps
%%We solve:
%%R(0) = (1 + alpha^2)*R(r)/alpha = 0
%%alpha^2*R(r) - alpha*R(0) + R(r) = 0

%% Computing of alpha
%%We find the roots of the equation, and we take the solution between 0 and 1
polynomial = [R_r -R_0 R_r];
roots = roots(polynomial);
alpha = roots(roots<1);
alpha = alpha(alpha>0);

%% Filtering
%%With for equation 1/(1 + alpha*z^-r) as explained before
y_filtered = filter(1,[1 zeros(1,dl-1) alpha], y);                          %%Then, we filter with the values found

%% Listening
%%Before:
%%sound(y, Fs);
%%After:
%%sound(y_filtered, Fs);

%% Plot
[Rmm_original_plot,lags_original_plot] = xcorr(y);
[Rmm_filtered_plot,lags_filtered_plot] = xcorr(y_filtered);

figure(1)
plot(lags_original_plot/Fs,Rmm_original_plot);
hold on;
plot(lags_filtered_plot/Fs,Rmm_filtered_plot);
legend('Original', 'After filtering');
xlabel('Lag (s)');
ylabel('Amplitude');
title('Autocorrelation of the original signal and after filtering');
grid on;

t = (0:length(y)-1)/Fs;                                                     %%Time axis 

figure(2)
plot(t, y);
hold on;
plot(t, y_filtered);
legend('Original', 'After filtering');
xlabel('Time (s)');
ylabel('Amplitude');
title('Original signal before and after filtering in the time domain');
grid on;
