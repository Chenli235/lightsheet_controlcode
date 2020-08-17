function [nextLightPath] = ChangeLightPath(controlParameters, allLasers, currentWavelength, currLightPath, nextLightPath, lightSheetMode) 
    
    path1Excitation = 1;
    path2Excitation = 2;
    pauseTime = 0.25;
    %Find the index of the wavelength
    %listWavelength = cat(1,allLasers.wavelength)    
    for ii = 1:numel(allLasers)
       if (allLasers(ii).wavelength == currentWavelength)
            curIndWavelength = ii;            
       end        
    end
    
    %Change the shutters
    if (nextLightPath == path2Excitation)
        %Change from path one to two
        controlParameters.shutters.open(path2Excitation);
        controlParameters.shutters.close(path1Excitation);
        nextLightPath = path2Excitation;
    else   
        %Change from path two to one
        controlParameters.shutters.open(path1Excitation);
        controlParameters.shutters.close(path2Excitation);
        nextLightPath = path1Excitation;
    end
    
    %The detection lens which is path depended 
    deltaForDet = allLasers(curIndWavelength).posDetLens(nextLightPath) - allLasers(curIndWavelength).posDetLens(currLightPath);
    if (abs(deltaForDet) < 0.1)
        fprintf(controlParameters.sDetLens,['1PR',num2str(deltaForDet)]);
        pause(pauseTime);
    end
    
    %In case that the system is in light sheet mode, move to the
    %parameters
    if (lightSheetMode)
        
        %Set the function generator to the new parameters
        vLowScan = allLasers(curIndWavelength).minVoltage(nextLightPath);
        vHighScan = allLasers(curIndWavelength).maxVoltage(nextLightPath);
        newFreq = allLasers(curIndWavelength).newFreq;
        symmetry = allLasers(curIndWavelength).symmetry(nextLightPath);
        SetAfgRamp(controlParameters.afg, vLowScan, vHighScan, newFreq, symmetry);
        
        SetExternalTriggerSignal(controlParameters.afg, newFreq, allLasers(curIndWavelength).OptimalDelay(nextLightPath));
        fwrite(controlParameters.afg, ':source1:phase:initiate');
        fwrite(controlParameters.afg, ':output1 on;');
        fwrite(controlParameters.afg, ':output2 on;');
        
    end
    
    
end

