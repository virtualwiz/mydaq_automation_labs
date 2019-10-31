Configure;
%% Connect to myDAQ
fprintf("Connecting to DAQ...\n");
dev = daq.getDevices;
assert(isequal(size(dev), [1, 1]), 'No devices or multiple devices found.');

%% Start session and add channels
daq_session = daq.createSession('ni');
addAnalogInputChannel(daq_session, DEVICE_ID, 0, 'Voltage');

%% Single scan
while 1
  data = daq_session.inputSingleScan;
  fprintf("Voltage: %f\n", data);
  pause(0.3);
end