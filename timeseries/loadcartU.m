function [data] = loadcartU(filename)
% loadcartU  load any CART .dat file (Cart 3 or CART 2)
% [data] = loadcart3(filename,framelength,frames)
%
%          filename is the name of the file to be loaded
%
%          example usage:
%
%            data=loadcartU('filename.txt');
%
%

%This is the universal CART2 & CART3 data file opener, it detects the file
%type (between CART 2 and 3, and also different types of CART 3, and also
%auto-detects the number of channels and assumes the number of samples to
%be 600 seconds worth

%The first thing to do is to see if this is just the filename, or filename
%+ path and if plus path strip out just the filename
SlashLoc = 0;
for i = 1:length(filename)
    if(strcmp(filename(i),'\'))
        SlashLoc = i;
    end
end
filenameNOPATH = filename(SlashLoc+1:length(filename));

%This is a universal file opener, first determine the file type

%First check for CART 2, which will have a shorter filename
if(size(filenameNOPATH,2) < 20)
    %In the case of CART 2, must first open the co-located HDR
    
    %Read in the HDR file
    [a,b,c,d,e,f,g,type]=textread([filename(1:SlashLoc) 'CART.HDR'],'%d%q%q%f%f%f%f%q','delimiter',',','headerlines',1);
    
    %Now loop through the type column and count everything not 'I' or 'U'
    NumChan = 0;
    for i=1:length(type)
        if (type{i} == 'I' || type{i} == 'U')
            %don't count it
        else
            NumChan = NumChan + 1;
        end
    end
    
        
    %Now open the data file and grab the info
    fid2=fopen(filename,'r','l');

    if(fid2~=-1)
      % Read data
      data=fread(fid2,[NumChan,100*600],'float32')';
      fclose(fid2);
    end % if

    
%Next check for the fixed style of 100 singles (earliest type)
elseif (datenum(filenameNOPATH(7:16)) < datenum('2009 12-18'))
    %100 single type open
    
    % Open the file in read only 
    fid=fopen(filename,'r');

    % Now read in the first six bytes which are characters denoting the number
    % of bytes in the header file
    TotByte = 0; %this is the total number of bytes in header file
    for i = 1:6
        c = fread(fid,1,'char') - 48;%subtract 48 to convert from ascii
        if c > 0 %otherwise invalid byte (probably space)
            TotByte = TotByte + c * 10 ^ (6 - i);
        end
    end

    %Now skip the header file
    fseek(fid,6 + TotByte,'bof');

    %Now read in the data
    if(fid~=-1)
      % Read data
      data=fread(fid,[100,400*600],'float32',0,'l')';  %data is little-endian
      fclose(fid);
    end

    
elseif(datenum(filenameNOPATH(7:16)) < datenum('2010 02-09'))
    %150 signle type open
    
        % Open the file in read only 
    fid=fopen(filename,'r');
    
        % Now read in the first six bytes which are characters denoting the number
    % of bytes in the header file
    TotByte = 0; %this is the total number of bytes in header file
    for i = 1:6
        c = fread(fid,1,'char') - 48;%subtract 48 to convert from ascii
        if c > 0 %otherwise invalid byte (probably space)
            TotByte = TotByte + c * 10 ^ (6 - i);
        end
    end

    %Now skip the header file
    fseek(fid,6 + TotByte,'bof');

    %Now read in the data
    if(fid~=-1)
      % Read data
      data=fread(fid,[150,400*600],'float32',0,'l')';  %data is little-endian
      fclose(fid);
    end
    
elseif(datenum(filenameNOPATH(7:16)) < datenum('2010 03-17'))
    %125 single type open
        
        % Open the file in read only 
    fid=fopen(filename,'r');
    
        % Now read in the first six bytes which are characters denoting the number
    % of bytes in the header file
    TotByte = 0; %this is the total number of bytes in header file
    for i = 1:6
        c = fread(fid,1,'char') - 48;%subtract 48 to convert from ascii
        if c > 0 %otherwise invalid byte (probably space)
            TotByte = TotByte + c * 10 ^ (6 - i);
        end
    end

    %Now skip the header file
    fseek(fid,6 + TotByte,'bof');

    %Now read in the data
    if(fid~=-1)
      % Read data
      data=fread(fid,[125,400*600],'float32',0,'l')';  %data is little-endian
      fclose(fid);
    end
    
else %variable length type open
    %If this is a CART 3 file, then the HDR information is stored at the
    %beginning of the same file
    
    % Open the file in read only 
    fid=fopen(filename,'r');
    
    %Now process the file if no error
    if(fid~=-1)

        % Now read in the first six bytes which are characters denoting the number
        % of bytes in the header file
        TotByte = 0; %this is the total number of bytes in header file
        for i = 1:6
            c = fread(fid,1,'char') - 48;%subtract 48 to convert from ascii
            if c > 0 %otherwise invalid byte (probably space)
                TotByte = TotByte + c * 10 ^ (6 - i);
            end
        end

        %Now start reading in the HDR file
        %Start by reading the header's header row
        a = textscan(fid,'%s',18);

        %Now read in the header line by line to compute the number of channels
        NumChan = 0;
        
        while(true) %read until we've overrun the total bytes
            row = textscan(fid,'%d%q%q%f%f%f%f%q%q%q%q',1,'delimiter','\t'); %Read in one line of the header
            NumChan = NumChan + 1; %Increment the number of channels
            ChanNum = row{1}; %Chan Num will be 561 for the last element

            if (ftell(fid) > TotByte) %end of the HDR
                break;
            end
        end
        
        %Now go to the start of the data within the file
        fseek(fid,6 + TotByte,'bof');

        %Now that we know the number of channels can read in the data
        %Assume the largest possible number of frames (600s 400 fps)
        
        if (filenameNOPATH(2) == '_') %check for super long file type
            disp('Long file type detected')
            data=fread(fid,[NumChan,50*400*600],'float32',0,'l')';  %data is little-endian
        else
            data=fread(fid,[NumChan,400*600],'float32',0,'l')';  %data is little-endian
        end
            
       fclose(fid);  %Close the file
    end
end
    


