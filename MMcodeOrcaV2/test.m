s1 = daq.createSession('mcc');

galvoX1 = addAnalogOutputChannel(s1,'Board1', 'Ao1', 'Voltage');
galvoY1= addAnalogOutputChannel(s1,'Board1', 'Ao3', 'Voltage');
% data0 = linspace(-2,2,5000)';
% data1 = linspace(-2,2,5000)';
% queueOutputData(s,[data0 data1]);
% startBackground(s);
outputSingleScan(s1,[0.03,0])% set galvo x and y zero
release(s1);
clear s1;
clear galvoX1;
clear galvoY1;

images_file = dir('*.tiff');
len=length(images_file);
resolution = [];
for i=1:len
    i
%     oldname = images_file(i).name;
%     newname = [oldname(1:3),'8',oldname(5:end)];
%     command = ['rename' 32 oldname 32 newname];
%     status = dos(command);
    D = dir(images_file(i).name);
    if D.bytes/1000 > 500
        quality = brisque(imread(images_file(i).name));
        resolution = [resolution,quality];
    end
end
plot(resolution)
original_img = imread('beam.tiff');
new_img = original_img(1190:1550,:);
imshow(new_img,[0,1500]);
x=[1024,1024];y=[100,270];
line(x,y,'linewidth',6);

x=[1024-153*6,1024-153*6];y=[100,270];
line(x,y,'linewidth',6);
x=[1024+153*6,1024+153*6];y=[100,270];
line(x,y,'linewidth',6);

x=[1024-153*4,1024-153*4];y=[100,270];
line(x,y,'linewidth',6);
x=[1024+153*4,1024+153*4];y=[100,270];
line(x,y,'linewidth',6);

x=[1024-153*2,1024-153*2];y=[100,270];
line(x,y,'linewidth',6);
x=[1024+153*2,1024+153*2];y=[100,270];
line(x,y,'linewidth',6);

x=[1024-153*2,1024-153*2];y=[100,270];
line(x,y,'linewidth',6);
x=[1024+153*2,1024+153*2];y=[100,270];
line(x,y,'linewidth',6);



% beam width 13, 17, 19,28
%x=[-600,-400,-200,0,200,400,600];
%x = ['-600um','-400um','-200um','0um','200um','400um','600um']
x = categorical({'-600um','-400um','-200um','0um','200um','400um','600um'});
x = reordercats(x,{'-600um','-400um','-200um','0um','200um','400um','600um'});
y=[38,26.78,17.38,11.67,14.035,23.031,34.14185];
bar(x,y,0.5);ylabel('beam width(um)');ylim([10,40]);
for i=-5:1:5
    x=1:361;
    y=double(new_img(:,1024+i*153))';
    f=fit(x',y','gauss1');
    width = [width,f.c1/sqrt(2)*2.355*1.7*0.65];
end



