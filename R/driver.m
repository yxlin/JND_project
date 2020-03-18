#!/usr/bin/octave
function driver(subNo,hand,ntrial,nblock)
  %% Just noticeable difference (JND) auditory test
  %%
  %% Input parameters:
  %%
  %% subNo    subject number; use subNo>9999 to skip the check for existing file
  %% hand     1, c: old, m: new; others, c: new, m: old
  %% ntrial   number of trials per block
  %% nblock   number of blocks
  %%
  %% Examples:
  %% driver(99,1, 10, 3);  %% We label this participant as 99, assign
  %% her/his handedness mapping to 1, set up 10 trials in each block,
  %% and run the auditory test for blocks. Therefore, the total number
  %% of trial is 30.
  %%
  %% Author: Yi-Shin Lin
  %% Affiliation: Tsao Yu's Bio-ASP Laboratory
  %% Institute: Research Center for Information Technology,
  %% Academia Sinica, Taiwan.
  %% Version: v.0.4
  %% 
  %% Date: 23 Feb, 2020
  %%       07 Mar, 2020
  %%       09 Mar, 2020
  %%---------------------------------
  %% Preliminary setup/check
  %% * Send to inferior Octave C-c C-i l
  %%---------------------------------
  sca;            %% Clear Matlab/Octave window; see help sca
  if nargin < 4   %% Check if all needed parameters are given:
    error('Must provide required input parameters "subNo", "hand", "ntrail" and "nblock"!');
  end

  if ntrial > 100   %% b'cz we use only 100 unique sound files; 
    error('ntrial must be less than or equal to 100.');  
  end

  %% Temporarily overwrite the Sync check
  %% Screen('Preference', 'SkipSyncTests', 1);

  %% Use current date and time to define a seeding 'state'.
  rand('state', sum(100*clock));
  
  %%---------------------------------
  %% Set up keyboard / response pad
  %%---------------------------------
  KbName('UnifyKeyNames');   %% Initialize keyboard responses
  advancestudytrial=KbName('n'); %% Press 'n' key to next screen
  %% Input variable, "hand", determines response mapping.
  if (hand==1)
      oldresp=KbName('c'); % 'c' key is for "SAME" response.
      newresp=KbName('m'); % 'm' key is for "DIFF" response.
  else
      oldresp=KbName('m'); % Keys are switched in this case.
      newresp=KbName('c');
  end

  %%--------------------------------------
  %% We save the result in 'data' folder and assign a pointer,
  %% 'datafn' to catch it.
  %%--------------------------------------
  datafn  = strcat('../data/task0/JND_', num2str(subNo),'.dat'); 
  %% Check for existing files to prevent overwriting files from a 
  %% previous subject/session (except for subject numbers > 9999).
  %% 'rt': read and text mode; see help fopen
  if subNo<9999 && fopen(datafn, 'rt')~=-1  
    fclose('all');
    error('JND Error: Data file already exists! Choose a different subject name.');
  else
    dfptr = fopen(datafn, 'wt'); % open text file to write
  end

  %%--------------------------------------
  %% The path where we store sound files
  %%--------------------------------------
  ROOT = "/home/bio-asp/Documents/data/JND44_1k";
  MASK = "12_QFCN_TIMIT_epoch_100_mask_";

  %% Set up sound ---------------------------------------
  %% Use default setting 2; see help PsychDefaultSetup
  PsychDefaultSetup(2);
  %% Wait until 10 s, if no response is entered. We should change it
  %% to 2 s, after pilot tests confirms the task likes regular auditory tasks.
  duration=10.000;  
  
  %% We choose the display with the maximum index, which is usually
  %% the external display on a laptop. We should investigate this
  %% further, when visual displays become critical.
  screens=Screen('Screens');
  screenNumber=max(screens);

  %% Define black, white and grey
  black = BlackIndex(screenNumber);
  white = WhiteIndex(screenNumber);
  grey  = white / 2;

  %% This will start screen check
  [window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey);
  %% Get the centre coordinate of the window in pixels
  [xCenter, yCenter] = RectCenter(windowRect);
  %% Get the size of the on screen window
  [screenXpixels, screenYpixels] = Screen('WindowSize', window);
  %% Query the frame duration in secs. Typical refresh rate is .016699 = 60 Hz; 
  ifi = Screen('GetFlipInterval', window); 
  hertz = FrameRate(window);

  %% Set up alpha-blending for smooth (anti-aliased) lines
  Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

  %% Task instruction
  str= sprintf('Press "%s" for SAME and "%s" for DIFFERENCE.\n', KbName(oldresp),KbName(newresp));
  message=['Test phase ...\n' str '... press "n" to begin ...'];
  Screen('TextSize', window, 40);   %% Select specific text font, style and size:
  Screen('TextFont', window, 'Courier');
  DrawFormattedText(window, message, 'center', 'center', white);

  %% Position the CITI logo
  yPos = yCenter;
  xPos = linspace(screenXpixels * 0.1, screenXpixels * 0.8, 4);
  theImageLocation = ['/home/bio-asp/Documents/figs/123.jpg'];
  theImage = imread(theImageLocation);
  [s1, s2, s3] = size(theImage);   %% Get the size of the image

  baseRect = [0 0 s1 s2];
  dstRects = nan(4, 1);
  dstRects(:, 1) = CenterRectOnPointd(baseRect, xPos(1), yPos);

  %% Check if the image is too big to fit on the screen 
  if s1 > screenYpixels || s2 > screenYpixels
     disp('ERROR! Image is too big to fit on the screen');
     sca;
     return;
  end
  imageTexture = Screen('MakeTexture', window, theImage);
  Screen('DrawTexture', window, imageTexture, [], dstRects, 0);

  Screen('Flip', window); %% Should the logo and the instruction together
  KbStrokeWait; %% Wait for 'n' to be pressed.

  repetitions=1;
  startCue=0;
  waitForDeviceStart=1;

  NOISE = cellstr(["BabyCry"; "Engine"; "White"]);
  SNR   = cellstr(["-6dB"; "-12dB"; "-15dB"; "0dB"; "6dB"; "12dB"]);
  SEQ   = 1:100;
  mask  = [0 2 4 6 8 10 12 14 16 18 20 22 23]; %% Compression levels
  same  = [0 1]; %% Same wav file?

  nstimulus = length(SEQ);
  nnoise    = length(NOISE);
  nsnr      = length(SNR);
  nmask     = length(mask);

  str=sprintf('SAME (%s) or DIFFERENCE (%s)\n',...
	      KbName(oldresp),KbName(newresp));
  message_resp=[str];
	
  try
    KbCheck;
    WaitSecs(0.1); %% 0.1 secs
    GetSecs;
    HideCursor;

    %% Set priority for script execution to the higtest
    priorityLevel=MaxPriority(window);
    Priority(priorityLevel);

    for block=1:nblock %% Time critical part

      str=sprintf('Block %i\n', block);
      message=[str];
      DrawFormattedText(window, message, 'center', 'center', black);
      Screen('Flip', window);
      WaitSecs(.500);
      
      for trial=1:ntrial
	  randomorder=randperm(nstimulus); %% 1 x nstimulus 
	  rfac_noise=randperm(nnoise); %% 1 x nnoise
	  rfac_snr=randperm(nsnr); %% 1 x nsnr
	  rfac_mask=randperm(nmask);
	  rfac_same=randperm(2);

	  if rfac_same(1,1) == 1
	    mask0 = num2str(mask(1,rfac_mask(1,1)));
	    mask1 = num2str(mask(1,rfac_mask(1,1)));
	  else
	    mask0 = num2str(mask(1,rfac_mask(1,1)));
	    mask1 = num2str(mask(1,rfac_mask(1,2)));
	  end
	  
	  MKTP0 = strcat(MASK, mask0);
	  MKTP1 = strcat(MASK, mask1);
	    
          fn = strcat("Test_", num2str(randomorder(1,trial)), ".wav");
          studyfn=[ROOT filesep MKTP0 filesep "Noisy" filesep NOISE{rfac_noise(1,1)} ...
     		   filesep SNR{rfac_snr(1,1)} filesep fn];
          %% testfn=[ROOT filesep "Test" filesep "Clean" filesep
	  %% fn];
	  testfn=[ROOT filesep MKTP1 filesep "Noisy" filesep ...
		  NOISE{rfac_noise(1,1)} filesep SNR{rfac_snr(1,1)} filesep fn];
	  

	  WaitSecs(.500);

          DrawFormattedText(window,'READY','center','center',black);
          Screen('Flip', window);
          [KeyIsDown, endrt, KeyCode]=KbCheck;
      
          [y0, freq0] = psychwavread(studyfn);
          [y1, freq1] = psychwavread(testfn);
          wavdata0 = y0';
          wavdata1 = y1';
          nrchannels0 = size(wavdata0,1);
          nrchannels1 = size(wavdata1,1);
          info0=audioinfo(studyfn);
          info1=audioinfo(testfn);
      
            %% Scale the length of the wav files according to ifi
            beepLengthSecs0   = info0.Duration;
            beepLengthSecs1   = info1.Duration;
            beepLengthFrames0 = round(beepLengthSecs0 / ifi);
            beepLengthFrames1 = round(beepLengthSecs1 / ifi);
        
            pahandle = PsychPortAudio('Open', [], [], 0, freq0, ...
      				nrchannels0);
            %% Play reference sentence
            PsychPortAudio('FillBuffer', pahandle, wavdata0);
            PsychPortAudio('Start', pahandle, repetitions, startCue, ...
      		     waitForDeviceStart);
      
            %% Draw Noise 1 text
            for i = 1:beepLengthFrames0
      	      DrawFormattedText(window, 'NOISE #1', 'center', 'center', ...
      				[1 0 0]);
      	      Screen('Flip', window);
            end
	    WaitSecs(0.500);

	    %% Play test sentence
            PsychPortAudio('FillBuffer', pahandle, wavdata1);
            PsychPortAudio('Start', pahandle, repetitions, startCue, ...
      		     waitForDeviceStart);
            t1=GetSecs;
            %% Draw beep text
            for i = 1:beepLengthFrames1
      	      DrawFormattedText(window, 'NOISE #2', 'center', 'center', ...
      				[1 0 0]);
      	      Screen('Flip', window);
            end
            t2=GetSecs;

            DrawFormattedText(window, message_resp, 'center', 'center', black);
            Screen('Flip', window);
      	    
            while (GetSecs - t2)<=duration
      	      if ( KeyCode(oldresp)==1 || KeyCode(newresp)==1 )
                break;
      	      end
      	      [KeyIsDown, endrt, KeyCode]=KbCheck;
      	      %% Wait 1 ms before checking the keyboard again to
      	      %% prevent overload of the machine at elevated Priority():
      	      WaitSecs(0.001);
            end
            resp=KbName(KeyCode);
            rt=round(1000*(endrt-t2));
		  
            fprintf(dfptr, '%i %i %i %s %s %s %s %s %s %s %s\n', ...
      	      subNo, ...
      	      hand, ...
      	      rt, ...
      	      resp, ...
      	      fn, ...
      	      NOISE{rfac_noise(1,1)}, ...
      	      SNR{rfac_noise(1,1)}, ...
	      mask0, ...
	      NOISE{rfac_noise(1,1)}, ...
      	      SNR{rfac_noise(1,1)},...
	      mask1);
      
            PsychPortAudio('Stop', pahandle);
	    PsychPortAudio('Close', pahandle);
	  end  %% Trial end
    end  %% Block end

    sca;  %% clear up 
    ShowCursor;
    fclose('all');
    Priority(0);

    return;  %% End of experiment:
  catch
    sca;
    ShowCursor;
    fclose('all');
    Priority(0);
    psychrethrow(psychlasterror);
  end


