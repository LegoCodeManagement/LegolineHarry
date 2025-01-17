addpath RWTHMindstormsNXT;
%establish memory map to status.txt. 
fstatus = memmapfile('status.txt', 'Writable', true, 'Format', 'int8');
fstatus.Data(3) = 49;
m1 = memmapfile('m1.txt', 'Writable', true, 'Format', 'int8');

%open config file and save variable names and values column 1 and 2
%respectively.
cd ../
config = fopen('config.txt','rt');
cd([pwd,filesep,'Local_Control']);
out = textscan(config, '%s %s');
fclose(config);
%retrieve parameters
power = str2double(out{2}(strcmp('line_speed',out{1})));
M1addr = char(out{2}(strcmp('Main1',out{1})));
M1delay = str2double(out{2}(strcmp('M1delay',out{1})));	
Mthreshold = str2double(out{2}(strcmp('Mthreshold',out{1})));	
%open connection and activate sensors
nxtM1 = COM_OpenNXTEx('USB', M1addr);
OpenLight(SENSOR_1, 'ACTIVE', nxtM1);
OpenLight(SENSOR_2, 'ACTIVE', nxtM1);


mainline = NXTMotor(MOTOR_A,'Power',-power,'SpeedRegulation',false);
fstatus.Data(3) = 50;
disp('MAINLINE 1');
disp('waiting for ready signal');
%wait for ready sign so that all matlab instances start simultaneously
while fstatus.Data(1) == 48
    pause(0.5);
end
disp('Main 1 has started!')
ambientLight1 = GetLight(SENSOR_1, nxtM1);
mainline.SendToNXT(nxtM1);
%one timer for each pallet.

clearPalletM = [timer('TimerFcn', 'm1.Data(1) = m1.Data(1) - 1;', 'StartDelay', M1delay);
                timer('TimerFcn', 'm1.Data(1) = m1.Data(1) - 1;', 'StartDelay', M1delay);
                timer('TimerFcn', 'm1.Data(1) = m1.Data(1) - 1;', 'StartDelay', M1delay);
                timer('TimerFcn', 'm1.Data(1) = m1.Data(1) - 1;', 'StartDelay', M1delay);
                timer('TimerFcn', 'm1.Data(1) = m1.Data(1) - 1;', 'StartDelay', M1delay);
                timer('TimerFcn', 'm1.Data(1) = m1.Data(1) - 1;', 'StartDelay', M1delay);
                timer('TimerFcn', 'm1.Data(1) = m1.Data(1) - 1;', 'StartDelay', M1delay);
                timer('TimerFcn', 'm1.Data(1) = m1.Data(1) - 1;', 'StartDelay', M1delay);
                timer('TimerFcn', 'm1.Data(1) = m1.Data(1) - 1;', 'StartDelay', M1delay);
                timer('TimerFcn', 'm1.Data(1) = m1.Data(1) - 1;', 'StartDelay', M1delay);
                timer('TimerFcn', 'm1.Data(1) = m1.Data(1) - 1;', 'StartDelay', M1delay);
                timer('TimerFcn', 'm1.Data(1) = m1.Data(1) - 1;', 'StartDelay', M1delay);
                timer('TimerFcn', 'm1.Data(1) = m1.Data(1) - 1;', 'StartDelay', M1delay);
                timer('TimerFcn', 'm1.Data(1) = m1.Data(1) - 1;', 'StartDelay', M1delay);
                timer('TimerFcn', 'm1.Data(1) = m1.Data(1) - 1;', 'StartDelay', M1delay);
                timer('TimerFcn', 'm1.Data(1) = m1.Data(1) - 1;', 'StartDelay', M1delay);
                timer('TimerFcn', 'm1.Data(1) = m1.Data(1) - 1;', 'StartDelay', M1delay);
                timer('TimerFcn', 'm1.Data(1) = m1.Data(1) - 1;', 'StartDelay', M1delay);
                timer('TimerFcn', 'm1.Data(1) = m1.Data(1) - 1;', 'StartDelay', M1delay);
                timer('TimerFcn', 'm1.Data(1) = m1.Data(1) - 1;', 'StartDelay', M1delay);];


%If pallet detected at start of mainline, wait for pallet to be detected at end.
%If not detected before timeout, display error.

k=0;
array = ones(1,10)*GetLight(SENSOR_1,nxtM1);
avg = mean(array);
while (fstatus.Data(1) == 49)

	waitForDetectionExit(nxtM1,SENSOR_1,4,Mthreshold)
	
    k=k+1;
    disp(['pallet detected. Pallets on mainline 1: ',num2str(m1.Data(1)-48)]);
    start(clearPalletM(k));
    pause(0.2)
    m1.Data(1) = m1.Data(1) + 1;
    
    if fstatus.Data(1) ~= 49
        break
		disp('break');
    end

	pause(0.1); %prevents updating to quickly
end

mainline.Stop('off', nxtM1);
disp('Main 1 STOPPED');
clear m1;
delete(timerfind); %Remove all timers from memory
CloseSensor(SENSOR_1, nxtM1);
CloseSensor(SENSOR_2, nxtM1);
COM_CloseNXT(nxtM1);
quit;