clear all;close all;
filepath = 'D:\lightsheetsourcecode_matlab\MMcodeOrcaV2\imagedata\chenli\bone_02_07\151668\151668_195293\';
folderInfo = dir([filepath,'*.tiff']);
for i = 1:length(folderInfo)
    original_name = [filepath,folderInfo(i).name];
    new_name = strrep(folderInfo(i).name,'151667','151668');
    
    eval(['!rename' 32 original_name 32 new_name]);
end