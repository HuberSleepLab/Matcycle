function [Data, t] = simulate_aperiodic_eeg(Slope, Intercept, Duration, SampleRate)
arguments
    Slope = -2;
    Intercept = 2;
    Duration = 30; % seconds
    SampleRate = 250;
end

nPoints = Duration*SampleRate;
Frequencies = SampleRate*(0:(nPoints/2))/nPoints;

% Power = Slope*Frequencies(1:nPoints/2+1)+Intercept;
Power = Intercept+Slope*log(Frequencies(1:nPoints/2+1));

Complex = exp(Power);
Complex2 = cat(2, Complex, flip(Complex(2:end-1)));
Complex2 = Complex2.*exp(1i*2*pi*rand(1, numel(Complex2)));
Complex2(1) = 0;

% convert to time domain
Data = real(ifft(Complex2));
t = linspace(0, Duration, nPoints);
% figure;plot(Signal)
