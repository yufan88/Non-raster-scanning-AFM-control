clear;
clc;
close all;

load('E_designed256MuPath35_8FOR14_1D2_1400_20ptg_1.mat');
data_afm = textread('C:\Users\AnderssonLab\Desktop\yufan\newData_designed256MuPath35_8FOR14_1D2_1400_20ptg_1_attempt1.csv');

x_pixel = 256;
y_pixel = 256;

x_volt_start = 0;
x_volt_end = 6;
y_volt_start = 0;
y_volt_end = 6;

deflection_cutoff = 9.5;

a = find(abs(data_afm(:,4))<deflection_cutoff);
data_afm = data_afm(a,:);


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

total_value_map = total_value_map./max(total_num_map,1);


figure(1)
imshow(total_value_map, [min(min(total_value_map)) max(max(total_value_map))])


total_value_map_real = total_value_map;
for i = 1:x_pixel
    for j = 1:y_pixel
        if E(i,j) < 0.5
            total_value_map_real(i,j) = 0;
        end
    end
end

x_11 = sum(sum(total_value_map_real(1:x_pixel/2,1:y_pixel/2)))/sum(sum(E(1:x_pixel/2,1:y_pixel/2)));
x_12 = sum(sum(total_value_map_real(1:x_pixel/2,y_pixel/2+1:y_pixel)))/sum(sum(E(1:x_pixel/2,y_pixel/2+1:y_pixel)));
x_21 = sum(sum(total_value_map_real(x_pixel/2+1:x_pixel,1:y_pixel/2)))/sum(sum(E(x_pixel/2+1:x_pixel,1:y_pixel/2)));
x_22 = sum(sum(total_value_map_real(x_pixel/2+1:x_pixel,y_pixel/2+1:y_pixel)))/sum(sum(E(x_pixel/2+1:x_pixel,y_pixel/2+1:y_pixel)));

offset_value = (x_12-x_11)+(x_22-x_21);
offset_value = offset_value/y_pixel;
offset_value_mtx1 = [0:1:y_pixel-1]*offset_value;

offset_value = (x_21-x_11)+(x_22-x_12);
offset_value = offset_value/x_pixel;
offset_value_mtx2 = [0:1:x_pixel-1]*offset_value;

for i = 1:y_pixel
   total_value_map(:,i) = total_value_map(:,i) - offset_value_mtx2';
end 

for i = 1:x_pixel
    total_value_map(i,:) = total_value_map(i,:) - offset_value_mtx1;
end    

figure(2)
imshow(total_value_map, [min(min(total_value_map)) max(max(total_value_map))])

total_value_map_real = total_value_map;
for i = 1:x_pixel
    for j = 1:y_pixel
        if E(i,j) < 0.5
            total_value_map_real(i,j) = 0;
        end
    end
end
total_value_map_real = total_value_map_real - sum(sum(total_value_map_real))/sum(sum(E));
I = total_value_map_real;

maxiter = 1300;
load('grouthTruth8.mat');
I1 = total_value_map_real;
Is = PixelMatrixToVector(I1);
Js = dct(Is);
[a1 b] = sort(abs(Js),'descend');
[ b ] = ApproximateLargeComponents1D( b, 1200 );
b = b';


weight = ones(256^2,1);
weight(b) = 2.4;



[ Ir ] = SMPfunc_1D_wt( I.*E,E,maxiter,weight );





% [ Ir ] = SMPfunc( PixelMatrixToVector(I),PixelMatrixToVector(pixelifsampled),maxiter);

% [ Ir ] = SMP_1D( I,E,maxiter);

% imshow(Ir, [min(min(Ir)) max(max(Ir))])








