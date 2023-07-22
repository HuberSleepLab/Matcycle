# Matcycle
 
 This is a repository of functions that detect EEG oscillation bursts based on the shape and periodicity of the signal. It is a MATLAB implementation of the cycle-by-cycle analysis outlined by [Cole & Voytek, 2019](https://journals.physiology.org/doi/full/10.1152/jn.00273.2019) originally created in [python](https://github.com/bycycle-tools/bycycle).


It was first used in *How and when EEG reflects changes in neuronal connectivity due to time awake*, by Snipes et al. 2023, iScience, applied in the repository [Theta_Bursts](https://github.com/snipeso/Theta_Bursts).

## How it works
![Flowchart](docs/flowchart.jpg)

For more details, see [Snipes et al. (2023)](https://doi.org/10.1016/j.isci.2023.107138).


## How to use

See [Example.m](Example.m).

1. Filter clean EEG data into narrow overlapping bands
2. Run `cycy_detect_bursts()` to get a struct with all the detected bursts in the EEG recording.
3. Run `cycy_aggregate_bursts()` to aggregate bursts in different channels overlapping in time by phase coherence, or `aggregateBurstsByFrequency()` to aggregate bursts by burst frequency (recommended).
4. Run `cycy_plot_all_bursts()` to see how well the detection went.

Optional:
4. Run `cycy_burst_shape_properties()` then `cycy_burst_averages()` to get all sorts of properties of the reference burst (the longest from those aggregated across channels), like how peaky it is
5. Run `cycy_classify_bursts_shape()` to sort bursts into shapes, like "sawtooth" or "sinusoid".


## How to adapt
Modify the example script burst thresholds, and run the lines under `%DEBUG`. It will apply the burst detection to a single channel, then plot it, from which you can see how well it does.
