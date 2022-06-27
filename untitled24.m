close all
clear
clc

fs = 250;
% L = 60*10;
L = fs*10;
% f=0:1/fs:1-1/fs;
c = linspace(1, fs, L/2);
freqs = fs*(0:(L/2))/L;
% S=1./sqrt(c);
S = 1./c;
freqs = freqs(1:end-1);
figure;plot(freqs, S)


S(L/2+1:L)=flip(S);
S=S.*exp(j*2*pi*rand(1, L));
figure
Power = abs(S);
plot(freqs, Power(1:L/2))
S(1)=0;

t = linspace(0, L/fs, L);
figure
Signal = real(ifft(S));
plot(t, Signal)


fSignal = hpfilt(Signal, fs, 2);
fSignal = lpfilt(fSignal, fs, 40);
hold on;plot(t, fSignal)
% pwelch(fSignal)

%%
% fs = 1000;            % Sampling frequency                    
T = 1/fs;             % Sampling period       
% L = 1500;             % Length of signal
t = (0:L-1)*T;        % Time vector


% S = 0.7*sin(2*pi*50*t) + sin(2*pi*120*t);
% fSignal = S + 2*randn(size(t));

figure
plot(1000*t(1:50),fSignal(1:50))
title('Signal Corrupted with Zero-Mean Random Noise')
xlabel('t (milliseconds)')
ylabel('X(t)')
Y = fft(fSignal);

P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);
c = fs*(0:(L/2))/L;
figure
plot(c,P1) 
title('Single-Sided Amplitude Spectrum of X(t)')
xlabel('f (Hz)')
ylabel('|P1(f)|')