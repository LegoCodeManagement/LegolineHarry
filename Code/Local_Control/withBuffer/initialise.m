j1 = memmapfile('junction1.txt', 'Writable', true);
j2 = memmapfile('junction2.txt', 'Writable', true);
j3 = memmapfile('junction2.txt', 'Writable', true);
b1 = memmapfile('buffer1.txt', 'Writable', true);
b2 = memmapfile('buffer2.txt', 'Writable', true);
b3 = memmapfile('buffer2.txt', 'Writable', true);

b1.Data(1) = 0, b1.Data(2) = 0;
b2.Data(1) = 0, b2.Data(2) = 0;
b3.Data(1) = 0, b3.Data(2) = 0;
j1.Data(1) = 0;
j1.Data(1) = 0;
j1.Data(1) = 0;

disp('values have been reset');