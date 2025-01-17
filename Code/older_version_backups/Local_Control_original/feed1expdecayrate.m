addpath RWTHMindstormsNXT;
%establish memory map to status.txt. 
fstatus = memmapfile('status.txt', 'Writable', true, 'Format', 'int8');
fstatus.Data(5) = 49;
b1 = memmapfile('buffer1.txt', 'Writable', true, 'Format', 'int8');

%open config file and save variable names and values column 1 and 2
%respectively.
config = fopen('config.txt','rt');
out = textscan(config, '%s %s');
fclose(config);
%retrieve parameters
power = str2double(out{2}(strcmp('SPEED_F',out{1})));
F1addr = char(out{2}(strcmp('Feed1',out{1})));
T_F1 = str2double(out{2}(strcmp('T_F1',out{1})));
nxtF1 = COM_OpenNXTEx('USB', F1addr);

OpenSwitch(SENSOR_1, nxtF1);
OpenLight(SENSOR_3, 'ACTIVE', nxtF1);

%signal that this module is ready
fstatus.Data(5) = 50;
disp('FEED 1');
disp('waiting for ready signal');
%wait for ready sign so that all matlab instances start simultaneously
while fstatus.Data(1) == 48
    pause(0.1);
end

currentLight3 = GetLight(SENSOR_3, nxtF1);

k=0; 
a = 0.05;
buffer1 = 0;
buffer2 = 0;
timer1 = tic;
timer2 = tic;

%feed first pallet
feedPallet(nxtF1, SENSOR_1, MOTOR_A);
b1.Data(1) = b1.Data(1) + 1;

while (k<12) && (fstatus.Data(1) == 49)
	if toc(timer1) > T_F1*exp(-a*toc(timer2))
		switch b1.Data(1)
    		case 0
    			timer1 = tic; %set timer for next pallet
    			b1.Data(1) = b1.Data(1) + 1;
				feedPallet(nxtF1, SENSOR_1, MOTOR_A);
				
				if fstatus.Data(1) ~= 49
                    disp('break');
					break
				end
								
				k=k+1;
			
            case 1     
            	timer1 = tic; %set timer for next pallet
				b1.Data(1) = b1.Data(1) + 1;      
                movePalletSpacing(350, MOTOR_B, power, nxtF1);
                feedPallet(nxtF1, SENSOR_1, MOTOR_A);

                if fstatus.Data(1) ~= 49
                    disp('break');
					break
                end
				
				k=k+1; 
				
            case 2
				disp(['cannot feed there are ',num2str(b1.Data(1)),' pallets on feed line']);
			
			otherwise
				disp(['error, there are ',num2str(b1.Data(1)),' pallets on feed line']);
				break;
		end
	end
	switch b1.Data(2)
        case 0
			switch b1.Data(1)
			
				case 0

				case 1
					movePalletPastLightSensor(MOTOR_B, power, nxtF1, SENSOR_3, currentLight3, 6, 10);
					b1.Data(1) = b1.Data(1) - 1;
			
                case 2 
					movePalletPastLightSensor(MOTOR_B, power, nxtF1, SENSOR_3, currentLight3, 6, 10);
					b1.Data(1) = b1.Data(1) - 1;
					movePalletSpacing(350, MOTOR_B, -power, nxtF1);
					
				otherwise
					disp(['error, there are ',num2str(b1.Data(1)),' pallets on feed line']);
					break;
			end
			
        case 1
		disp('waiting for pallet on transfer line');
        disp(['transfer buffer = ', num2str(b1.Data(2))]);
        disp(['feed buffer = ', num2str(b1.Data(1))]);
        disp(' ');
        pause(0.3);
	end
	
	pause(0.1)  %to avoid update error
end

disp('Feed 1 STOPPED')
clear b1;
CloseSensor(SENSOR_1, nxtF1);
CloseSensor(SENSOR_3, nxtF1);
COM_CloseNXT(nxtF1);
			