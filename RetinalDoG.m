% Always clear everything before start
% clear; clc; close all

function [ON, OFF, Total] = RetinalDoG(imRGB, gpuEnhanced, colOppenency)

% this function is calibrated to 1024 pixels.
imageSize = 1024;

%--------------------------------------------------------------------------
% Create padded matrix
%--------------------------------------------------------------------------

% resize to the standard image size and convert to GPU array
if gpuEnhanced == 1
    imRGB      = imresize(gpuArray(imRGB), [imageSize, imageSize ]);
else
    imRGB      = imresize(imRGB, [imageSize, imageSize ]);
end

paddedMatrix(imageSize + 254, imageSize + 254) = 0;
paddedMatrix(127:imageSize+126, 127:imageSize+126, 1:3) = double(imRGB(:,:,1:3));

for n = 1:127
    paddedMatrix(n,               127:imageSize+126, 1:3) = double(imRGB(1,:,1:3));
    paddedMatrix(imageSize+126+n, 127:imageSize+126, 1:3) = double(imRGB(imageSize,:,1:3));
    paddedMatrix(127:imageSize+126,n,                1:3) = double(imRGB(:,1,1:3));
    paddedMatrix(127:imageSize+126,imageSize+126+n,  1:3) = double(imRGB(:,imageSize,1:3));
end

for colour = 1:3
    paddedMatrix(1:126,1:126,  colour) = double(imRGB(1,1,colour));
    paddedMatrix(imageSize+127:imageSize+254,1:126,  colour) = double(imRGB(imageSize,1,colour));
    paddedMatrix(1:126, imageSize+127:imageSize+254,  colour) = double(imRGB(1,imageSize,colour));
    paddedMatrix(imageSize+127:imageSize+254, imageSize+127:imageSize+254,  colour) = double(imRGB(imageSize,imageSize,colour));
end

imRGB = paddedMatrix;

%--------------------------------------------------------------------------
% Create the base kernel
%--------------------------------------------------------------------------

% Define a basic gaussian matrix of 101 x 101 from which we can resize to
% whatever is required.
matrixSize      = [101, 101];       % Define size
sigma           = 25;               % Set sigma so Gaussian reaches edges.

gaussianMatrix  = fspecial('gaussian', matrixSize, sigma);

L3_gaussian     = imresize((gaussianMatrix), [3,3]);
L7_gaussian     = imresize((gaussianMatrix), [7,7]);
L15_gaussian     = imresize((gaussianMatrix), [15,15]);
L31_gaussian     = imresize((gaussianMatrix), [31,31]);
L63_gaussian     = imresize((gaussianMatrix), [63,63]);
L127_gaussian    = imresize((gaussianMatrix), [127,127]);

L3_gaussian     = (L3_gaussian)/sum(L3_gaussian);
L7_gaussian     = (L7_gaussian)/sum(L7_gaussian);
L15_gaussian    = (L15_gaussian)/sum(L15_gaussian);
L31_gaussian    = (L31_gaussian)/sum(L31_gaussian);
L63_gaussian    = (L63_gaussian)/sum(L63_gaussian);
L127_gaussian   = (L127_gaussian)/sum(L127_gaussian);

%--------------------------------------------------------------------------
% Extract image colormaps
%--------------------------------------------------------------------------

% Depending on the colour setting, extract grey or colour colormaps;
imGreen     = double(imRGB(:,:,2)); % 1 = red, 2 = green, 3 = blue
imRed       = double(imRGB(:,:,1));
imBlue      = double(imRGB(:,:,3));

if colOppenency ==1

    imYellow    = (imRed + imGreen)/2; 
else
    % defining grey as absolute according to the YUV Y setting, which is
    % based on the human perception index. Though I'm not sure if this is
    % already taken into account when defining the RGB.
    imGrey      = (0.299 *imRed) +...
                  (0.587 * imGreen) +...
                  (0.114 * imBlue); 
end


