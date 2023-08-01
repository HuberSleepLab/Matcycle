function EEG = simulate_eeg(Channels, Seconds, fs, bpfilter, hpStopfrq)
% Generates a fake EEG signal without any oscillations, to see how many
% false positives get generated.
% Channels: number of "channels" to generate
% Seconds: duration in seconds of the recording
% fs: sampling rate
% bpfilter: [high-pass, low-pass] frequencies to filter signal at

% I found the code for this in MATLAB community exchange posts, but can't
% find the source again. Just know that I didn't write it, and someone
% cleverer then me is to thank.

% Part of Matcycle 2022, by Sophia Snipes.

Scale = 50000;

nPoints = fs*Seconds;

EEG = struct();
EEG.data = nan(Channels, nPoints);
EEG.srate = fs;

for Indx_Ch = 1:Channels

    % generate fake 1/f curve in the frquency domain
    c = linspace(1, fs, nPoints/2);
    S = 1./c; 
    S(nPoints/2+1:nPoints)=flip(S);

    % scramble the phases (imaginary part) to add noise
    S=S.*exp(1i*2*pi*rand(1, nPoints));
    S(1)=0;

    % convert to time domain
    Signal = real(ifft(S));

    % filter
    if exist('bpfilter', 'var') && ~isempty(bpfilter)
        Signal = cycy.cycy.utils.highpass_filter(Signal, fs, bpfilter(1), hpStopfrq);
        Signal = lowpass_filter(Signal, fs, bpfilter(2));

    end

    EEG.data(Indx_Ch, :) = Signal;
end


% scale all values up, so that it's in approximately the same range as EEG
% microvolts
EEG.data = EEG.data*Scale;
EEG.filename = 'null';
[EEG.nbchan, EEG.pnts] = size(EEG.data);
EEG.trials = 1;
EEG.xmin = 0;
EEG.xmax = EEG.pnts/EEG.srate;
EEG.times = linspace(0, EEG.xmax, EEG.pnts);
EEG.chanlocs = [];
EEG.event = [];
