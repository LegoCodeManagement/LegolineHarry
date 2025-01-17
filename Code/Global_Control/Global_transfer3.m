addpath RWTHMindstormsNXT;

%establish memory map to status.txt. 
fstatus  = memmapfile('status.txt', 'Writable', true, 'Format', 'int8');
fstatus.Data(10) = 49;
m2 		 = memmapfile('m2.txt', 'Writable', true);
m3 		 = memmapfile('m3.txt', 'Writable', true);
b3 		 = memmapfile('buffer3.txt', 'Writable', true, 'Format', 'int8');
wait 	 = memmapfile('wait.txt', 'Writable', true);
priority = memmapfile('priority.txt', 'Writable', true);

global wait
global fstatus

%open config file and save variable names and values column 1 and 2 respectively.
cd ../
config = fopen('config.txt','rt');
cd([pwd,filesep,'Global_Control']);
out = textscan(config, '%s %s');
fclose(config);
power 		= str2double(out{2}(strcmp('line_speed',out{1})));
T3addr 		= char(out{2}(strcmp('Transfer3',out{1})));
T3angle 	= str2double(out{2}(strcmp('T3angle',out{1})));
T3delay 	= str2double(out{2}(strcmp('T3delay',out{1})));	
Tarmwait	= str2double(out{2}(strcmp('Tarmwait',out{1})));
Tthreshold  = str2double(out{2}(strcmp('Tthreshold',out{1})));

%open connection and activate sensors
nxtT3 = COM_OpenNXTEx('USB', T3addr);
OpenLight(SENSOR_3, 'ACTIVE', nxtT3);
OpenSwitch(SENSOR_2, nxtT3);
OpenLight(SENSOR_1, 'ACTIVE', nxtT3);
TransferArmReset(MOTOR_B, SENSOR_2, nxtT3, T3angle);

%signal that this module is ready
fstatus.Data(10) = 50;
disp('TRANSFER 3');
disp('waiting for ready signal');

%wait for ready sign so that all matlab instances start simultaneously
while fstatus.Data(1) == 48
    pause(0.1);
end

%detect ambient light in room
currentLight1 = GetLight(SENSOR_1, nxtT3);
currentLight3 = GetLight(SENSOR_3, nxtT3);

transferpallet3 = 51;
upstreampallet = 48;

%run until told to stop
while (fstatus.Data(1) == 49)
    if (abs(GetLight(SENSOR_1, nxtT3) - currentLight1) > 100) %triggers if pallet is detected
		b3.Data(2) = b3.Data(2) + 1;
		movePalletToLightSensor(MOTOR_A, -power, nxtT3, SENSOR_3, currentLight3, 10, Tthreshold);
		
		while (m3.Data(1) > 48) && (checkStop)
			pause(0.2);
			disp('mainline is busy')
		end
		
		while b3.Data(2) > 48
		
			if m2.Data(1) > 48
	
				if checkpriority(transferpallet3,m2.Data(1)) %
			
					wait.Data(3) = 49;						%tell upstream to stop
					addpallet(transferpallet3,'m3.txt')
                    TransferArmRun(MOTOR_B, nxtT3, 105);
				
					
				
					b3.Data(2) = b3.Data(2) - 1; 			%remove one pallet from transfer line section of buffer
					pause(Tarmwait);
					TransferArmReset(MOTOR_B, SENSOR_2, nxtT3, T3angle);
					wait.Data(3) = 48; 						%tell upstream to resume
		
				else
			
					while (m3.Data(1)>48) && (checkStop) %if there is delay between m1=m1+1 and u1=u1-1 then may clash.
						pause(0.1);
						disp('upstream is busy')
					end
				
				end
		
            else
                addpallet(transferpallet3,'m3.txt')
				TransferArmRun(MOTOR_B, nxtT3, 105);
			
				
			
				b3.Data(2) = b3.Data(2) - 1; 			%remove one pallet from transfer line section of buffer
				pause(Tarmwait);
				TransferArmReset(MOTOR_B, SENSOR_2, nxtT3, T3angle);	
			
			end
		end
    end
	pause(0.1);
end

disp('Transfer 3 STOPPED');
delete(timerfind);
clearvars m2 b3 m3;
CloseSensor(SENSOR_1, nxtT3);
CloseSensor(SENSOR_2, nxtT3);
CloseSensor(SENSOR_3, nxtT3);
COM_CloseNXT(nxtT3);
quit;