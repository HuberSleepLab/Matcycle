close all
fs = 250;
f=0:1/fs:1-1/fs;
S=1./sqrt(f);

S(end/2+2:end)=fliplr(S(2:end/2));
S=S.*exp(j*2*pi*rand(size(f)));
figure
plot(abs(S))
S(1)=0;

figure
plot(real(ifft(S)))