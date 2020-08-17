s = daq.createSession('mcc');
s.DurationInSeconds = 5;

%ai0 = addAnalogInputChannel(s,'Board1','ai0','Voltage');
%ai0.TerminalConfig = 'SingleEnded';
ao0 = addAnalogOutputChannel(s,'Board1','ao0','Voltage');
%ao1 = addAnalogOutputChannel(s,'Board1','ao1','Voltage');
%output_data = [];
%queueOutputData(s.ao0,output_data);
%[data,timeStamps,triggerTime] = startForeground(s);
%plot(timeStamps,data),ylim([-5,5])

