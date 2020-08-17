function [ bigImage, xyzScanArray, indCenter] = TileInOneSection( controlParameters, vertTilesNum, horzTilesNum, stepSizeInLateralScan )
    
    %Get the current location of the stage !
    [xPos, yPos, zPos] = GetXYZPosition(controlParameters.MMC);
    %Find the cordinates of the sampling grid
    [ xyzScanArray, dirNames] = CreateScanCordCurrentCenter( xPos, yPos, zPos, vertTilesNum, horzTilesNum, stepSizeInLateralScan );
    indCenter = find((xyzScanArray(2,:) == yPos) & (xyzScanArray(3,:) == zPos));    
    %Capture the images according to the grid
    [images] = CaptureOneImagePerTile(xyzScanArray,  controlParameters);
    %stitch the images together
    [bigImage] = StitchTheImages(images, horzTilesNum, vertTilesNum); 
    save bigImage bigImage;
end

