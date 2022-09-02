function filtData = hpfilt(Data, fs, PassFrq, StopFrq)
% filters data optimally when around 3-20 Hz.
% part of Matcycle 2022 by Sophia Snipes. Filter by Sven Leach.
%
% method = 'cheby2';
% type = 'highpassiir';
% srate = fs;
% StopFrq = PassFrq-1; % not perfect, but easy to understand
% PassRipple = 0.1;
% StopAtten = 60;

method = 'equiripple';

% FIR filter HP equiripple
type = 'highpassfir';
srate        = fs;

if ~exist('StopFrq', 'var') || isempty(StopFrq)
    StopFrq      = PassFrq-1;
end

PassRipple   = 0.04;
StopAtten    = 40;

HiPassFilt = getfilt(type, method, srate, PassFrq, StopFrq, PassRipple, StopAtten);
filtData = filtfilt(HiPassFilt, double(Data'))';
