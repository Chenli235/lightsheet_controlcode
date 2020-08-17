%For now this program assume a fixed exposure time of 50 ms, since it will
%support the required frame rate. Presss E to exit the live mode
%lightSheetmode - does not allow to change exposure or wavelength 

function [markedParameters, lastWavelength, lastIntensityInMW, lastExpTime, lastPosDetStage, lastPosExtStage, indWavelength, invalidTile, focusParameters] = ControlDCMotorUsingKeyboardV11(...
    controlParameters, allLasers, frameRate, expTime,...
    wavelength, intensityInMW, focusingFilter, lightSheetmode, addLine)

    %Debug
    %controlParameters.MMC.setCircularBufferMemoryFootprint(1024*10);
    
    SetPowerOfLasersV3(allLasers, controlParameters.sFWExt, controlParameters.sFWDet, wavelength,intensityInMW, focusingFilter);
    pause(3);
        
    %These parameters are points that the user want to save per wavelength
    markedParameters = struct('wavelength', 0, 'intensity', 0, 'posDetStage', 0, ...
    'posExtStage', 0);

    focusParameters = struct('sampleXPos',0, 'sampleYPos', 0, 'sampleZPos', 0 ,...
        'posExtLens', 0, 'posDetLens', 0, 'intensityInMW', 0, 'invalidTile', false, 'wavelength', 0);
    
    %In case that a line is added 
    if (addLine)
        %Crerate line array
        vPos = 1:100:2048;
        array1 = [vPos' ones(size(vPos,2),1)]; 
        array2 = [vPos' 2048*ones(size(vPos,2),1)];
    end
    
    if (~lightSheetmode)
        %Set the exposure according to the user input
         %Check the value of frameRate and make sure it is reasonable
        if (frameRate > 7)
            frameRate = 7;
        end
        if (frameRate < 0)
            frameRate = 2;
        end
        controlParameters.MMC.setProperty(controlParameters.cameraLabel,'Exposure', expTime);
        waitBetweenImages = 1/frameRate; %[sec]
    else
        waitBetweenImages = 0.1;
    end
    expVal = controlParameters.MMC.getProperty(controlParameters.cameraLabel,'Exposure');
    
    %Set running mode for light-sheet
    numOfImages = 1000000;
    intervalMs = 0;
    stopOnOverflow = false;
    controlParameters.MMC.setShutterOpen(true);
    controlParameters.MMC.startSequenceAcquisition(numOfImages, intervalMs, stopOnOverflow);
    %Set the shutter off
    controlParameters.MMC.setAutoShutter(false);   
    controlParameters.MMC.setShutterOpen(true);
    pause(0.2);
    
    %Snap an image and get its properties
    
    image = controlParameters.MMC.getLastImage();  % returned as a 1D array of signed integers in row-major order
    width = controlParameters.MMC.getImageWidth();
    height = controlParameters.MMC.getImageHeight();
    pixelType = 'uint16';
    image = typecast(image, pixelType);      % pixels must be interpreted as unsigned integers
    image = reshape(image, [width, height]); % image should be interpreted as a 2D array
    image = transpose(image);                % make column-major order for MATLAB
    prevImage = zeros(size(image));
    
        
    %Start capturing images and show them until somebody press the 'q' key
    
    %Check stage positions
    [posExt] = GetPos(controlParameters.sExtLens);
    [posDet] = GetPos(controlParameters.sDetLens);    
    
    %According to newport speed will not change accuracy
    %Set the speed at 1 mm/sec 
    fprintf(controlParameters.sExtLens, '1VA1');
    %Set the speed at 0.25 mm/sec 
    fprintf(controlParameters.sDetLens,'1VA0.25');
    
    %Find which wavelength  
    wavelengthList = zeros(1, numel(allLasers));
    for ii = 1:numel(allLasers)
        wavelengthList(ii) = allLasers(ii).wavelength;
        markedParameters(ii).wavelength = allLasers(ii).wavelength;
        if (allLasers(ii).wavelength == wavelength)
            indWavelength = ii;            
        end
    end
           
    %Create the figure and the call back function
    f = figure;   
    set(f,'toolbar','figure');
    set(f,'WindowKeyRelease', @KeyReleaseFcn); 
    %f.WindowStyle = 'modal';
    hAxes = subplot(1,1,1);
    hImage = imshow(image,'Parent',hAxes, 'DisplayRange', []); 
    textbox_handle = uicontrol('Style','text','HorizontalAlignment','left',...
    'String',['Step ext = 0.1 mm, Step det = 0.01, exp time =',char(expVal)...
    ,' intensity = ', num2str(intensityInMW),'mW, wavelength = ', num2str(wavelength),' nm'],'Position', [0 0 1000 50],...
     'TooltipString','Press up,down,right,left, z to change step size excitation, x to change step size detection, e to change exposure time, w to change wavelength, Y and u to increase decrease intensity and q to close the figure.');
    set(textbox_handle,'FontSize',12);
    
    %Create the handles structure
    myhandles = guihandles(f);
    myhandles.textbox_handle = textbox_handle;     
    myhandles.continue = true;
    myhandles.sDet = controlParameters.sDetLens;
    myhandles.sExt = controlParameters.sExtLens;
    myhandles.stepSizeExtOpt = {'1', '0.1', '0.01', '0.001'};
    myhandles.stepSizeExtIndex = 2; 
    myhandles.stepSizeDetOpt = {'0.1', '0.01', '0.005', '0.002', '0.001'};
    myhandles.stepSizeDetIndex = 3;   
    myhandles.stepSizeIntensity = [10, 5, 1];
    myhandles.stepSizeIntensityIndex = 2;
    myhandles.expousreTime = [500 250 100 50 25];
    myhandles.expousreTimeIndex = 3; 
    myhandles.controlParameters.cameraLabel = controlParameters.cameraLabel;
    myhandles.controlParameters.MMC = controlParameters.MMC;
    myhandles.allLasers = allLasers; 
    myhandles.sFWExt = controlParameters.sFWExt;
    myhandles.sFWDet = controlParameters.sFWDet;
    myhandles.wavelengthList = wavelengthList;
    myhandles.indWavelength = indWavelength;
    myhandles.intensityInMW = intensityInMW;
    myhandles.focusingFilter = focusingFilter;
    myhandles.lightSheetmode = lightSheetmode;
    myhandles.markedParameters = markedParameters;
    myhandles.saveImage = false;
    myhandles.afg = controlParameters.afg;
    myhandles.invalidTile = false; 
    myhandles.focusParameters = focusParameters;
    myhandles.numOfFocusPoints = 0;
    %myhandles.frameRateLSOptions = allLasers(1).FrameRates;
    %myhandles.frameRateLSOptionsInd = 2; 
     
    %Disable the auto shutter
    controlParameters.MMC.setAutoShutter(0);
    controlParameters.MMC.setShutterOpen(true);
    
    %For alignment 
    if (addLine)
        for ii = 1:size(vPos,2)
            hold on;  line([array1(ii,2) array2(ii,2)],[array1(ii,1) array2(ii,1)],'Color','y','LineWidth',2);        
        end
    end
    counter = 1;
   
    %Update the structure
    while (myhandles.continue)
        
        guidata(f,myhandles); 
        startTime = tic;
        image = controlParameters.MMC.getLastImage();
        image = typecast(image, pixelType);      % pixels must be interpreted as unsigned integers
        image = reshape(image, [width, height]); % image should be interpreted as a 2D array
        image = transpose(image);                % make column-major order for MATLAB
        set(hImage,'CData',image);
        
        %This part was added due to a software bug in MM and zyla adaptor 
        sumImages = sum(sum(double(prevImage) - double(image)));
        if (sumImages == 0)
            controlParameters.MMC.stopSequenceAcquisition;    
            controlParameters.MMC.clearCircularBuffer;
            display('Ops');
            controlParameters.MMC.startSequenceAcquisition(numOfImages, intervalMs, stopOnOverflow);
        end
        prevImage = image;
        %----------------
        
        if (myhandles.saveImage)
            myhandles.saveImage = false;
            nameOfFile = [date,'_',num2str(myhandles.wavelengthList(myhandles.indWavelength)),'nm_'...
            ,num2str(counter),'.tiff'];
            counter = counter + 1;
            imwrite(image, nameOfFile);    
            guidata(f,myhandles);
        end
        
        elTime = toc(startTime);
        if (elTime <= (waitBetweenImages))
            pause(waitBetweenImages - elTime);                
        else
            pause(0.15);
        end
        myhandles = guidata(f);     
       
    end
    
    %Close the shutter
    controlParameters.MMC.setShutterOpen(false);
    %Enable the auto shutter
    controlParameters.MMC.setAutoShutter(1);    
    close(f);
    figure; imshow(image,[]);
    lastIntensityInMW = myhandles.intensityInMW;
    lastWavelength = myhandles.wavelengthList(myhandles.indWavelength);
    lastExpTime = myhandles.expousreTime(myhandles.expousreTimeIndex);
    [lastPosExtStage] = GetPos(controlParameters.sExtLens);
    [lastPosDetStage] = GetPos(controlParameters.sDetLens); 
    markedParameters = myhandles.markedParameters;
    indWavelength = myhandles.indWavelength;
    invalidTile = myhandles.invalidTile;
    focusParameters = myhandles.focusParameters;
    
    %Make sure to close to stop the sequence acquisation and flush the buffer 
    controlParameters.MMC.clearCircularBuffer;
    controlParameters.MMC.stopSequenceAcquisition;
    
end

function [] = KeyReleaseFcn(src, evt)
        myhandles = guidata(src);
        %Debug
        %myhandles.controlParameters.MMC.stopSequenceAcquisition;        
        %-----
        speedFactor = 1;
        pauseTime = (1/speedFactor) + 0.1;
        switch lower(evt.Key)
            %Push the ext objective backwards
            case 'uparrow'
                fprintf(myhandles.sExt,['1PR-',myhandles.stepSizeExtOpt{myhandles.stepSizeExtIndex}]);
                pause(pauseTime); 
                
            %Push the ext objective toward the chamber
            case 'downarrow'
                fprintf(myhandles.sExt,['1PR',myhandles.stepSizeExtOpt{myhandles.stepSizeExtIndex}]);
                pause(pauseTime);    
               
            %Push the det objective toward the chamber
            case 'leftarrow'
                fprintf(myhandles.sDet,['1PR',myhandles.stepSizeDetOpt{myhandles.stepSizeDetIndex}]);
                pause(pauseTime); 
               
            %Push the det objective away from the chamber
            case 'rightarrow'
                fprintf(myhandles.sDet,['1PR-',myhandles.stepSizeDetOpt{myhandles.stepSizeDetIndex}]);
                pause(pauseTime);
                
            case 'z'
                %Change the step size
                myhandles.stepSizeExtIndex = myhandles.stepSizeExtIndex + 1;
                if (myhandles.stepSizeExtIndex > numel(myhandles.stepSizeExtOpt))
                    myhandles.stepSizeExtIndex = myhandles.stepSizeExtIndex - numel(myhandles.stepSizeExtOpt);
                end     
               
            case 'x'
                %Change the step size
                myhandles.stepSizeDetIndex = myhandles.stepSizeDetIndex + 1;
                if (myhandles.stepSizeDetIndex > numel(myhandles.stepSizeDetOpt))
                    myhandles.stepSizeDetIndex = myhandles.stepSizeDetIndex - numel(myhandles.stepSizeDetOpt);
                end     
               
            case 'e'
                %Change the exposure time
                if (~myhandles.lightSheetmode)
                    myhandles.expousreTimeIndex = myhandles.expousreTimeIndex + 1;
                    if (myhandles.expousreTimeIndex > numel(myhandles.expousreTime))
                        myhandles.expousreTimeIndex = myhandles.expousreTimeIndex - numel(myhandles.expousreTime);
                    end  
                    numOfImages = 1000000;
                    intervalMs = 0;
                    stopOnOverflow = false;
                    myhandles.controlParameters.MMC.stopSequenceAcquisition;
                    myhandles.controlParameters.MMC.clearCircularBuffer;
                    myhandles.controlParameters.MMC.setProperty(myhandles.controlParameters.cameraLabel,'Exposure', myhandles.expousreTime(myhandles.expousreTimeIndex));                
                    myhandles.controlParameters.MMC.startSequenceAcquisition(numOfImages, intervalMs, stopOnOverflow);              
                else
                    display('Light sheet mode cannot change the exposure time');
                end    
                
            case 'i'
                myhandles.stepSizeIntensityIndex = myhandles.stepSizeIntensityIndex + 1;
                if (myhandles.stepSizeIntensityIndex > numel(myhandles.stepSizeIntensity))
                    myhandles.stepSizeIntensityIndex = myhandles.stepSizeIntensityIndex - numel(myhandles.stepSizeIntensity);
                end                     
            case 'u'
                %increase the power
                myhandles.intensityInMW = myhandles.intensityInMW + myhandles.stepSizeIntensity(myhandles.stepSizeIntensityIndex) ;
                %myhandles.wavelengthList(myhandles.indWavelength)
                SetPowerOfLasersV3(myhandles.allLasers, myhandles.sFWExt, myhandles.sFWDet,...
                    myhandles.wavelengthList(myhandles.indWavelength), myhandles.intensityInMW, myhandles.focusingFilter); 
               
            case 'y' 
                %Decrease the power
                myhandles.intensityInMW = myhandles.intensityInMW - myhandles.stepSizeIntensity(myhandles.stepSizeIntensityIndex) ;
                %myhandles.wavelengthList(myhandles.indWavelength)
                SetPowerOfLasersV3(myhandles.allLasers, myhandles.sFWExt, myhandles.sFWDet,...
                    myhandles.wavelengthList(myhandles.indWavelength), myhandles.intensityInMW, myhandles.focusingFilter); 
               
            case 'w'
                if (~myhandles.lightSheetmode)
                    %Change the wavelength
                    %myhandles.intensityInMW = 10;
                    myhandles.indWavelength = myhandles.indWavelength + 1;
                    if (myhandles.indWavelength > numel(myhandles.wavelengthList))
                        myhandles.indWavelength = myhandles.indWavelength - numel(myhandles.wavelengthList);
                    end  
                    SetPowerOfLasersV3(myhandles.allLasers, myhandles.sFWExt, myhandles.sFWDet,...
                        myhandles.wavelengthList(myhandles.indWavelength), myhandles.intensityInMW, myhandles.focusingFilter); 
                    %Change the position of the stages to account for the chromatic abberations
                    %move the stage to the relative difference between the
                    %colors
                    
                    if (myhandles.indWavelength ~= 1)
                        deltaForExt = myhandles.allLasers(myhandles.indWavelength).posExtLens - myhandles.allLasers(myhandles.indWavelength - 1).posExtLens;
                    else
                        deltaForExt = myhandles.allLasers(myhandles.indWavelength).posExtLens - myhandles.allLasers(numel(myhandles.allLasers)).posExtLens;
                    end
                    if (abs(deltaForExt) < 2)
                         fprintf(myhandles.sExt,['1PR',num2str(deltaForExt)]);
                         pause(pauseTime);  
                    end
                 
                    if (myhandles.indWavelength ~= 1)
                        deltaForDet = myhandles.allLasers(myhandles.indWavelength).posDetLens - myhandles.allLasers(myhandles.indWavelength - 1).posDetLens;
                    else
                        deltaForDet = myhandles.allLasers(myhandles.indWavelength).posDetLens - myhandles.allLasers(numel(myhandles.allLasers)).posDetLens;
                    end
                    if (abs(deltaForDet) < 0.1)
                         fprintf(myhandles.sDet,['1PR',num2str(deltaForDet)]);
                         pause(pauseTime);  
                    end
                else
                    display('Light sheet mode cannot change the wavelength');
                end 
            case 's'
                myhandles.saveImage = true;
            case 'm'
                %Mark the position of the power and stages position in the
                %structure
                myhandles.markedParameters(myhandles.indWavelength).intensity = myhandles.intensityInMW;
                myhandles.markedParameters(myhandles.indWavelength).posDetStage = GetPos(myhandles.sDet);
                myhandles.markedParameters(myhandles.indWavelength).posExtStage = GetPos(myhandles.sExt); 
            case 'a'
                %In the case of autofocus
                if (myhandles.focusingFilter)
                    fwrite(myhandles.afg, ':output1 on;');
                    myhandles.focusingFilter = false;
                    %myhandles.intensityInMW = myhandles.intensityInMW*10;
                    SetPowerOfLasersV3(myhandles.allLasers, myhandles.sFWExt, myhandles.sFWDet,...
                    myhandles.wavelengthList(myhandles.indWavelength), myhandles.intensityInMW, myhandles.focusingFilter); 
                else
                    fwrite(myhandles.afg, ':output1 off;');
                    myhandles.focusingFilter = true;
                    %myhandles.intensityInMW = myhandles.intensityInMW/10;
                    SetPowerOfLasersV3(myhandles.allLasers, myhandles.sFWExt, myhandles.sFWDet,...
                    myhandles.wavelengthList(myhandles.indWavelength), myhandles.intensityInMW, myhandles.focusingFilter); 
                end       
           case 'subtract'
                myhandles.invalidTile = true;     
           case 'add'
                myhandles.invalidTile = false;    
           case 'pageup'
               myhandles.numOfFocusPoints = myhandles.numOfFocusPoints + 1;
               myhandles.focusParameters(myhandles.numOfFocusPoints).wavelength = myhandles.allLasers(myhandles.indWavelength).wavelength;  
               myhandles.focusParameters(myhandles.numOfFocusPoints).intensityInMW = myhandles.intensityInMW;
               myhandles.focusParameters(myhandles.numOfFocusPoints).posDetLens = str2num(GetPos(myhandles.sDet));
               myhandles.focusParameters(myhandles.numOfFocusPoints).posExtLens = str2num(GetPos(myhandles.sExt));
               [xPos, yPos, zPos] = GetXYZPosition(myhandles.controlParameters.MMC);
               myhandles.focusParameters(myhandles.numOfFocusPoints).sampleXPos = xPos;
               myhandles.focusParameters(myhandles.numOfFocusPoints).sampleYPos = yPos;
               myhandles.focusParameters(myhandles.numOfFocusPoints).sampleZPos = zPos;                    
           case 'pagedown'
               if (myhandles.numOfFocusPoints > 0)
                    myhandles.focusParameters(myhandles.numOfFocusPoints) = [];
                    myhandles.numOfFocusPoints = myhandles.numOfFocusPoints - 1;               
               end
           case 'q'
                display('Stopped');
                fwrite(myhandles.afg, ':output1 on;');
                if (myhandles.numOfFocusPoints == 0)
                    myhandles.numOfFocusPoints = myhandles.numOfFocusPoints + 1;
                    myhandles.focusParameters(myhandles.numOfFocusPoints).wavelength = myhandles.allLasers(myhandles.indWavelength).wavelength;  
                    myhandles.focusParameters(myhandles.numOfFocusPoints).intensityInMW = myhandles.intensityInMW;
                    myhandles.focusParameters(myhandles.numOfFocusPoints).posDetLens = str2num(GetPos(myhandles.sDet));
                    myhandles.focusParameters(myhandles.numOfFocusPoints).posExtLens = str2num(GetPos(myhandles.sExt));
                    [xPos, yPos, zPos] = GetXYZPosition(myhandles.controlParameters.MMC);
                    myhandles.focusParameters(myhandles.numOfFocusPoints).sampleXPos = xPos;
                    myhandles.focusParameters(myhandles.numOfFocusPoints).sampleYPos = yPos;
                    myhandles.focusParameters(myhandles.numOfFocusPoints).sampleZPos = zPos;     
                end
                myhandles.continue = false; 
        end     
               
        %Check for position of excitation lens
        [posExt] = GetPos(myhandles.sExt);
        
        %Check for position of detection lens
        [posDet] = GetPos(myhandles.sDet);
        
        %Check the exposure time
        expVal = myhandles.controlParameters.MMC.getProperty(myhandles.controlParameters.cameraLabel,'Exposure');
       
        %Update the text box
        textToDisplay = [{['Pos Ext = ',posExt,'   Step Ext = ',myhandles.stepSizeExtOpt{myhandles.stepSizeExtIndex},...
            '   Pos Det = ',posDet,'   Step Det = ',myhandles.stepSizeDetOpt{myhandles.stepSizeDetIndex},'  Exp time = ',char(expVal),'ms']};{[...
            ' intensity = ', num2str(myhandles.intensityInMW),'mW intensity step size = ',...
            num2str(myhandles.stepSizeIntensity(myhandles.stepSizeIntensityIndex)),'mW, wavelength = ',...
            num2str(myhandles.wavelengthList(myhandles.indWavelength)),' nm, InvalidTile =' num2str(myhandles.invalidTile),...
            ' Num of focus point = ',num2str(myhandles.numOfFocusPoints)]}];
        set(myhandles.textbox_handle,'String',textToDisplay);   
        guidata(src,myhandles); 
        %[{['x : ','pos x']};{['y : ','pos y']}]
        
        %Debug
%         numOfImages = 1000000;
%         intervalMs = 0;
%         stopOnOverflow = false;
%         myhandles.controlParameters.MMC.startSequenceAcquisition(numOfImages, intervalMs, stopOnOverflow);
%         %-----
end

function [pos] = GetPos(serial)
        
        maxSizeOfString = 7;        
        fprintf(serial,'1TP?');
        pos = fscanf(serial);
        k = strfind(pos,'TP');
        k = k(1);
        pos = pos(k+2:end);
        k = strfind(pos,'e');        
        if (~isempty(k))
            k = k(1);
            scale = pos(k+1:k+3);
            pos = pos(1:k-1);
            switch scale
                case '-06'
                    pos = num2str(0);
                case '-05'
                    pos = num2str(0);                
            end                   
        end
        
        if(numel(pos) > maxSizeOfString)
            pos = pos(1:maxSizeOfString);
        end       
            
end



