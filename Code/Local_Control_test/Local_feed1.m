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
power = str2double(out{2}(strcmp('line_speed',out{1})));
F1addr = char(out{2}(strcmp('Feed1',out{1})));
T_F1 = str2double(out{2}(strcmp('T_F1',out{1})));
Fthreshold = str2double(out{2}(strcmp('Fthreshold',out{1})));	
nxtF1 = COM_OpenNXTEx('USB', F1addr);

%activate sensors
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

%calculate the background light in the room. Further measurements will be measured as a difference to this.
currentLight3 = GetLight(SENSOR_3, nxtF1);

%feed all the pallets or until told to stop.
feedPallet(nxtF1, SENSOR_1, MOTOR_A); %so that feed starts immediately
b1.Data(1) = b1.Data(1) + 1;
tic;
k=0;
while (k<12) && (fstatus.Data(1) == 49) 
	if (toc >= T_F1) %true if it's time to feed
		if b1.Data(1) == 48
			b1.Data(1) = b1.Data(1) + 1;
			feedPallet(nxtF1, SENSOR_1, MOTOR_A);
			k=k+1;
			tic %set timer for next pallet
		
		elseif b1.Data(1) < 48+n
                      
			movePalletSpacing(400, MOTOR_B, power, nxtF1); %move pallet already on feed line out the way
			feedPallet(nxtF1, SENSOR_1, MOTOR_A);
			k=k+1;
			clear toc
			tic %set timer for next pallet
			b1.Data(1) = b1.Data(1) + 1;
				
		elseif b1.Data(1) == 48+n
			disp(['cannot feed there are ',num2str(b1.Data(1)),' pallets on feed line']);
			entry = 'Buffer exceeded on feed 1';
			errorlogID = fopen('errorlog.txt', 'a');
			if errorlogID == -1
			  error('Cannot open log file.');
			end
			fprintf(errorlogID, '%s: %s\n', datestr(now, 0), entry);
			fclose(errorlogID);
			fstatus.Data(1)=50;
			
		else
			disp(['error, there are ',num2str(b1.Data(1)),' pallets on feed line']);
			break;
		end
	end
	switch b1.Data(2)
        case 48
			switch b1.Data(1)
				case 48
					pause(0.1);
				case 49
					movePalletPastLSfeed(MOTOR_B, power, nxtF1, SENSOR_3, 6, Fthreshold);
					b1.Data(1) = b1.Data(1) - 1;
			
                case 50
                	movePalletSpacing(500, MOTOR_B, power, nxtF1);
                	pause(1);
					b1.Data(1) = b1.Data(1) - 1;
					movePalletSpacing(450, MOTOR_B, -power, nxtF1); %move pallet back on feed line so two can fit
					%if n = 1 then this should never execute
					
				otherwise
					disp(['error, there are ',num2str(b1.Data(1)),' pallets on feed line']);
					break;
			end
			
        case 49
		disp('waiting for pallet on transfer line');
        disp(['transfer buffer = ', num2str(b1.Data(2))]);
        disp(['feed buffer = ', num2str(b1.Data(1))]);
        disp(' ');
        pause(0.3);
	end
	
	pause(0.2)  %to avoid update error
end

disp('Feed 1 STOPPED')
clear b1;
CloseSensor(SENSOR_1, nxtF1);
CloseSensor(SENSOR_3, nxtF1);
COM_CloseNXT(nxtF1);
quit;			