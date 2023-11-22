% This function creates a logpolar noise profile on that assumption that
% retinal ganglion have increasing receptive fields towards the periphery.
% This means that the equivalent pixels sizes get larger. Aslo as ganglion
% cells can integrate over a larger area, the equivalent noise level also
% reduces.
% imSize       :     Image size
% imageScaling :     How the retinal resolution scales with eccentricity
% noiseLevel   :     What is the noise level (Set between 0 -1)
function noiseImage = retinalNoise(imSize, imageScaling, noiseLevel)

imCentre    = round(imSize);
numSpots    = 50*imSize;                % number of noise spots. 10x image size seems to work best 

% create a gausianSphere to seed noise pixels
gauss_sphere = gaussianSphere;

% pre-generate polar coordinates for the noise locations.
radiusNoise = 1 + round(((imSize/2)-1) * rand(1,numSpots));
thetaNoise  = 2*pi * rand(1,numSpots);

% intialise the output noise matrix
noiseImage = zeros(2*imSize);

for n = 1:numSpots
    
    % get the noise level
    noiseSize = round(1/imageScaling(round(radiusNoise(n))));

    % get the noise coordinates
    x = imCentre + round(radiusNoise(n) * cos(thetaNoise(n)));
    x = x - round(noiseSize/2);
    y = imCentre + round(radiusNoise(n) * sin(thetaNoise(n)));
    y = y - round(noiseSize/2);
    
    % Create the noise frame
    % use a gaussian profile resized according to the expected pixel acuity
    % for the given eccentricity. 
    % Although the "pixels" get larger, actually the photoreceptors are 
    % the same size. It is just that the receptive field is larger. As such
    % the noise level should also scale down due to averaging effect.

    frame = imresize(gauss_sphere, [noiseSize, noiseSize]);
    frame =  frame * rand * imageScaling(round(radiusNoise(n)));

    % Add the noise
    noiseImage(x:x+noiseSize -1, y:y+noiseSize -1) = noiseImage(x:x+noiseSize -1, y:y+noiseSize -1) + frame;

end

% cutout the active image
cutImage = noiseImage(1+floor(imSize/2):floor(imSize/2)+imSize, ...
                      1+floor(imSize/2):floor(imSize/2)+imSize);

% rescale to noise level and invert;
noiseImage = cutImage .* (cutImage<1);
noiseImage = noiseImage * noiseLevel/max(max(noiseImage));
noiseImage = 1-noiseImage;

% Plot outcome
% subplot(1,3,1); imagesc(imGrey); colormap(gray); colorbar
% subplot(1,3,2); imagesc(noiseImage); colormap(gray); colorbar
% subplot(1,3,3); imagesc(noiseImage.*double(imGrey)); colormap(gray); colorbar