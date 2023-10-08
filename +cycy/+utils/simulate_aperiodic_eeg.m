function [Data, t] = simulate_aperiodic_eeg(Slope, Intercept, Duration, SampleRate)
arguments
    Slope = -2;
    Intercept = 2;
    Duration = 30; % seconds
    SampleRate = 250;
end

nPoints = Duration*SampleRate;
Frequencies = SampleRate*(0:(nPoints/2))/nPoints;

Power = Slope*Frequencies(1:nPoints/2+1)+Intercept;
% Phase = 2*pi*rand(1, numel(Power))-pi;
% Phase = 2*pi*rand(1, numel(Power));

% Complex = exp(Power).*(cos(Phase)+1i*sin(Phase));
% Complex = exp(Power).*exp(1i*2*pi*rand(1, numel(Power)));
Complex = exp(Power);
Complex2 = cat(2, Complex, flip(Complex(2:end-1)));
Complex2 = Complex2.*exp(1i*2*pi*rand(1, numel(Complex2)));
Complex2(1) = 0;
%
% % generate fake 1/f curve in the frquency domain
% c = linspace(1, fs, nPoints/2);
% S = 1./c;
% S(nPoints/2+1:nPoints)=flip(S);
%
% % scramble the phases (imaginary part) to add noise
% S=S.*exp(1i*2*pi*rand(1, nPoints));
% S(1)=0;

% convert to time domain
Signal = real(ifft(Complex2));
% figure;plot(Signal)