if colOppenency ==1
    %--------------------------------------------------------------------------
    % Colour Difference of Gaussians
    %--------------------------------------------------------------------------
    
    L3_Green     = conv2(imGreen, L3_gaussian,'same');
    L7_Green     = conv2(imGreen, L7_gaussian,'same');
    L15_Green    = conv2(imGreen, L15_gaussian,'same');
    L31_Green    = conv2(imGreen, L31_gaussian,'same');
    L63_Green    = conv2(imGreen, L63_gaussian,'same');
    
    L3_Red    = conv2(imRed, L3_gaussian,'same');
    L7_Red     = conv2(imRed, L7_gaussian,'same');
    L15_Red    = conv2(imRed, L15_gaussian,'same');
    L31_Red    = conv2(imRed, L31_gaussian,'same');
    L63_Red    = conv2(imRed, L63_gaussian,'same');
    
    L3_Blue     = conv2(imBlue , L3_gaussian,'same');
    L7_Blue      = conv2(imBlue , L7_gaussian,'same');
    L15_Blue     = conv2(imBlue , L15_gaussian,'same');
    L31_Blue     = conv2(imBlue , L31_gaussian,'same');
    % L63_Green    = conv2(imGreen, L63_gaussian,'same');
    
    % L3_Red    = conv2(imRed, L3_gaussian,'same');
    L7_Yellow     = conv2(imYellow, L7_gaussian,'same');
    L15_Yellow    = conv2(imYellow, L15_gaussian,'same');
    L31_Yellow    = conv2(imYellow, L31_gaussian,'same');
    L63_Yellow    = conv2(imYellow, L63_gaussian,'same');
    
    RG1 = L3_Green  - L7_Red;
    RG2 = L7_Green  - L15_Red;
    RG3 = L15_Green - L31_Red;
    RG4 = L31_Green - L63_Red;
    RGT = (RG1 + RG2 + RG3 + RG4 )/4;
    
    GR1 = L3_Red  - L7_Green;
    GR2 = L7_Red  - L15_Green;
    GR3 = L15_Red - L31_Green;
    GR4 = L31_Red - L63_Green;
    GRT = (GR1 + GR2 + GR3 + GR4 )/4;
    
    BY1 = L3_Blue - L7_Yellow;
    BY2 = L7_Blue  - L15_Yellow;
    BY3 = L15_Blue - L31_Yellow;
    BY4 = L31_Blue - L63_Yellow;
    BYT = (BY1 + BY2 + BY3 + BY4 )/4;
    
    ON_Col =    ((RG1 > 0) .* RG1) + ...
                ((RG2 > 0) .* RG2) + ...
                ((RG3 > 0) .* RG3) + ...
                ((RG4 > 0) .* RG4) + ...
                ((GR1 > 0) .* GR1) + ...
                ((GR2 > 0) .* GR2) + ...
                ((GR3 > 0) .* GR3) + ...
                ((GR4 > 0) .* GR4) + ...
                ((BY1 > 0) .* BY1) + ...
                ((BY2 > 0) .* BY2) + ...
                ((BY3 > 0) .* BY3) + ...
                ((BY4 > 0) .* BY4);
    
    OFF_Col=    ((RG1 < 0) .* RG1) + ...
                ((RG2 < 0) .* RG2) + ...
                ((RG3 < 0) .* RG3) + ...
                ((RG4 < 0) .* RG4) + ...
                ((GR1 < 0) .* GR1) + ...
                ((GR2 < 0) .* GR2) + ...
                ((GR3 < 0) .* GR3) + ...
                ((GR4 < 0) .* GR4) + ...
                ((BY1 < 0) .* BY1) + ...
                ((BY2 < 0) .* BY2) + ...
                ((BY3 < 0) .* BY3) + ...
                ((BY4 < 0) .* BY4);
    
    ON        = ON_Col(127:imageSize+126, 127:imageSize+126);
    OFF       = OFF_Col(127:imageSize+126, 127:imageSize+126);
    Total     = ON + OFF;

else
    %--------------------------------------------------------------------------
    % GreyScale Difference of Gaussians
    %--------------------------------------------------------------------------
    
    L3_Grey     = conv2(imGrey, L3_gaussian,'same');
    L7_Grey     = conv2(imGrey, L7_gaussian,'same');
    L15_Grey    = conv2(imGrey, L15_gaussian,'same');
    L31_Grey    = conv2(imGrey, L31_gaussian,'same');
    L63_Grey    = conv2(imGrey, L63_gaussian,'same');
    
    G1 = L3_Grey - L7_Grey;
    G2 = L7_Grey - L15_Grey;
    G3 = L15_Grey - L31_Grey;
    G4 = L31_Grey - L63_Grey;
    
    ON_G     =   ((G1 > 0) .* G1) + ...
                ((G2 > 0) .* G2) + ...
                ((G3 > 0) .* G3) + ...
                ((G4 > 0) .* G4);
    
    OFF_G     =  ((G1 < 0) .* G1) + ...
                ((G2 < 0) .* G2) + ...
                ((G3 < 0) .* G3) + ...
                ((G4 < 0) .* G4);
    
    ON        = ON_G(127:imageSize+126, 127:imageSize+126);
    OFF       = OFF_G(127:imageSize+126, 127:imageSize+126);
    Total     = ON + OFF;
    
end

% %--------------------------------------------------------------------------
% % Plot figures
% %--------------------------------------------------------------------------
% 
% % Depending on the colour setting, extract grey or colour colormaps;
% if colour ==1
%     figure
%     subplot(1,3,1); imagesc(ON_Col); colormap("gray");
%     subplot(1,3,2); imagesc(OFF_Col); colormap("gray");
%     subplot(1,3,3); imagesc(Total_Col); colormap(gray)
% else
%    figure
%     subplot(1,3,1); imagesc(ON_Grey); colormap(gray)
%     subplot(1,3,2); imagesc(OFF_Grey); colormap(gray)
%     subplot(1,3,3); imagesc(Total_Grey); colormap(gray)
% end










