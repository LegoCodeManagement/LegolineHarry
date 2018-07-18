addpath RWTHMindstormsNXT;
%establish memory map to status.txt.
fstatus = memmapfile('status.txt', 'Writable', true, 'Format', 'int8');
fstatus.Data(11) = 49;
b3 = memmapfile('buffer3.txt', 'Writable', true, 'Format', 'int8');

%open config file and save variable names and values column 1 and 2
%respectively.
config = fopen('config.txt','rt');
out = textscan(config, '%s %s');
fclose(config);
%retrieve parameters
power = str2double(out{2}(strcmp('SPEED_F',out{1})));
F3addr = char(out{2}(strcmp('Feed3',out{1})));
T_F3 = str2double(out{2}(strcmp('T_F3',out{1})));
nxtF3 = COM_OpenNXTEx('USB', F3addr);

OpenSwitch(SENSOR_1, nxtF3);
OpenLight(SENSOR_3, 'ACTIVE', nxtF3);

%signal that this module is ready
fstatus.Data(11) = 50;
disp('FEED 3');
disp('waiting for ready signal');
%wait for ready sign so that all matlab instances start simultaneously
while fstatus.Data(1) == 48
    pause(0.1);
end

currentLight3 = GetLight(SENSOR_3, nxtF3);

toc = T_F + 1; %start with a number greater than T_F so that feed starts immediately
k=0; 
while (k<12) && (fstatus.Data(1) == 49)
	if toc > T_F
		switch b3.Data(1)
			case 0
				feedPallet(nxtF3, SENSOR_1, MOTOR_A);
				
				if fstatus.Data(1) ~= 49
                    disp('break');
					break
				end
				
				k=k+1;
				clear toc
				tic %set timer for next pallet
				b3.Data(1) = b3.Data(1) + 1;
			
            case 1            
                movePalletSpacing(350, MOTOR_B, power, nxtF3);
                feedPallet(nxtF3, SENSOR_1, MOTOR_A);

                if fstatus.Data(1) ~= 49
                    disp('break');
					break
                end
				
				k=k+1;
				clear toc
				tic %set timer for next pallet
				b3.Data(1) = b3.Data(1) + 1;
							
			case  2
				disp(['cannot feed there are ',num2str(b3.Data(1)),' pallets on feed line']);
			
			otherwise
				disp(['error, there are ',num2str(b3.Data(1)),' pallets on feed line']);
				break;
		end
	end
	switch b3.Data(2)
		case 0
			switch b3.Data(1)
			
				case 0
					pause(0.1);
				case 1
					movePalletPastLightSensor(MOTOR_B, power, nxtF3, SENSOR_3, currentLight3, 6, 10);
					b3.Data(1) = b3.Data(1) - 1;
			
				case 2
					movePalletPastLightSensor(MOTOR_B, power, nxtF3, SENSOR_3, currentLight3, 6, 10);
					b3.Data(1) = b3.Data(1) - 1;
					movePalletSpacing(350, MOTOR_B, -power, nxtF3);
					
				otherwise
					disp(['error, there are ',num2str(b3.Data(1)),' pallets on feed line']);
					break;
			end
			
		case 1
		disp('waiting for pallet on transfer line');
        disp(['transfer buffer = ', num2str(b1.Data(2))]);
        disp(['feed buffer = ', num2str(b1.Data(1))]);
        disp(' ');
        pause(0.3);	
	end
	
	pause(0.2)  %to avoid update error
end

disp('Feed 3 STOPPED')
clear b3;
CloseSensor(SENSOR_1, nxtF3);
CloseSensor(SENSOR_3, nxtF3);
COM_CloseNXT(nxtF3);
			