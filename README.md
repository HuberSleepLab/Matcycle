# Matcycle
 
This is a MATLAB implementation of the procedure outlined by [Cole & Voytek, 2019](https://journals.physiology.org/doi/full/10.1152/jn.00273.2019) originally created in [python](https://github.com/bycycle-tools/bycycle).
It was first published in [How and when EEG reflects changes in neuronal connectivity due to time awake](), Snipes et al. 2023, iScience, applied in the repository [Theta_Bursts](https://github.com/snipeso/Theta_Bursts).

## How to use
See "Example.m".

1. Filter clean EEG data into narrow overlapping bands
2. Run `getAllBursts()` to get a structure with all the detected bursts in the EEG recording.
3. Run `aggregateBursts()` to aggregate bursts in different channels overlapping in time by phase coherence, or `aggregateBurstsByFrequency()` to aggregate bursts by burst frequency (recommended).
4. Run `PreviewBursts()` to see how well the detection went.

Optional:
4. Run `burstPeakProperties()` then `meanBurstPeakProperties()` to get all sorts of properties of the reference burst (the longest from those aggregated across channels), like how peaky it is
5. Run `classifyBursts()` to sort bursts into shapes, like "sawtooth" or "sinusoid".
