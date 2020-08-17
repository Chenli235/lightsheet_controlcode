% output_data = [4*ones(4000,1);4*ones(4000,1)];
% s = daq.createSession('mcc');
% addAnalogOutputChannel(s,'Board1','Ao0','Voltage');
% queueOutputData(s,output_data);
% startForeground(s)
% release(s)

% clear s
% s = daq.createSession('mcc');
% addAnalogOutputChannel(s,'Board0','ao0','Voltage');
% % outputData = 1*sin(linspace(-30,30,5000))+1.8;
% outputData = [3*ones(2000,1);0*ones(2000,1);3*ones(1500,1);0*ones(500,1)];
% queueOutputData(s,outputData);
% startForeground(s);
% release(s);

pathToCfgFile = 'C:\Program Files\Micro-Manager-1.4\configuration_05302019.cfg';
[mmc] = InitiateHardware(pathToCfgFile); 

