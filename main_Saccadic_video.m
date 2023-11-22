clear; clc; close all

%%-------------------------------------------------------------------------
% Settings
% -------------------------------------------------------------------------
tic

% video properties
vidInputFile     = 'inputVideos\AodhanBoat.mp4'; %'outputVideo.avi';
vidOutputFile_O  = 'OutputFiles\outputVideo.mp4';           %'outputVideo.avi';
vidOutputFile_EC = 'OutputFiles\outputVideo_eccColour.mp4'; %'outputVideo.avi';
vidOutputFile_EG = 'OutputFiles\outputVideo_eccGrey.mp4'; %'outputVideo.avi';
vidFormat        = 'MPEG-4';                     %'Motion JPEG AVI';
vidFramerate     = 30;
vidQuality       = 80;

% video and search strategy
maxFrames       = 600;             % 1 frame =~ 1 minute so maximum 10 hours.
dTheta          = 1; 
% rotations                        = 8;    % how many times to spiral around the image
% fading          = 0.8;  % fading effect to simulate visual memory
% retinalNoise    = 0.02;  % Add background retinal noise;
% intensityScaling= 0.1; % scaling fudge factor
maxRadius       = 1; % max radius scaling - between 0 and 1;

% image/frame properties
imageSize       = 1024;      % The eccentricity funciton is calibrated to 1024 pixels
% prosthesisSize  = 80;
Stochasticity   = 50;       % To make the blur process stochastic - this helps prevent banding
noiseLevel      = 0.0;      % include noise to a value between 0-1;   

% % Phosphene parameters
% minPhosphene    = 0.1;      % Minimim phosphene intensity, max = 1
% minSpacing      = 15;       % Minimum spacing between phosphenes
% numPhosphenes   = 100;      % Number of phosphenes
% phospheneSize   = [20, 20]; % Size of the gaussian sphere representing the phosphene
% sigma           = 5;        % the spread of the phosphene

                
%%-------------------------------------------------------------------------
% Set up I/O files
% -------------------------------------------------------------------------

% Create a VideoWriter and VideoReader objects
readerObj = VideoReader(vidInputFile);
writerObj_O = VideoWriter(vidOutputFile_O,vidFormat);
writerObj_EC = VideoWriter(vidOutputFile_EC,vidFormat);
writerObj_EG = VideoWriter(vidOutputFile_EG,vidFormat);

% Obtain the number of input video Frames
numFrames = readerObj.NumFrames;

% Set the frame rate of the video
writerObj_O.FrameRate = vidFramerate;
writerObj_EC.FrameRate = vidFramerate;
writerObj_EG.FrameRate = vidFramerate;

% Set quality
writerObj_O.Quality = vidQuality;
writerObj_EC.Quality = vidQuality;
writerObj_EG.Quality = vidQuality;

% Open the VideoWriter object
open(writerObj_O);
open(writerObj_EC);
open(writerObj_EG);

%%-------------------------------------------------------------------------
% Set video Frame dimensions
% -------------------------------------------------------------------------

% Read video Frame
vidFrame = read(readerObj,1);

% Resize image to provide space for roving foveation
[rows, cols, clr] = size(vidFrame);
if rows>cols
     newRows = round(1536*rows/cols);
     newCols = 1536;
else
    newCols = round(1536*cols/rows);
    newRows = 1536;
end

% get mid point
midX = round(newCols/2);
midY = round(newRows/2);

% check the number of frames. If the video is longer the maximum number of
% acceptable frames, then truncate.
if numFrames > maxFrames
    numFrames = maxFrames;
end

if numFrames*65/60 >1
    disp(strcat('expected time:', num2str(numFrames*65/3600), 'hours'));
else
    disp(strcat('expected time:', num2str(numFrames*65/60), 'minutes'));
end




%%-------------------------------------------------------------------------
% Random walk strategy
% ------------------------------------------------------------------------
% Attain random walk coordinates in a randomised spiral strategy for the
% veiwing saccades

radius = (1536-min(rows,cols)-1)/2;
radius = radius * maxRadius;

% convert dTheta to radians
dTheta = dTheta * pi/180;

rotations = round(dTheta * numFrames);
n = 1;
rho = 0;
direction = 2;
for theta = linspace(0, rotations, numFrames)

    % Randomise radius
    rho = rho + direction; %rand() * radius;

    if rho > radius
        rho = radius -2;
        direction = direction * -1;
    elseif rho <1
        rho = 2;
        direction = direction * -1;
    end


    % get cartesian coordinates of the spiral random walk
    xPos(n)  = midX + int16(rho * sin(theta));
    yPos(n)  = midY + int16(rho * cos(theta));

    n = n+1;

end

%--------------------------------------------------------------------------
%% Calculate the retinal eccentricity function
%--------------------------------------------------------------------------
% this function calculates the resolution change with eccentrcitiy. It is
% calibrated to an image size of 1024 x 1024 using data from human vison.
iterations    = round(imageSize/2);
[radii, eccentricity, eccentricScale] = retinalEccentricity(imageSize, iterations);

%%-------------------------------------------------------------------------
% Create a pixelated reconstruction video
% ------------------------------------------------------------------------

for n = 1: length(xPos)

    % Get videoFrame
    vidFrame = read(readerObj,n);
    resizeFrame = imresize(vidFrame, [newRows, newCols]);    

    % get frame cutout coordinates
    xCoords = (xPos(n)-512):(xPos(n)+511);
    yCoords = (yPos(n)-512):(yPos(n)+511);

    % Get the cut scene
    cutScene = resizeFrame(yCoords, xCoords, 1:3);

    %convert each of the colour patterns of the frame into a retinal form
    for colour = 1:3

        % Extract the R, G, or B component of the image.
        imGrey = cutScene(:,:,colour);

        % imSize       :     Image size
        % imageScaling :     How the retinal resolution scales with eccentricity
        % noiseLevel   :     What is the noise level (Set between 0 -1)
        noiseImage = retinalNoise(imageSize, eccentricity, noiseLevel);

        % convert to the retinal image
        % radii          : Is a linear spacing of radii from the image centre from which to construct the logpolar retinal image
        % imageScaling   : Is the eccentricity scaling function - i.e. how resolution changes with distance from the fovea (image centre).
        % imGrey         : The input image - needs to be greyScale
        % Stochasticity  : To make the blur process stochastic - this helps prevent banding
        % noiseLevel     : Include noise to a value between 0-
        retinaImage = retinalBlur(imGrey, radii, eccentricity, Stochasticity, noiseImage);

        % integrate into final image
        retinalFrame(:,:,colour) = retinaImage;
    end
    
    % noiseImage = retinalNoise(imageSize, eccentricity, noiseLevel);
    % retinalFrame= retinalProcessing(rgb2gray(cutScene), radii, eccentricity, Stochasticity, noiseImage);

    retinalGreyFrame = rgb2gray(retinalFrame);

    % Write to video
    writeVideo(writerObj_O,uint8(cutScene));
    writeVideo(writerObj_EC,uint8(retinalFrame));
    writeVideo(writerObj_EG,uint8(retinalGreyFrame));

end

% Close the VideoWriter object
close(writerObj_O);
close(writerObj_EC);

toc



