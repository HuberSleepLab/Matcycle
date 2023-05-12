# Matcycle
 
This is a MATLAB implementation of the procedure outlined by [Cole & Voytek, 2019](https://journals.physiology.org/doi/full/10.1152/jn.00273.2019) originally created in [python](https://github.com/bycycle-tools/bycycle). It is just a collection of functions.

Uses EEGLAB structured EEG data. This is just a struct with fields: .data (ch x time matrix), .pnts (time size), .srate (sampling rate), .chanlocs (structure of channel information with fields .X, .Y, .Z with spatial coordinates).


For an example of how it's used, see [this repo](https://github.com/snipeso/2Process_Bursts/tree/main/Burst_Detection).

Basically, you need to have:
- EEG data, preferably nice and clean
- a structure of multiple EEGs, which are the narrow-band filtered data
- A structure with all the burst thresholds. There can be multiple entries there as well, if you have different sets of thresholds that work together
- a vector Keep_Points which indicates in which datapoints to actually look for bursts. This is to exclude noise timepoints.

Order in which to use functions.

1. Filter the clean EEG data into narrow bands.
2. Run "getAllBursts()" to identify all the bursts in the data in all the channels separately. Runs burst detection for each frequency band, on the signal and negative signal, and for the different sets of burst thresholds. 
3. Run "meanFreq()": just gets the average frequency for each burst, could have included it earlier, but oh well.
4. Run "aggregateBurstsByFrequency()": if you have a sufficient number of channels, this will find bursts that overlap in time and have the same frequency, and consider them the same burst.

Optionally, run also:
5. Run "burstPeakProperties()" gets properties of the cycle shapes, for later classification.
6. Run "meanBurstPeakProperties()": quite simply, averages the properties of all the cycles, so that there's just one value per burst
7. Run "classifyBursts()": classifies bursts based on cycle shape, into: Sn, sinusoidal;  Sq, square wave (flattish tops); Tr, triangle wave; Sw, sawtooth wave; Mu, mu wave; NM, notched mu wave; 