clear all;close all;
withcorrection_filepath = 'D:\lightsheetsourcecode_matlab\MMcodeOrcaV2\imagedata\chenli\test4\surface\withcorrection\207336\207336_164317\';
withoutcorrection_filepath = 'D:\lightsheetsourcecode_matlab\MMcodeOrcaV2\imagedata\chenli\test4\surface\withoutcorrection\207336\207336_164317\';

folderInfo1 = dir([withcorrection_filepath,'*.tiff']);
folderInfo2 = dir([withoutcorrection_filepath,'*.tiff']);
for i = 1:length(folderInfo1)
    firstimg = imread([withcorrection_filepath,folderInfo1(i).name]);
    secondimg = imread([withoutcorrection_filepath,folderInfo2(i).name]);
    %sum(sum(firstimg-secondimg))/(2048*2048)
    newimg = [firstimg,secondimg];
    imwrite(newimg,['D:\lightsheetsourcecode_matlab\MMcodeOrcaV2\imagedata\chenli\test4\surface\2tiles\',num2str(i),'.tiff']);
end


