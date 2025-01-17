clearvars j1 j2 j3 b1 b2 b3;

u1 = memmapfile('u.txt', 'Writable', true,'Format','int8');
m1 = memmapfile('m1.txt', 'Writable', true,'Format','int8');
m2 = memmapfile('m2.txt', 'Writable', true,'Format','int8');
m3 = memmapfile('m3.txt', 'Writable', true,'Format','int8');
b1 = memmapfile('buffer1.txt', 'Writable', true,'Format','int8');
b2 = memmapfile('buffer2.txt', 'Writable', true,'Format','int8');
b3 = memmapfile('buffer3.txt', 'Writable', true,'Format','int8');
wait = memmapfile('wait.txt', 'Writable', true,'Format','int8');

for i = 1:1:length(b1.Data)
	b1.Data(i) = 48;
	b2.Data(i) = 48;
	b3.Data(i) = 48;
end

for i = 1:1:length(wait.Data)
	wait.Data(i) = 48;
end

for i = 1:1:length(u1.Data)
	u1.Data(i) = 48;
	m1.Data(i) = 48;
	m2.Data(i) = 48;
	m3.Data(i) = 48;
end

disp('values have been reset');
