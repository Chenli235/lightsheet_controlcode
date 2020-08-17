for i =1:20
    filename = ['../zstacks/brain/_ChenLi_brain_02-Dec-2019',num2str(i,'%04d'),'.tiff'];
    image = imread(filename);
    new_image = imresize(image,0.4);
    new_filename = ['../zstacks/new_brain',num2str(i,'%04d'),'.tiff'];
    imwrite(new_image,new_filename);
end