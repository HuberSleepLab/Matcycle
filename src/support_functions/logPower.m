function Power = logPower(Power)

Power = log(Power);
Power(isinf(Power)) = nan;