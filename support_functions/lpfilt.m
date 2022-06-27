function filtData = lpfilt(Data, fs, PassFrq)
% filters data optimally when around 3-20 Hz. 
% part of Matcycle 2022 by Sophia Snipes. Filter by Sven Leach.

method = 'cheby2';
type = 'lowpassiir';
srate = fs;
StopFrq = PassFrq+1; % not perfect, but easy to understand
PassRipple = 0.1;
StopAtten = 60;

HiPassFilt = getfilt(type, method, srate, PassFrq, StopFrq, PassRipple, StopAtten);
filtData = filtfilt(HiPassFilt, double(Data'))';