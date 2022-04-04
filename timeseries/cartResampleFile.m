function cartResampleFile(inputFilename,sigListNames,resampFreq, outputFilename)

%function cartResampleFile
%
%This function loads a given cart file, selects a given list of channels,
%decimates the data to the frequency specified at the input and generates
%an essentially new cart data file out of this information
%NOTE ONLY WORKS WITH NEW FILE STRUCTURE!!

if nargin <4
    error('All 4 inputs required')
end

%Compute the decimation amount assuming original samping rate of 400
decFactor = floor(400/resampFreq);

%% Open the input file for reading and the output file for writing

fidIn=fopen(inputFilename,'r');
fidOut=fopen(outputFilename,'w');


%% Now progress through the input file's hdr line by line, copying lines when they are in the signal list

% Now read in the first six bytes which are characters denoting the number
% of bytes in the header file of the input file
TotByte = 0; %this is the total number of bytes in header file
for i = 1:6
    c = fread(fidIn,1,'char') - 48;%subtract 48 to convert from ascii
    if c > 0 %otherwise invalid byte (probably space)
        TotByte = TotByte + c * 10 ^ (6 - i);
    end
end

%Now start reading in the HDR file
%Start by reading the header's header row and writing into the output
%a = textscan(fidIn,'%s',18);
headerLine = fgetl(fidIn);

%Now read in the header file of the input
i = 0;
storeRow = [];
while(true) %read until we've overrun the total bytes
    i = i+1;%increment index
    row = textscan(fidIn,'%d%q%q%f%f%f%f%q%q%q%q',1,'delimiter','\t'); %Read in one line of the header
    storeRow = [storeRow;row];
    hdrIn(i,:) = [row{2} row{8} row{5} row{4}];
    if (ftell(fidIn) > TotByte) %end of the HDR
        break;
    end
end

%Now build up the HDR file of the output by finding channels which have a
%match in
hdrOut = [];
numHdrOutLines = 0;
sigList = [];
for s = 1:size(hdrIn,1)
    for ss = 1:length(sigListNames)
        if(strcmpi(hdrIn{s,1},sigListNames{ss}) || (strcmpi(hdrIn{s,1}(1:end-1),sigListNames{ss}) && strcmpi(hdrIn{s,1}(1:3),'GPS')))
            numHdrOutLines = numHdrOutLines + 1;
            sigList = [sigList s];
            hdrOut = [hdrOut;storeRow(s,:)];
        end
    end
end


rowOut = [];
for i = 1:size(hdrOut,1)
    
    rowOut = [rowOut sprintf('%d\t',i)];
    rowOut = [rowOut sprintf('%s\t',hdrOut{i,2}{1})];
    rowOut = [rowOut sprintf('%s\t',hdrOut{i,3}{1})];
    rowOut = [rowOut sprintf('%f\t',hdrOut{i,4})];
    rowOut = [rowOut sprintf('%f\t',hdrOut{i,5})];
    rowOut = [rowOut sprintf('%f\t',hdrOut{i,6})];
    rowOut = [rowOut sprintf('%f\t',hdrOut{i,7})];
    rowOut = [rowOut sprintf('%s\t',hdrOut{i,8}{1})];
    rowOut = [rowOut sprintf('%s\t',hdrOut{i,9}{1})];
    rowOut = [rowOut sprintf('%s\t',hdrOut{i,10}{1})];
    rowOut = [rowOut sprintf('%s\t',hdrOut{i,11}{1})];
    rowOut = [rowOut sprintf('\n')];
    
    %sprintf('%d\t%s\t%s\t%f\t%f\t%f\t%f\t%s\t%s\t%s\t%s',i,hdrOut{i,2}{1},hdrOut{i,3}{1},hdrOut(i,4),hdrOut(i,5),hdrOut(i,6),hdrOut(i,7),hdrOut{i,8}{1},hdrOut{i,9}{1},hdrOut{i,10}{1},hdrOut{i,11}{1})
end

%Build up the text now of the HDR file
%First append the hdr line
hdrLinesOut = [headerLine sprintf('\n') rowOut];
%Now compute the number of bytes in the HDR and append to the front
numBytesOut = length(hdrLinesOut);
hdrLinesOut = [sprintf('%6d',numBytesOut) hdrLinesOut];

%Now write this to the output file
fwrite(fidOut,hdrLinesOut);

%Close the input file
fclose(fidIn);

%Now load the data within the input file
dat = loadcartU(inputFilename);

%Take only the signals specified in sigList
dat = dat(:,sigList);

%Decimate by a factor of the amount calculated
dat = dat(1:decFactor:size(dat,1),:);

%Write the data to the output file
fwrite(fidOut,dat','float32',0,'l');  %data is little-endian

%Close the file
fclose(fidOut);
