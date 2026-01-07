
%% Homework - a full experiment

grey = [155 155 155];
black = [0 0 0];

white= [255 255 255];

my_screen = 0;
[my_window, rect] = Screen('OpenWindow', my_screen, grey, [0 0 700 700]);

device = -1;


KbName('UnifyKeyNames');  

keyRight = KbName('RightArrow');
keyLeft  = KbName('LeftArrow');
keyEsc   = KbName('ESCAPE');

% • Load from Internet famous and non famous faces

imgFolder = fullfile(pwd, 'Stimuli_FAMFAC');
if ~exist(imgFolder, 'dir')
    Screen('CloseAll');
    error('Bildordner nicht gefunden: %s', imgFolder);
end

n_trials = 5;

% Bilddateien sammeln
exts  = {'*.png','*.jpg','*.jpeg','*.bmp','*.tif','*.tiff'};
files = [];
for i = 1:numel(exts)
    files = [files; dir(fullfile(imgFolder, exts{i}))]; %#ok<AGROW>
end

if isempty(files)
    Screen('CloseAll');
    error('Keine Bilddateien im Ordner gefunden: %s', imgFolder);
end

n_images = numel(files);

% nicht mehr Trials als Bilder 
n_trials = min(n_trials, n_images);

% zufällig ohne Wiederholung
imgOrder = randperm(n_images, n_trials);


start_text = [ ...
    'Welcome to the experiment!\n\n\n' ...   
    'Thank you for taking part.\n\n' ... 
    'You will see a series of faces.\n\n\n' ...
    'Press the RIGHT arrow key if the face is familiar.\n' ...
    'Press the LEFT arrow key if the face is unfamiliar.\n\n\n' ...
    'Press any key to begin the experiment.' ...
];

 
% • Present a fix cross, then a mask/“noisy square” for
% some jittered time, then briefly show a random ’face’,d
% repeat/loops for many faces/trials …

fixCross = ones(50,50) * 155; 
fixCross(23:27,:) = 0; 
fixCross(:,23:27) = 0;
fixcrossTexture = Screen('MakeTexture', my_window, fixCross);

maskSize = 250;
maskRect = CenterRectOnPoint([0 0 maskSize maskSize], rect(3)/2, rect(4)/2);
maskMin = 0.2;   
maskMax = 0.8;   

RT   = nan(n_trials,1);
RESP = nan(n_trials,1);


Screen('TextSize', my_window, 20);      
DrawFormattedText(my_window, start_text, 'center', 'center', black);
Screen('Flip', my_window);
 
% KbQueue stuff
keysOfInterest = zeros(1,256);
keysOfInterest([keyLeft keyRight keyEsc]) = 1;

KbQueueCreate(device, keysOfInterest);
KbQueueStart(device);

% Press any key
KbReleaseWait(device);


while true
    [down, ~, keyCode] = KbCheck(device);
    if down
        if keyCode(keyEsc), Screen('CloseAll'); error('Abbruch (ESC).'); end
        break
    end
end
KbReleaseWait(device);   
 
for trial = 1:n_trials 
        
    % Fixcross
    Screen('fillRect', my_window, grey);
    Screen('DrawTexture', my_window, fixcrossTexture);
    Screen('Flip', my_window);
    WaitSecs(2)
    
    % jittered Noisy-mask
    noiseImg = uint8(rand(maskSize, maskSize) * 255);
    maskTex = Screen('MakeTexture', my_window, noiseImg);
    maskTime = maskMin + (maskMax - maskMin) * rand();
    Screen('FillRect', my_window, grey);
    Screen('DrawTexture', my_window, maskTex, [], maskRect);
    Screen('Flip', my_window);
    WaitSecs(maskTime); 
    
    % Face-Stimulus
    thisIdx  = imgOrder(trial);
    thisFile = fullfile(imgFolder, files(thisIdx).name);
    imgdata = imread(thisFile);
    my_texture = Screen('MakeTexture', my_window, imgdata);
    
    Screen('fillRect', my_window, grey);
    Screen('DrawTexture', my_window, my_texture, [], maskRect);
    
    KbQueueFlush(device); 
    tOn = Screen('Flip', my_window);
    
    % Face nur kurz zeigen (0.8s), dann blank, aber RT läuft weiter
    WaitSecs(0.8);
    Screen('FillRect', my_window, grey);
    Screen('Flip', my_window);
    
  deadline = tOn + 2.0;

    responded = false;
    while GetSecs < deadline
        % schaut, ob etwas in der Queue ist
        [pressed, firstPress] = KbQueueCheck(device);
        if pressed
            % ESC hat Priorität
            if firstPress(keyEsc) > 0
                Screen('CloseAll'); error('Abbruch (ESC).');
            end

            % nimm die erste gültige Taste (Left/Right) nach Zeit
            tL = firstPress(keyLeft);
            tR = firstPress(keyRight);

            if tL > 0 || tR > 0
                if tL > 0 && (tR == 0 || tL < tR)
                    RESP(trial) = 0;           % unfamiliar
                    RT(trial)   = tL - tOn;
                else
                    RESP(trial) = 1;           % familiar
                    RT(trial)   = tR - tOn;
                end
                responded = true;
                break
            end
        end
    end

    % Wenn keine Antwort innerhalb 2s: bleibt NaN
    if ~responded
        RESP(trial) = nan;
        RT(trial)   = nan;
    end

    Screen('Close', maskTex);
end

KbQueueStop(device);
KbQueueRelease(device);
      
Screen('CloseAll');