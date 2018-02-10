clear;
clc;
close all;

% data_afm = textread('C:\Users\AnderssonLab\Desktop\yufan\newData_groundTruth2.csv');
% data_afm = textread('C:\Users\AnderssonLab\Desktop\yufan\newData31_complete.csv');
%data_afm = textread('C:\Users\AnderssonLab\Desktop\yufan\newData13_complete.csv');

% data_afm = textread('C:\Users\AnderssonLab\Desktop\yufan\newData38_complete_a_141s.csv');

data_afm = textread('C:\Users\AnderssonLab\Desktop\yufan\newDataR.csv');



% offset_value = 0.17;
% offset_value = offset_value/256;
% offset_value_mtx1 = [0:1:255]*offset_value;
% 
% 
% offset_value = 0.22;
% offset_value = offset_value/256;
% offset_value_mtx2 = [0:1:255]*offset_value;


% data_afm = data_afm(find(data_afm(:,5)==4),:);

deflection_cutoff = 6;

a = find(abs(data_afm(:,4))<deflection_cutoff);
% a = find(abs(data_afm(:,8))<0.5);

data_afm = data_afm(a,:);
% 
% x_volt_start = 1;
% x_volt_end = 7;
% y_volt_start = 9;
% y_volt_end = 3;



x_volt_start = 0;
x_volt_end = 6;
y_volt_start = 0;
y_volt_end = 6;


% x_volt_start = -6;
% x_volt_end = 0;
% y_volt_start = -6;
% y_volt_end = 0;


% x_volt_start = 0;
% x_volt_end = 6;
% y_volt_start = -6;
% y_volt_end = 0;


% x_volt_start = -6;
% x_volt_end = 0;
% y_volt_start = 0;
% y_volt_end = 6;


% x_volt_start = -3;
% x_volt_end = 3;
% y_volt_start = -3;
% y_volt_end = 3;


% x_volt_start = -2;
% x_volt_end = 4;
% y_volt_start = -2;
% y_volt_end = 4;


% x_volt_start = -8;
% x_volt_end = -2;
% y_volt_start = -8;
% y_volt_end = -2;




x_pixel = 256;
y_pixel = 256;
x_increment = (x_volt_end-x_volt_start)/x_pixel;
y_increment = (y_volt_end-y_volt_start)/y_pixel;

total_value_map = zeros(x_pixel,y_pixel);
total_num_map = zeros(x_pixel,y_pixel);

m = length(data_afm);


for i = 1:m

    x_axis = data_afm(i,1);
    y_axis = data_afm(i,2);
    z_axis = data_afm(i,3);

    x_axis = floor((x_axis-x_volt_start)/x_increment)+1;
    y_axis = floor((y_axis-y_volt_start)/y_increment)+1;


    if x_axis>0 && x_axis<= x_pixel && y_axis>0 && y_axis<= y_pixel

        total_value_map(x_axis,y_axis) = z_axis + total_value_map(x_axis,y_axis);
        total_num_map(x_axis,y_axis) = total_num_map(x_axis,y_axis) + 1;

    end


end


% total_value_map = total_value_map./max(total_num_map,1);
total_value_map = total_value_map./total_num_map;

figure(1);
imshow(total_value_map, [min(min(total_value_map)) max(max(total_value_map))]);





data_mupath = textread('C:\Users\AnderssonLab\Desktop\yufan\sample locations\backup_a_upathlocations.txt');
a = length(data_mupath);
E = zeros(x_pixel,y_pixel);

for i = 1:a
    
    E(data_mupath(i,1),[data_mupath(i,2):data_mupath(i,2)+data_mupath(i,3)-1]) = 1; 


end

E = ones(x_pixel,y_pixel);

figure(2);
imshow(E, [0 1]);

pixelValue = E.*total_value_map;

figure(3);
imshow(pixelValue, [min(min(pixelValue)) max(max(pixelValue))]);


num_total = total_num_map.*E;
figure(4);
imshow(num_total, [0 200])


fake_image = pixelValue;
min_value = min(min(pixelValue));

for i = 1:x_pixel
    for j = 1:y_pixel


        if E(i,j) < 0.5 && num_total(i,j)<5

            fake_image(i,j) = min_value;

        end

    end
end


% for i = 1:x_pixel
%     
%     
%     fake_image(:,i) = fake_image(:,i) - offset_value_mtx2';
%     
% 
% end 
% 
% for i = 1:x_pixel
%     
%     
%     fake_image(i,:) = fake_image(i,:) - offset_value_mtx1;
%     
% 
% end    
% 

    
    
close all;

figure(5)
imshow(fake_image, [min(min(fake_image)) max(max(fake_image))]);



total_num_map_re = total_num_map.*E;


















