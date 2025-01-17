addpath RWTHMindstormsNXT;

%establish memory maps
fstatus = memmapfile('status.txt', 'Writable', true, 'Format', 'int8');
fstatus.Data(6) = 49;
m2 		= memmapfile('m2.txt', 'Writable', true, 'Format', 'int8');
wait 	= memmapfile('wait.txt', 'Writable', true);

global fstatus
global wait

%open config file and save variable names and values column 1 and 2 respectively.
cd ../
config = fopen('config.txt','rt');
cd([pwd,filesep,'Global_Control']);
out 	= textscan(config, '%s %s');
fclose(config);

%retrieve parameters
power 		= str2double(out{2}(strcmp('line_speed',out{1})));
M2addr 		= char(out{2}(strcmp('Main2',out{1})));
M2delay 	= str2double(out{2}(strcmp('M2delay',out{1})));
Mthreshold 	= str2double(out{2}(strcmp('Mthreshold',out{1})));		

%open connection and activate sensors
nxtM2 = COM_OpenNXTEx('USB', M2addr);
OpenLight(SENSOR_1, 'ACTIVE', nxtM2);
OpenLight(SENSOR_2, 'ACTIVE', nxtM2);

mainline = NXTMotor(MOTOR_A,'Power',-power,'SpeedRegulation',false);
fstatus.Data(6) = 50;
disp('MAINLINE 2');
disp('waiting for ready signal');

%wait for ready sign so that all matlab instances start simultaneously
while fstatus.Data(1) == 48
    pause(0.5);
end

mainline.SendToNXT(nxtM2);

array = ones(1,10)*GetLight(SENSOR_2,nxtM2);
stdarray = zeros(1,7);
stdavg = mean(stdarray);
ambient = array(1);

while (fstatus.Data(1) == 49)
	%tic
	[stdavg,avg,stdarray,array] = averagestd(nxtM2,SENSOR_2,stdarray,array);
	if stdavg > 10
		addpallet(m2.Data(1),'m3.txt')
		pause(0.01)
		removepallet('m2.txt')
		while (stdavg > 10) && (checkstop)
			pause(0.05)
			[stdavg,avg,stdarray,array] = averagestd(nxtM2,SENSOR_2,stdarray,array);
		end
		
		pause(0.08)
	end

	if wait.Data(3) == 49
		mainline.Stop('off', nxtM2);
		while wait.Data(3) == 49 && (checkStop)
			pause(0.2);
		end
		mainline.SendToNXT(nxtM2);
	end
	
	if m2.Data(1) == 48
	mainline.Stop('off', nxtM2);
		while m2.Data(1) == 48
			pause(0.2);
		end
	mainline.SendToNXT(nxtM2);
	end

	pause(0.1); %prevents updating to quickly
end

mainline.Stop('off', nxtM2);
disp('Main 2 STOPPED');
clear m2;
delete(timerfind);%Remove all timers from memory
CloseSensor(SENSOR_1, nxtM2);
CloseSensor(SENSOR_2, nxtM2);
COM_CloseNXT(nxtM2);
quit;