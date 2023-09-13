# Matcycle
 
 This is a repository of functions that detect EEG oscillation bursts based on the shape and periodicity of the signal. It is a MATLAB implementation of the cycle-by-cycle analysis outlined by [Cole & Voytek, 2019](https://journals.physiology.org/doi/full/10.1152/jn.00273.2019) originally created in [python](https://github.com/bycycle-tools/bycycle).


It was first used in *How and when EEG reflects changes in neuronal connectivity due to time awake*, by Snipes et al. 2023, iScience, applied in the repository [Theta_Bursts](https://github.com/snipeso/Theta_Bursts). It has since been substantially re-formatted (different variable names, functions, etc.) to work as a matlab package and be more user friendly.

## How it works
![Flowchart](docs/flowchart.jpg)

For more details, see [Snipes et al. (2023)](https://doi.org/10.1016/j.isci.2023.107138).


### First time setup
1. Add the Matcycle folder to the MATLAB paths. Either:
  - run `addpath(fullfile({path}, 'Matcycle'))`
  - Using the GUI, in Home > Set path > add folder (N.B. don't use "add subfolers")

### How to use

See example script [SingleBandExample.m](/examples/SingleBandExample.m) on how to apply burst detection on a single channel with a single set of criteria. See example script [MultiChannelExample.m](/examples/MultiChannelExample.m) to see how to apply multiple sets of burst criteria, multiple frequency bands of interest, to multiple channels.

Matcycle is formatted as a MATLAB [package](https://ch.mathworks.com/help/matlab/matlab_oop/scoping-classes-with-packages.html), so to the main call the main functions you use `cycy.{function}()`, and to call the support functions in the subfolders you use `cycy.{folder}.{function}()`. 


# Glossary

- Data needs to be both **broadband** filtered, where the various EEG features are generally recognizable, and **narrowband** filtered in the frequency range of interest for a specific burst.
- EEG data can be **original** and **inverted** (multiplied by -1) so that burst detection is run both focusing on the negative and positive peaks. With mu-shaped rhythms, this makes a difference.
- **zero crossings** (of narrowband data)
- **peaks**: max/min between zerocrossings in the broadband data
- **falling edge** and **rising edge** of a cycle
- **cycles**: a single oscillation, going from positive to positive peak, centered on the negative peak
- **properties**: of cycles (frequency, ratio of falling/rising edges, etc.)
- **criteria**: conditions the properties of each cycle has to meet to make it into a burst. Each criteria indicates a threshold, and the cycle has to have a property above that value to be part of a burst.
  - criteria can also be booleans and ranges
- **criteria set**: a set of criteria that have to all be fullfiled for cycles to be included in a burst
- **burst**: set of consecutive cycles that match all criteria in a given criteria set in a single channel
- **burst cluster**: set of bursts that overlap in time across multiple channels with similar frequencies


## Coding conventions
- function names are `snake_case`
- Variable names are `CamelCase`
- The path of folders should be called `ImportantDataDir`
- The path of a file should be called `DataPath`
- indexes should be `idxThisAndThat`
