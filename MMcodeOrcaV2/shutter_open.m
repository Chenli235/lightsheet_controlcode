out = [5*ones(80,1);5*ones(80,1)];
output_data = [];

for i=1:5*10
    output_data = [output_data;0*out];
end

queueOutputData(s,output_data);
startBackground(s)