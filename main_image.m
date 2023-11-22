

% Always clear everything before start
clear; clc; close all

tic
% Global variables
Stochasticity   = 50;       % To make the blur process stochastic - this helps prevent banding
noiseLevel      = 0.25;      % include noise to a value between 0-1;   
imSize          = 1024;     % The eccentricity funciton is calibrated to 1024 pixels

% Read image from file
imRGB       = imread('donkey.jpg');

%--------------------------------------------------------------------------
%% Calculate the retinal eccentricity function
%--------------------------------------------------------------------------
% this function calculates the resolution change with eccentrcitiy. It is
% calibrated to an image size of 1024 x 1024 using data from human vison.
iterations    = round(imSize/2);
[radii, eccentricity, eccentricScale] = retinalEccentricity(imSize, iterations);


% %--------------------------------------------------------------------------
% %% Calculate the retinally blurred image in orginal form
% %--------------------------------------------------------------------------
% 
finalImage = uint8(zeros(1024,1024,3));

for colour = 1:3

    % Extract the R, G, or B component of the image.
    imGrey =  imRGB(:,:,colour);
    % imGrey =  gpuArray(imRGB(:,:,colour));

    % imSize       :     Image size
    % imageScaling :     How the retinal resolution scales with eccentricity
    % noiseLevel   :     What is the noise level (Set between 0 -1)
    noiseImage = retinalNoise(imSize, eccentricity, noiseLevel);

    % convert to eccentricity of human vision
    % radii          : Is a linear spacing of radii from the image centre from which to construct the logpolar retinal image
    % imageScaling   : Is the eccentricity scaling function - i.e. how resolution changes with distance from the fovea (image centre).
    % imGrey         : The input image - needs to be greyScale
    % Stochasticity  : To make the blur process stochastic - this helps prevent banding
    % noiseLevel     : Include noise to a value between 0-
    retinaImage = retinalBlur(imGrey, radii, eccentricity, Stochasticity, noiseImage);

    % integrate into final image
    finalImage(:,:,colour) = retinaImage;


end


% make sure it is a uint8 for output
finalImage = uint8(finalImage);

%--------------------------------------------------------------------------
%% Calculate the retinally blurred image in Retinal form
%--------------------------------------------------------------------------

retinalImage = uint8(zeros(1024,1024,3));

% Get the retinal image
gpuEnhanced     = 0;
colOppenency    = 1;
[ON, OFF, Total] = RetinalDoG(imRGB, gpuEnhanced, colOppenency);

% % Add noise
% % imSize       :     Image size
% % imageScaling :     How the retinal resolution scales with eccentricity
% % noiseLevel   :     What is the noise level (Set between 0 -1)
% noiseImage = retinalNoise(imSize, eccentricity, noiseLevel);
  
% convert to eccentricity of human vision
% radii          : Is a linear spacing of radii from the image centre from which to construct the logpolar retinal image
% imageScaling   : Is the eccentricity scaling function - i.e. how resolution changes with distance from the fovea (image centre).
% imGrey         : The input image - needs to be greyScale
% Stochasticity  : To make the blur process stochastic - this helps prevent banding
% noiseLevel     : Include noise to a value between 0-
retinaImage = retinalBlur(Total, radii, eccentricity, Stochasticity, noiseImage);
    

% make sure it is a uint8 for output
retinaImage = uint8(retinaImage);
%--------------------------------------------------------------------------
%% Plot outputs
%--------------------------------------------------------------------------

figure; 
set(gcf,'color','w');

subplot(1,3,1)
set(gcf,'color','w');
plot(eccentricScale, eccentricity);
xlabel('Eccentricity (degrees)')
ylabel('Acuity')
title('Human acuity with eccentricity from fovea')

subplot(1,3,2)
imagesc(imRGB); 

subplot(1,3,3)
imagesc(finalImage); 

figure; 
set(gcf,'color','w');

subplot(1,3,1)
set(gcf,'color','w');
plot(eccentricScale, eccentricity);
xlabel('Eccentricity (degrees)')
ylabel('Acuity')
title('Human acuity with eccentricity from fovea')

subplot(1,3,2)
imagesc(RetinalDoG); 

subplot(1,3,3)
imagesc(retinaImage); 


%--------------------------------------------------------------------------
%% Plot outputs
%--------------------------------------------------------------------------
% imwrite(finalImage, 'retinalImage.jpg')
% toc