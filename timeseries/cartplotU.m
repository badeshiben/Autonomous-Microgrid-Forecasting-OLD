function cartplotU
% cartplot is used to open and examine CART data
% Dependencies: cartLoadHdrU, loadcartU,
%               "CART.HDR" file in the path of the data to open (if CART2)
%               "charts.mat" file in the current path

% This is the new universal cartplot which likewise calls universal loaders


%% Use system background color for GUI components
panelColor = get(0,'DefaultUicontrolBackgroundColor');

%% ------------------Global Variables------------------------------------
% Define global variables for use throughout the GUI
%------------------------------------------------------------------------

charts=zeros(1);
d=zeros(1);  %normal data matrix for 1st and 2nd data set
d2=zeros(1);
x=zeros(1);
x2=zeros(1);
d_filt=zeros(1);  %filtered data matrix for 1st and 2nd data set
d_filt2=zeros(1);
d_counts=zeros(1);  %count values for 1st and second data set
d_counts2=zeros(1);

numAnalBtn = 6; %the number of analysis buttons currently

hdr = {[]}; %we don't know the hdr in the beginning in this version
load charts;
ForceRedraw = false;  %Use this variable to force a plot redraw
FPS = [0 0]; %The fps of the 1st and second data set
alpha = [0 0]; %The alpha value is used to filter the signals
LSSRPM = [0 0]; %Which column contains LSSPM in the data file?
LSSPOS = [0 0]; %Which column contains the azimuth angle in each data file
COMCOL = [0 0]; %Which column contains the command state
CNTCOL = [0 0]; %Which column contains the controller state
B1COL = [0 0]; %Which column contains the B1 Pitch Angle
B2COL = [0 0]; %Which column contains the B2 Pitch Angle
B3COL = [0 0]; %Which column contains the B3 Pitch Angle
MET37WSCOL = [0 0]; %Which column contains the 37m wind speed

%Analysis options
Spa_Av_Num = 1;  %The Spa Average Number used in fft and psd anal
PSDLower = 0.3; %The lower limit for plotting PSD
PSDUpper = 5; %The lower limit for plotting PSD

WFWindowLength = 3; %Size of waterfall window in seconds
WFWindowStep = 0.25; %Size in seconds, of steps between windows
WFResamp = 1; %Factor for resampling
WFDistort = 1; %Whether or not to log distort amplitude
WFInterpolate = 1; %Whether or not to interpolate
WFPCount = 0; %Number of p-lines to plot
WFFReqRange = [0.5 200]; %Freq range to plot
WFBinRange = [0 42]; %Bin range to plot
WFNumBins = 200; %Number of RPM bins to use
WFLSS = 1; %Whether or not to bin against RPM
WFControlOnly = 0; %Whether or not to only include control modes in WF compute
WFSliceRange = [0 200];  %The region for waterfall slice averaging
WFForceMax = -1;  %Force a value into the waterfall (-1 for don't force)

%% ------------ GUI layout-------------------------------------------------
% In this first section define all the components of the GUI
%--------------------------------------------------------------------------

%% Set up the figure and defaults
f = figure('Units','characters',...
        'Position',[30 30 210 40],...
        'Color',panelColor,...
        'HandleVisibility','callback',...
        'IntegerHandle','off',...
        'MenuBar','none',...
        'Renderer','painters',...
        'Toolbar','figure',...
        'NumberTitle','off',...
        'Name','CART data plotter',...
        'ResizeFcn',@figResize);

%% Create the Center panel
CenterPanel = uipanel('bordertype','etchedin',...
    'BackgroundColor',panelColor,...
    'Units','characters',...
    'Position',[82 0 38 40],...
    'Parent',f,...
    'ResizeFcn',@PanelResize);%% Create the Center panel

%% Create the Right panel
RightPanel = uipanel('bordertype','etchedin',...
    'BackgroundColor',panelColor,...
    'Units','characters',...
    'Position',[120 0 38 40],...
    'Parent',f,...
    'ResizeFcn',@PanelResize);

%% Create the Left (axes) panel
LeftPanel = uipanel('bordertype','etchedin',...
    'Units','characters',...
    'Position', [0 0 82 35],...
    'Parent',f,...
    'ResizeFcn',@PanelResize);

%% Create the analysis panel and subpanels
AnalysisPanel = uipanel('bordertype','etchedin',...
    'BackgroundColor',panelColor,...
    'Units','characters',...
    'Position',[150 0 25 40],...
    'Parent',f,...
    'ResizeFcn',@PanelResize);

PSDPanel = uipanel('bordertype','etchedin',...
    'BackgroundColor',panelColor,...
    'Title','PSD options',...
    'Units','characters',...
    'Position',[0 0 25 20],...
    'Parent',AnalysisPanel,...
    'ResizeFcn',@PanelResize);

WFPanel = uipanel('bordertype','etchedin',...
    'BackgroundColor',panelColor,...
    'Title','Watefall options',...
    'Units','characters',...
    'Position',[0 25 25 20],...
    'Parent',AnalysisPanel,...
    'ResizeFcn',@PanelResize);

%% Add an axes to the center panel
for i=1:6
    a(i)=axes('parent',LeftPanel,...
        'OuterPosition',[0 (2-i)/2 1 0.5]);
end
    
%% Add ListBox
for i=1:12
ListBox(i) = uicontrol(f,'Style','ListBox',...
        'Units','characters',...
        'Position',[80 22 34 6],...
        'BackgroundColor','white',...
        'String',hdr(:,1),...
        'Parent',CenterPanel,...
        'Enable','off',...
        'TooltipString','Select multiple with ctrl/shift',...
        'Max',2,...
        'Value',[],...
        'Callback',@ListBox_Callback);
    if i>6 set(ListBox(i),'Parent',RightPanel);end;
end

%% Add clear button
for i=1:12
ClearButton(i) = uicontrol(f,'Style','pushbutton',...
        'Units','characters',...
        'String','Clear',...
        'Parent',CenterPanel,...
        'TooltipString','Clears selections',...
        'Callback',@ClearButton_Callback);
    if i>6 set(ClearButton(i),'Parent',RightPanel);end;
end

%% Add Export buttons (export data to workspace)
for i=1:6
ExpButton(i) = uicontrol(f,'Style','pushbutton',...
        'Units','characters',...
        'String','Export',...
        'Parent',LeftPanel,...
        'TooltipString','Export current signals to workspace',...
        'Position',[200 0 6 1],...
        'Callback',@ExpButton_Callback);
end


%% Add Collective (0) button
for i=1:6
CollectiveButton(i) = uicontrol(f,'Style','pushbutton',...
        'Units','characters',...
        'String','0',...
        'Parent',LeftPanel,...
        'TooltipString','Find MBC Collective',...
        'Position',[200 0 6 1],...
        'Callback',@CollectiveButton_Callback);
end

%% Add Cosine-cyclic (c) button
for i=1:6
CosineButton(i) = uicontrol(f,'Style','pushbutton',...
        'Units','characters',...
        'String','c',...
        'Parent',LeftPanel,...
        'TooltipString','Find MBC Cosine-Cyclic',...
        'Position',[200 0 6 1],...
        'Callback',@CosineButton_Callback);
end

%% Add Sine-cyclic (s) button
for i=1:6
SineButton(i) = uicontrol(f,'Style','pushbutton',...
        'Units','characters',...
        'String','s',...
        'Parent',LeftPanel,...
        'TooltipString','Find MBC Sine-Cyclic',...
        'Position',[200 0 6 1],...
        'Callback',@SineButton_Callback);
end

%% Add Minus (-) button
for i=1:6
MinusButton(i) = uicontrol(f,'Style','pushbutton',...
        'Units','characters',...
        'String','-',...
        'Parent',LeftPanel,...
        'TooltipString','Subtraction',...
        'Position',[200 0 6 1],...
        'Callback',@MinusButton_Callback);
end

%% Add Out of plane button
for i=1:6
OopButton(i) = uicontrol(f,'Style','pushbutton',...
        'Units','characters',...
        'String','Oop',...
        'Parent',LeftPanel,...
        'TooltipString','Compute out of plane bending',...
        'Position',[200 0 6 1],...
        'Callback',@OopButton_Callback);
end

%% Add In plane button
for i=1:6
InpButton(i) = uicontrol(f,'Style','pushbutton',...
        'Units','characters',...
        'String','Inp',...
        'Parent',LeftPanel,...
        'TooltipString','Compute in plane bending',...
        'Position',[200 0 6 1],...
        'Callback',@InpButton_Callback);
end

%% Add FFT button
for i=1:6
FFTButton(i) = uicontrol(f,'Style','pushbutton',...
        'Units','characters',...
        'String','FFT',...
        'Parent',LeftPanel,...
        'TooltipString','FFT',...
        'Position',[200 0 6 1],...
        'Callback',@FFTButton_Callback);
end

%% Add PSD button
for i=1:6
PSDButton(i) = uicontrol(f,'Style','pushbutton',...
        'Units','characters',...
        'String','PSD',...
        'Parent',LeftPanel,...
        'TooltipString','PSD',...
        'Position',[200 0 6 1],...
        'Callback',@PSDButton_Callback);
end



%% Add 1PFFT buttons
for i=1:6
OnePFFTButton(i) = uicontrol(f,'Style','pushbutton',...
        'Units','characters',...
        'String','1P FFT',...
        'Parent',LeftPanel,...
        'TooltipString','1P FFT',...
        'Position',[200 0 6 1],...
        'Callback',@OnePFFTButton_Callback);
end

%% Add Waterfall buttons
for i=1:6
WFButton(i) = uicontrol(f,'Style','pushbutton',...
        'Units','characters',...
        'String','WF',...
        'Parent',LeftPanel,...
        'TooltipString','Produce a waterfall plot',...
        'Position',[200 0 6 1],...
        'Callback',@WFButton_Callback);
end

%% Add Waterfall Slice buttons
for i=1:6
WFSliceButton(i) = uicontrol(f,'Style','pushbutton',...
        'Units','characters',...
        'String','WF Slice',...
        'Parent',LeftPanel,...
        'TooltipString','Produce a waterfall slice plot',...
        'Position',[200 0 6 1],...
        'Callback',@WFSliceButton_Callback);
end



%% Add a filter button
FilterButton1 = uicontrol(f,'Style','togglebutton',...
        'Units','characters',...
        'String','Filter 1st',...
        'Parent',CenterPanel,...
        'TooltipString','Use Filtered Data?',...
        'Position',[79 0 6 1],...
        'Callback',@FilterButton1_Callback);

FilterButton2 = uicontrol(f,'Style','togglebutton',...
        'Units','characters',...
        'String','Filter 2nd',...
        'Parent',RightPanel,...
        'TooltipString','Use Filtered Data?',...
        'Position',[79 0 6 1],...
        'Callback',@FilterButton2_Callback);
    
%% Add a counts button
CountsButton1 = uicontrol(f,'Style','togglebutton',...
        'Units','characters',...
        'String','Counts',...
        'Parent',CenterPanel,...
        'TooltipString','Use Filtered Data?',...
        'Position',[79 0 6 1],...
        'Callback',@CountsButton1_Callback);

CountsButton2 = uicontrol(f,'Style','togglebutton',...
        'Units','characters',...
        'String','Counts',...
        'Parent',RightPanel,...
        'TooltipString','Use Filtered Data?',...
        'Position',[79 0 6 1],...
        'Callback',@CountsButton2_Callback);
    

%% Add popup menu
popup = uicontrol(f,'Style','popupmenu',...
        'Units','characters',...
        'Position',[1 0 36 1],...
        'Parent',CenterPanel,...
        'String',{charts.name},...
        'Enable','off',...
        'TooltipString','Pre-defined plot sets',...
        'Callback',@popup_Callback);
popupd1 = uicontrol(f,'Style','popupmenu',...
        'Units','characters',...
        'Position',[1 38 36 1],...
        'Parent',CenterPanel,...
        'String','Group 1 data sets',...
        'Enable','off',...
        'TooltipString','Group 1 data sets',...
        'Callback',@popup_Callback);
popupd2 = uicontrol(f,'Style','popupmenu',...
        'Units','characters',...
        'Position',[1 38 36 1],...
        'Parent',RightPanel,...
        'String','Group 2 data sets',...
        'Enable','off',...
        'TooltipString','Group 2 data sets',...
        'Callback',@popup_Callback);

%% Add slider
slider = uicontrol(f,'Style','slider',...
        'Units','characters',...
        'Position',[85 0 27 1],...
        'Parent',RightPanel,...
        'SliderStep',[.2 .2],...
        'Value',2,...
        'Max',6,...
        'Min',1,...
        'String','Plots',...
        'TooltipString','Changes number of plots',...
        'Callback',@slider_Callback);
    
%% Add grid pushbotton
GridButton = uicontrol(f,'Style','togglebutton',...
        'Parent',RightPanel,...
        'Units','characters',...
        'String','Grid',...
        'Position',[79 0 6 1],...
        'TooltipString','Turns on grid lines',...
        'Callback',@GridButton_Callback);
            
%% Add link pushbotton
LinkButton = uicontrol(f,'Style','togglebutton',...
        'Parent',RightPanel,...
        'Units','characters',...
        'String','Link',...
        'Position',[79 0 6 1],...
        'Value',1,...
        'TooltipString','Links the x-axes together',...
        'Callback',@LinkButton_Callback);
    
%% Add MultiPlot button
MultiPlotButton = uicontrol(f,'Style','togglebutton',...
        'Parent',RightPanel,...
        'Units','characters',...
        'String','Mult',...
        'Value',0,...
        'Position',[79 0 6 1],...
        'TooltipString','Combine plots together on one axes',...
        'Callback',@MultiPlotButton_Callback);
    
%% Add analysis options

PSDAvEdit = uicontrol(f,'Style','edit',...
        'Units','characters',...
        'Parent',PSDPanel,...
        'TooltipString','PSD Averaging Size',...
        'String',num2str(Spa_Av_Num),...
        'Position',[5 3 3 3],...
        'Callback',@AnaylsisOptions_Callback);
    
PSDAvText = uicontrol(f,'Style','text',...
         'Units','characters',...
        'Parent',PSDPanel,...
        'String', 'Av Size');
    
PSDUpperEdit = uicontrol(f,'Style','edit',...
        'Units','characters',...
        'Parent',PSDPanel,...
        'TooltipString','PSD Upper Frequency',...
        'String',num2str(PSDUpper),...
        'Position',[5 3 3 3],...
        'Callback',@AnaylsisOptions_Callback);
    
PSDUpperText = uicontrol(f,'Style','text',...
         'Units','characters',...
        'Parent',PSDPanel,...
        'String', 'Upper Limit');
PSDLowerEdit = uicontrol(f,'Style','edit',...
        'Units','characters',...
        'Parent',PSDPanel,...
        'TooltipString','PSD Lower Frequency',...
        'String',num2str(PSDLower),...
        'Position',[5 3 3 3],...
        'Callback',@AnaylsisOptions_Callback);
    
PSDLowerText = uicontrol(f,'Style','text',...
         'Units','characters',...
        'Parent',PSDPanel,...
        'String', 'Lower Limit');
    
WFWindowLengthEdit = uicontrol(f,'Style','edit',...
        'Units','characters',...
        'Parent',WFPanel,...
        'TooltipString','WF Window Size (s)',...
        'String',num2str(WFWindowLength),...
        'Position',[1 1 1 1],...
        'Callback',@AnaylsisOptions_Callback);
    
WFWindowLengthText = uicontrol(f,'Style','text',...
        'Units','characters',...
        'Parent',WFPanel,...
        'String', 'Wndw Size');
    
WFWindowStepEdit = uicontrol(f,'Style','edit',...
        'Units','characters',...
        'Parent',WFPanel,...
        'TooltipString','WF step Size (s)',...
        'String',num2str(WFWindowStep),...
        'Position',[1 1 1 1],...
        'Callback',@AnaylsisOptions_Callback);

WFWindowStepText = uicontrol(f,'Style','text',...
        'Units','characters',...
        'Parent',WFPanel,...
        'String', 'Step Size');    
    
WFResampEdit = uicontrol(f,'Style','edit',...
        'Units','characters',...
        'Parent',WFPanel,...
        'TooltipString','WF resampling',...
        'String',num2str(WFResamp),...
        'Position',[1 1 1 1],...
        'Callback',@AnaylsisOptions_Callback);
    
WFResampText = uicontrol(f,'Style','text',...
        'Units','characters',...
        'Parent',WFPanel,...
        'String', 'Resampling');      
    
WFDistortPop = uicontrol(f,'Style','popupmenu',...
        'Units','characters',...
        'Parent',WFPanel,...
        'TooltipString','Whether or not to distort',...
        'String',{'No log scaling','Log scaling'},...
        'Value',WFDistort + 1,...
        'Position',[1 1 1 1],...
        'Callback',@AnaylsisOptions_Callback);
    
WFInterpolatePop = uicontrol(f,'Style','popupmenu',...
        'Units','characters',...
        'Parent',WFPanel,...
        'TooltipString','Whether or not to interpolate',...
        'String',{'Flat Shading','Interp Shading'},...
        'Value',WFInterpolate + 1,...
        'Position',[1 1 1 1],...
        'Callback',@AnaylsisOptions_Callback);
    
WFPCountEdit = uicontrol(f,'Style','edit',...
        'Units','characters',...
        'Parent',WFPanel,...
        'TooltipString','Number of P-Lines to show',...
        'String',num2str(WFPCount),...
        'Position',[1 1 1 1],...
        'Callback',@AnaylsisOptions_Callback);
   
WFPCountText = uicontrol(f,'Style','text',...
        'Units','characters',...
        'Parent',WFPanel,...
        'String', 'Num P Lines');     
    
WFFreqLowerEdit = uicontrol(f,'Style','edit',...
        'Units','characters',...
        'Parent',WFPanel,...
        'TooltipString','Lower frequency for display',...
        'String',num2str(WFFReqRange(1)),...
        'Position',[1 1 1 1],...
        'Callback',@AnaylsisOptions_Callback);
    
WFFreqLowerText = uicontrol(f,'Style','text',...
        'Units','characters',...
        'Parent',WFPanel,...
        'String', 'Freq Lower');     
    
WFFreqUpperEdit = uicontrol(f,'Style','edit',...
        'Units','characters',...
        'Parent',WFPanel,...
        'TooltipString','Upper frequency for display',...
        'String',num2str(WFFReqRange(2)),...
        'Position',[1 1 1 1],...
        'Callback',@AnaylsisOptions_Callback);
    
WFFreqUpperText = uicontrol(f,'Style','text',...
        'Units','characters',...
        'Parent',WFPanel,...
        'String', 'Freq Upper');    
    
WFBinLowerEdit = uicontrol(f,'Style','edit',...
        'Units','characters',...
        'Parent',WFPanel,...
        'TooltipString','Lower bin value for display',...
        'String',num2str(WFBinRange(1)),...
        'Position',[1 1 1 1],...
        'Callback',@AnaylsisOptions_Callback);
    
WFBinLowerText = uicontrol(f,'Style','text',...
        'Units','characters',...
        'Parent',WFPanel,...
        'String', 'Bin Lower');     
    
WFBinUpperEdit = uicontrol(f,'Style','edit',...
        'Units','characters',...
        'Parent',WFPanel,...
        'TooltipString','Upper bin for display',...
        'String',num2str(WFBinRange(2)),...
        'Position',[1 1 1 1],...
        'Callback',@AnaylsisOptions_Callback);
    
WFBinUpperText = uicontrol(f,'Style','text',...
        'Units','characters',...
        'Parent',WFPanel,...
        'String', 'Bin Upper');   
    
WFNumBinsEdit = uicontrol(f,'Style','edit',...
        'Units','characters',...
        'Parent',WFPanel,...
        'TooltipString','Number of bins',...
        'String',num2str(WFNumBins),...
        'Position',[1 1 1 1],...
        'Callback',@AnaylsisOptions_Callback);
    
WFNumBinsText = uicontrol(f,'Style','text',...
        'Units','characters',...
        'Parent',WFPanel,...
        'String', 'RPM Bins');     
    
WFLSSPop = uicontrol(f,'Style','popupmenu',...
        'Units','characters',...
        'Parent',WFPanel,...
        'TooltipString','Whether or not to bin against RPM or Wind Speed',...
        'String',{'Time-Based WF','LSSRPM Binning','Windspeed Binning'},...
        'Value',WFLSS + 1,...
        'Position',[1 1 1 1],...
        'Callback',@AnaylsisOptions_Callback);
    
WFControlOnlyPop = uicontrol(f,'Style','popupmenu',...
        'Units','characters',...
        'Parent',WFPanel,...
        'TooltipString','Whether or not to only use control modes',...
        'String',{'Use all data','Control modes only'},...
        'Value',WFControlOnly + 1,...
        'Position',[1 1 1 1],...
        'Callback',@AnaylsisOptions_Callback);

WFSliceLowerEdit = uicontrol(f,'Style','edit',...
        'Units','characters',...
        'Parent',WFPanel,...
        'TooltipString','Lower frequency for slice',...
        'String',num2str(WFSliceRange(1)),...
        'Position',[1 1 1 1],...
        'Callback',@AnaylsisOptions_Callback);
    
WFSliceLowerText = uicontrol(f,'Style','text',...
        'Units','characters',...
        'Parent',WFPanel,...
        'String', 'Slice Lower');     
    
WFSliceUpperEdit = uicontrol(f,'Style','edit',...
        'Units','characters',...
        'Parent',WFPanel,...
        'TooltipString','Upper frequency for slice',...
        'String',num2str(WFSliceRange(2)),...
        'Position',[1 1 1 1],...
        'Callback',@AnaylsisOptions_Callback);
    
WFSliceUpperText = uicontrol(f,'Style','text',...
        'Units','characters',...
        'Parent',WFPanel,...
        'String', 'Slice Upper'); 
    
WFForceMaxEdit = uicontrol(f,'Style','edit',...
        'Units','characters',...
        'Parent',WFPanel,...
        'TooltipString','Force a maximum in waterfall',...
        'String',num2str(WFForceMax),...
        'Position',[1 1 1 1],...
        'Callback',@AnaylsisOptions_Callback);
    
WFForceMaxText = uicontrol(f,'Style','text',...
        'Units','characters',...
        'Parent',WFPanel,...
        'String', 'FrcMax -1off');     
    
   
%% Add file menu
filemenu = uimenu(f,...
        'Parent',f,...
        'Label','File',...
        'Tag','FileMenu',...
        'Callback',@FileMenu_Callback);
    
openmenu1 = uimenu(f,'Parent',filemenu,...
        'Accelerator','O',...
        'Label','Open 1st data set(s) ...',...
        'Tag','openmenu1Item',...
        'Callback',@openmenu1Item_Callback);

openmenu2 = uimenu(f,'Parent',filemenu,...
        'Label','Open 2nd data set(s) ...',...
        'Tag','openmenu2Item',...
        'Callback',@openmenu2Item_Callback);
    
savechartmenu = uimenu(f,'Parent',filemenu,...
        'Label','Save chart ...',...
        'Enable','off',...
        'Callback',@SaveChart_Callback);
           
closemenu = uimenu(f,'Parent',filemenu,...
        'Label','Close',...
        'Separator','on',...
        'Tag','CloseMenuItem',...
        'Callback',@CloseMenuItem_Callback);

%% Add data menu
datamenu = uimenu(f,...
    'Parent',f,...
    'Label','Data',...
    'Tag','DataMenu');%,...
 %   'Callback',@FileMenu_Callback);
 
 
exportDataMenu = uimenu(f,'Parent',datamenu,...
        'Label','Export all data ...',...
        'Accelerator','e',...
        'Callback',@exportAllData_Callback);
    
exportmenu = uimenu(f,'Parent',datamenu,...
        'Label','Export plots',...
        'Accelerator','p',...
        'Callback',@ExportChart_Callback);
    
fillMenu = uimenu(f,'Parent',datamenu,...
        'Label','Fill data set 2 ...',...
        'Accelerator','f',...
        'Callback',@fill_Callback);
    
%% Add options menu    
    
optionsmenu = uimenu(f,...
    'Parent',f,...
    'Label','Options',...
    'Tag','OptionsMenu');%,...
 %   'Callback',@FileMenu_Callback);
 
 %% Add help menu    
    
helpmenu = uimenu(f,...
    'Parent',f,...
    'Label','Help',...
    'Tag','HelpMenu');%,...
 %   'Callback',@FileMenu_Callback);
 
aboutHelpMenu = uimenu(f,'Parent',helpmenu,...
        'Label','About ...',...
        'Callback',@About_Callback);
 
%% Link axes
linkaxes(a,'x');

%% ------------ Basic Callback Functions ----------------------------------
% Add callback functions now, functions initiated by button pressing
%  Start with basic functions and then go through analysis
%--------------------------------------------------------------------------

%% Figure resize function
function figResize(src,evt)
    fpos = get(f,'Position');
    set(AnalysisPanel,'Position',...
        [fpos(3)-25 0 25 fpos(4)])
            set(PSDPanel,'Position',...
            [0 fpos(4) - 7 25 6])
            set(WFPanel,'Position',...
            [0 0 25 fpos(4)-7])
    set(RightPanel,'Position',...
        [fpos(3)-63 0 38 fpos(4)])
    set(CenterPanel,'Position',...
        [fpos(3)-101 0 38 fpos(4)])
    set(LeftPanel,'Position',...
        [0 0 fpos(3)-101 fpos(4)]);
    
        fpos = get(WFPanel,'Position');
        %Also on panel resize repostion the anaylsis optoins
        set(PSDAvEdit,'Position',[1 0.5 7 1]);
        set(PSDAvText,'Position',[8 0.5 20 1]);
        set(PSDLowerEdit,'Position',[1 3.5 7 1]);
        set(PSDLowerText,'Position',[8 3.5 20 1]);
        set(PSDUpperEdit,'Position',[1 2 7 1]);
        set(PSDUpperText,'Position',[8 2 20 1]);
        set(WFWindowLengthEdit ,'Position',[1 fpos(4) - 3 7 1]);
        set(WFWindowLengthText ,'Position',[8 fpos(4) - 3 20 1]);
        set(WFWindowStepEdit,'Position',[1 fpos(4) - 4.5 7 1]);
        set(WFWindowStepText,'Position',[8 fpos(4) - 4.5 20 1]);
        set(WFResampEdit,'Position',[1 fpos(4) - 6 7 1]);
        set(WFResampText,'Position',[8 fpos(4) - 6 20 1]);
        set(WFDistortPop,'Position',[1 fpos(4) - 7.5 23 1]);
        set(WFInterpolatePop ,'Position',[1 fpos(4) - 9.5 23 1]);
        set(WFPCountEdit,'Position',[1 fpos(4) - 11.5 7 1]);
        set(WFPCountText,'Position',[8 fpos(4) - 11.5 20 1]);
        set(WFFreqLowerEdit,'Position',[1 fpos(4) - 13 7 1]);
        set(WFFreqLowerText,'Position',[8 fpos(4) - 13 20 1]);
        set(WFFreqUpperEdit,'Position',[1 fpos(4) - 14.5 7 1]);
        set(WFFreqUpperText,'Position',[8 fpos(4) - 14.5 20 1]);
        
        set(WFBinLowerEdit,'Position',[1 fpos(4) - 16 7 1]);
        set(WFBinLowerText,'Position',[8 fpos(4) - 16 20 1]);
        set(WFBinUpperEdit,'Position',[1 fpos(4) - 17.5 7 1]);
        set(WFBinUpperText,'Position',[8 fpos(4) - 17.5 20 1]);
        
        
        set(WFNumBinsEdit,'Position',[1 fpos(4) - 19 7 1]);
        set(WFNumBinsText,'Position',[8 fpos(4) - 19 20 1]);
        set(WFLSSPop,'Position',[1 fpos(4) - 20.5 23 1]);
        set(WFControlOnlyPop,'Position',[1 fpos(4) - 22.5 23 1]);
        set(WFSliceLowerEdit,'Position',[1 fpos(4) - 24.5 7 1]);
        set(WFSliceLowerText,'Position',[8 fpos(4) - 24.5 20 1]);
        set(WFSliceUpperEdit,'Position',[1 fpos(4) - 26 7 1]);
        set(WFSliceUpperText,'Position',[8 fpos(4) - 26 20 1]);
        set(WFForceMaxEdit,'Position',[1 fpos(4) - 27.5 7 1]);
        set(WFForceMaxText,'Position',[7.5 fpos(4) - 27.5 20 1]);
end
    
%% Panel resize function
function PanelResize(src,evt)
    
    %this function is called when the figure is resized and repositions and
    %refreshes all the buttons and widgets
    
    %first work on the center panel
    rpos = get(CenterPanel,'Position');
    
    %get number of figures
    num=get(slider,'Value');
    
    %get panel height
    height=((rpos(4)-2)/num)-5;
    
    %position list boxes and clearbuttons
    for i=1:6
        set(ListBox(i),'Position',[rpos(3)-36 ...
            ((2*num-(2*i-1))/...
              (num*2))*rpos(4)*0.98-(height/2.0)+1.25 34 height]);
        set(ClearButton(i),'Position',[rpos(3)-36 ...
            ((2*num-(2*i-1))/...
              (num*2))*rpos(4)*0.98-((height/2.0)+1.2)+1.25 34 1]);
    end

    %position various buttons
    set(GridButton,'Position',...
        [rpos(3)-38 0.1 6 1]);
    set(LinkButton,'Position',...
        [rpos(3)-31 0.1 6 1]);
    set(MultiPlotButton,'Position',...
        [rpos(3)-24 0.1 6 1]);   
    set(slider,'Position',...
        [rpos(3)-17 0.1 17 1]);
    set(popup,'Position',...
        [rpos(3)-37 0.6 36 1]);
    set(popupd1,'Position',...
        [rpos(3)-37 rpos(4)-1.4 36 1]);
    set(popupd2,'Position',...
        [rpos(3)-37 rpos(4)-1.4 36 1]);
    set(FilterButton2,'Position',...
        [rpos(3)-36 1.5 17 1.1]);
     set(FilterButton1,'Position',...
        [rpos(3)-36 1.5 17 1.1]);
    set(CountsButton2,'Position',...
        [rpos(3)-19 1.5 17 1.1]);
     set(CountsButton1,'Position',...
        [rpos(3)-19 1.5 17 1.1]);
    
    
    %now work on the right panel
    rpos = get(RightPanel,'Position');
    for i=7:12
        set(ListBox(i),'Position',[rpos(3)-36 ...
            ((2*num-(2*(i-6)-1))/...
              (num*2))*rpos(4)*0.98-(height/2)+1.25 34 height]);
        set(ClearButton(i),'Position',[rpos(3)-36 ...
            ((2*num-(2*(i-6)-1))/...
              (num*2))*rpos(4)*0.98-((height/2)+1.2)+1.25 34 1]);
    end
    
    %Now position analysis buttons in the left panel
    rpos = get(LeftPanel,'Position');
    
    %Get a step size based on panel size and number of figures
    step = rpos(4)/(num*2);
   % btnHeight = (rpos(4)/num)/numAnalBtn;
    
    %Position the analysis buttons
    for i=1:6
     set(ExpButton(i),'Position',[rpos(3)-9 ...
          rpos(4) - step - (i-1)*2*step + 3 ...
              10 1]);
     set(CollectiveButton(i),'Position',[rpos(3)-9 ...
          rpos(4) - step - (i-1)*2*step + 2 ...
              3 1]);
     set(CosineButton(i),'Position',[rpos(3)-6 ...
          rpos(4) - step - (i-1)*2*step + 2 ...
              3 1]);
     set(SineButton(i),'Position',[rpos(3) - 3 ...
          rpos(4) - step - (i-1)*2*step + 2 ...
              3 1]);
     set(MinusButton(i),'Position',[rpos(3) - 0 ...
          rpos(4) - step - (i-1)*2*step + 2 ...
              3 1]);
    set(OopButton(i),'Position',[rpos(3) - 9 ...
          rpos(4) - step - (i-1)*2*step + 1 ...
              5 1]);
    set(InpButton(i),'Position',[rpos(3) - 4 ...
          rpos(4) - step - (i-1)*2*step + 1 ...
              5 1]);
     set(FFTButton(i),'Position',[rpos(3)-9 ...
          rpos(4) - step - (i-1)*2*step ...
              10 1]);
     set(PSDButton(i),'Position',[rpos(3)-9 ...
          rpos(4) - step - (i-1)*2*step - 1 ...
              10 1]);
     set(OnePFFTButton(i),'Position',[rpos(3)-9 ...
          rpos(4) - step - (i-1)*2*step - 2 ...
              10 1]);
     set(WFButton(i),'Position',[rpos(3)-9 ...
          rpos(4) - step - (i-1)*2*step - 3 ...
              10 1]);
     set(WFSliceButton(i),'Position',[rpos(3)-9 ...
          rpos(4) - step - (i-1)*2*step - 4 ...
              10 1]);
    end
    
    %Do some refreshing to force redrawing
   % refresh(f) 
   % pause(0.5)
    refresh(f)
    
end

%% FileMenu Callback function
function FileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

%% openmenu1Item Callback function
function openmenu1Item_Callback(hObject, eventdata, handles)
% hObject    handle to openmenu1Item (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    %this function (and its dual for open 2nd data set) load into a memory
    %a CART 2 or CART 3 data file using the loading scripts

   % path=get(openmenu1,'userdata');
    [file,path] = uigetfile('*.DAT',...
                        'Open 1st data set(s)',...
                        'MultiSelect','On');
    set(openmenu1,'userdata',path);
    if ~isequal(file,0)
        d=zeros(1,'single');
        % When one file is selected, convert from string to cell array
        if ~iscellstr(file) file=cellstr(file);end;
        file=sort(file);
        
        %Determine FPS by checking filelength to determine Cart 2 or 3
        if(length(file{1})<20)
            FPS(1) = 100;
            alpha(1) = 1 - exp(-(1/FPS(1))/1.0);
        else
            FPS(1) = 400;
            alpha(1) = 1 - exp(-(1/FPS(1))/1.0);
        end
        
        %grab the header and refresh the listboxes
        hdr = cartLoadHdrU([path char(file(1))]);
        for i=1:6
            Hold_sel = get(ListBox(i),'Value');
            ListBox(i) = uicontrol(f,'Style','ListBox',...
            'Units','characters',...
            'Position',[80 22 34 6],...
            'BackgroundColor','white',...
            'String',hdr(:,1),...
            'Parent',CenterPanel,...
            'TooltipString','Select multiple with ctrl/shift',...
            'Max',2,...
            'Value',[],...
            'Callback',@ListBox_Callback);
            if i>6 set(ListBox(i),'Parent',RightPanel);end;
            if(~isempty(Hold_sel))
                set(ListBox(i),'Value',Hold_sel);
            end
        end
        
        %Find and save the row which contains the LSSRPM (for 1P)
        for i = 1:size(hdr,1)
            if (strcmp(hdr{i,1},'LSS RPM'))
                LSSRPM(1) = i;
            end
        end
        
        %Find and save the row which contains the LSS Position (for 1P)
        for i = 1:size(hdr,1)
            if (strcmp(hdr{i,1},'LSS Position') || strcmp(hdr{i,1},'LSS position'))
                LSSPOS(1) = i;
            end
        end
        
        %Find and save the column which contains the Command State
        for i = 1:size(hdr,1)
            if (strcmp(hdr{i,1},'command state'))
                COMCOL(1) = i;
            end
        end
        
        %Find and save the column which contains the Command State
        for i = 1:size(hdr,1)
            if (strcmp(hdr{i,1},'controller state'))
                CNTCOL(1) = i;
            end
        end
        
        %Find and save the column which contains the Blade 1 Pitch Angle
        for i = 1:size(hdr,1)
            if (strcmp(hdr{i,1},'Blade 1 Pitch') || strcmp(hdr{i,1},'Blade 1 pitch angle'))
                B1COL(1) = i;
            end
        end
        
        %Find and save the column which contains the Blade 2 Pitch Angle
        for i = 1:size(hdr,1)
            if (strcmp(hdr{i,1},'Blade 2 Pitch') || strcmp(hdr{i,1},'Blade 2 pitch angle'))
                B2COL(1) = i;
            end
        end
        
        %Find and save the column which contains the Blade 3 Pitch Angle
        for i = 1:size(hdr,1)
            if (strcmp(hdr{i,1},'Blade 3 Pitch') || strcmp(hdr{i,1},'Blade 3 pitch angle'))
                B3COL(1) = i;
            end
        end
        
        %Find and save the column which contains the 37 m Wind speed
        for i = 1:size(hdr,1)
            if (strcmp(hdr{i,1},'Met wind speed 36.6m') || strcmp(hdr{i,1},'Windspeed 36.6m'))
                MET37WSCOL(1) = i;
            end
        end
        
        
        %Load the data
        disp('Loading in data...')
        for i=1:length(file)
           disp(['... File ' num2str(i) ' of ' num2str(length(file))])
           tempdata=cast(loadcartU(...
               [path char(file(i))]),'single');
           if(length(d)>1) d=vertcat(d,tempdata);
           else d=tempdata;end;
        end
        
        %Now derived filtered data (using very basic way)
        disp('Filtering data...')
        d_filt = zeros(size(d));
        
        for chan = 1:size(d,2)
            if (mod(chan,10) == 0)
                disp(['... Channel ' num2str(chan) ' of ' num2str(size(d,2))])
            end
            for samp = 2:size(d,1)
                d_filt(samp,chan) = alpha(1) * d(samp,chan) + (1 - alpha(1)) * d_filt(samp-1,chan);
            end
        end
        
%         %Now derived filtered data (using very butterworth filter and filtfilt)
%         disp('Filtering data...')
%         d_filt = zeros(size(d));
%         [bParam,aParam] = butter(4,4/(FPS(1)/2),'low');%4 pole Butterworth with 2 second cut-off
%         for chan = 1:size(d,2)
%             if (mod(chan,10) == 0)
%                 disp(['... Channel ' num2str(chan) ' of ' num2str(size(d,2))])
%             end            
%             d_filt(:,chan) = filtfilt(bParam,aParam,d(:,chan));
%         end
        
        %Now derive counts data
        disp('computing counts...')
        d_counts = zeros(size(d));
        
        %% OLD
%         for chan = 1:size(d,2)
%             if (mod(chan,10) == 0)
%                 disp(['... Channel ' num2str(chan) ' of ' num2str(size(d,2))])
%             end
%             for samp = 1:size(d,1)
%                 d_counts(samp,chan) = (d(samp,chan) - hdr{chan,3}) / hdr{chan,4};
%                 %d_filt(samp,chan) = alpha(1) * d(samp,chan) + (1 - alpha(1)) * d_filt(samp-1,chan);
%             end
%         end       
        
%% NEW
%need here to be careful which is smaller, because old CART files might
%mismatch
      for chan = 1:min(size(hdr,1),size(d,2))
            if (mod(chan,10) == 0)
                disp(['... Channel ' num2str(chan) ' of ' num2str(min(size(hdr,1),size(d,2)))])
            end
            d_counts(:,chan) = (d(:,chan) - hdr{chan,3}) ./ hdr{chan,4};
      end   
        
%% END        
        disp('Loading and filtering completed')
        
        %Adjust button and listbox properties
        for i=1:6
            set(ListBox(i),'Enable','on');
        end
        set(popup,'Enable','on');
        set(popupd1,'Enable','on');
        set(popupd1,'String',file);
        set(f,'Name',file{1});
        set(savechartmenu,'Enable','on');
        x=(0:length(d)-1)/FPS(1);
    
    
        %Paul Fleming addition:
        ForceRedraw = true;  %Force a redraw
        ListBox_Callback()

        PanelResize()%Call the panel resize function now to refresh
    end
end

%% openmenu2Item Callback function
function openmenu2Item_Callback(hObject, eventdata, handles)
% hObject    handle to openmenu2Item (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  %  path=get(openmenu2,'userdata');
    [file,path] = uigetfile('*.DAT',...
                        'Open 2nd data set(s)',...
                        'MultiSelect','On');
    set(openmenu2,'userdata',path);
    if ~isequal(file,0)
        d2=zeros(1,'single');
        % When one file is selected, convert from string to cell array
        if ~iscellstr(file) file=cellstr(file);end;
        file=sort(file);
        
        %Determine FPS by checking filelength to determine Cart 2 or 3
        if(length(file{1})<20)
            FPS(2) = 100;
            alpha(2) = 1 - exp(-(1/FPS(2))/1.0);
        else
            FPS(2) = 400;
            alpha(2) = 1 - exp(-(1/FPS(2))/1.0);
        end
        
        %grab the header and refresh the listboxes
        hdr = cartLoadHdrU([path char(file(1))]);
        for i=7:12
            Hold_sel = get(ListBox(i),'Value');
            ListBox(i) = uicontrol(f,'Style','ListBox',...
            'Units','characters',...
            'Position',[80 22 34 6],...
            'BackgroundColor','white',...
            'String',hdr(:,1),...
            'Parent',CenterPanel,...
            'TooltipString','Select multiple with ctrl/shift',...
            'Max',2,...
            'Value',[],...
            'Callback',@ListBox_Callback);
            if i>6 set(ListBox(i),'Parent',RightPanel);end;
            if(~isempty(Hold_sel))
                set(ListBox(i),'Value',Hold_sel);
            end
        end

       %Find and save the row which contains the LSSRPM (for 1P)
        for i = 1:size(hdr,1)
            if (strcmp(hdr{i,1},'LSS RPM'))
                LSSRPM(2) = i;
            end
        end
        
        %Find and save the row which contains the LSS Position (for 1P)
        for i = 1:size(hdr,1)
            if (strcmp(hdr{i,1},'LSS Position') || strcmp(hdr{i,1},'LSS position'))
                LSSPOS(2) = i;
            end
        end
        
       %Find and save the column which contains the Command State
        for i = 1:size(hdr,1)
            if (strcmp(hdr{i,1},'command state'))
                COMCOL(2) = i;
            end
        end
        
        %Find and save the column which contains the Command State
        for i = 1:size(hdr,1)
            if (strcmp(hdr{i,1},'controller state'))
                CNTCOL(2) = i;
            end
        end
        
        %Find and save the column which contains the Blade 1 Pitch Angle
        for i = 1:size(hdr,1)
            if (strcmp(hdr{i,1},'Blade 1 Pitch') || strcmp(hdr{i,1},'Blade 1 pitch angle'))
                B1COL(2) = i;
            end
        end
        
        %Find and save the column which contains the Blade 2 Pitch Angle
        for i = 1:size(hdr,1)
            if (strcmp(hdr{i,1},'Blade 2 Pitch') || strcmp(hdr{i,1},'Blade 2 pitch angle'))
                B2COL(2) = i;
            end
        end
        
        %Find and save the column which contains the Blade 3 Pitch Angle
        for i = 1:size(hdr,1)
            if (strcmp(hdr{i,1},'Blade 3 Pitch') || strcmp(hdr{i,1},'Blade 3 pitch angle'))
                B3COL(2) = i;
            end
        end
        
        %Find and save the column which contains the 37 m Wind speed
        for i = 1:size(hdr,1)
            if (strcmp(hdr{i,1},'Met wind speed 36.6m') || strcmp(hdr{i,1},'Windspeed 36.6m'))
                MET37WSCOL(2) = i;
            end
        end
        
        
       disp('Loading data...')
        for i=1:length(file)
           disp(['... File ' num2str(i) ' of ' num2str(length(file))])
           tempdata=cast(loadcartU(...
               [path char(file(i))]),'single');
           if(length(d2)>1) d2=vertcat(d2,tempdata);
           else d2=tempdata;end;
        end
        disp('Filtering data')
        
        %Now derived filtered data
        d_filt2 = zeros(size(d2));
        for chan = 1:size(d2,2)
            if (mod(chan,10) == 0)
                disp(['... Channel ' num2str(chan) ' of ' num2str(size(d2,2))])
            end
            for samp = 2:size(d2,1)
                d_filt2(samp,chan) = alpha(2) * d2(samp,chan) + (1 - alpha(2)) * d_filt2(samp-1,chan);
            end

        end
%         
%                 %Now derived filtered data (using very butterworth filter and filtfilt)
%         disp('Filtering data...')
%         d_filt2 = zeros(size(d2));
%         [bParam,aParam] = butter(4,4/(FPS(2)/2),'low');%4 pole Butterworth with 2 second cut-off
%         for chan = 1:size(d2,2)
%             if (mod(chan,10) == 0)
%                 disp(['... Channel ' num2str(chan) ' of ' num2str(size(d2,2))])
%             end            
%             d_filt2(:,chan) = filtfilt(bParam,aParam,d2(:,chan));
%         end
%           
%% NEW
%need here to be careful which is smaller, because old CART files might
%mismatch
        %Now derive counts data
        disp('computing counts...')
        d_counts2 = zeros(size(d2));
      for chan = 1:min(size(hdr,1),size(d2,2))
            if (mod(chan,10) == 0)
                disp(['... Channel ' num2str(chan) ' of ' num2str(min(size(hdr,1),size(d2,2)))])
            end
            d_counts2(:,chan) = (d2(:,chan) - hdr{chan,3}) ./ hdr{chan,4};
      end   


        disp('Loading and filtering completed')
        
        for i=7:12
            set(ListBox(i),'Enable','on');
        end
        set(popup,'Enable','on');
        set(popupd2,'Enable','on');
        set(popupd2,'String',file);
        set(savechartmenu,'Enable','on');
        x2=(0:length(d2)-1)/FPS(2);
    
        %Paul Fleming addition:
        ForceRedraw = true;  %Force a redraw
        ListBox_Callback()

        PanelResize()%Call the panel resize function now to refresh
    end
end

%% SaveChart Callback function
function SaveChart_Callback(hObject, eventdata, handles)
% hObject    handle to openmenu1Item (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

options.Resize='off';
options.WindowStyle='normal';
options.Interpreter='none';

chartname = inputdlg({'Enter chart name'},...
            'Chart name',1,{''},options);

    if ~isempty(chartname)
    index=length(charts)+1;
    charts(index).name=char(chartname);
    charts(index).grid=get(GridButton,'Value');
    charts(index).plots=get(slider,'Value');
    charts(index).link=get(LinkButton,'Value');
    charts(index).data(1:4,1:12)=zeros(4,12);
        for i=1:12
            val=get(ListBox(i),'Value');
            for j=1:length(val)
               charts(index).data(j,i)=val(j);
            end
        end
    
    set(popup,'String',{charts.name});
    end

uisave('charts','charts.mat');
end

%% Export Chart Callback function
function ExportChart_Callback(hObject, eventdata, handles)
% hObject    handle to CloseMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

fpos = get(f,'Position');

f2 = figure('Units','characters',...
        'Position',[0 0 fpos(3)-38 fpos(4)]);

    %Copy the legends
    for i=1:get(slider,'Value');
        nh(i)=copyobj(a(i),f2);
            legend(nh(i),...
                [hdr(get(ListBox(i),'Value'),1)' ...
                 hdr(get(ListBox(i+6),'Value'),1)']);
    end
end

%% fill Callback function
function fill_Callback(hObject, eventdata, handles)
% hObject    handle to CloseMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
   d2 = d;
   d_filt2 = d_filt;
   d_counts2 = d_counts;
   FPS(2) = FPS(1);
   alpha(2) = alpha(1);
   LSSRPM(2) = LSSRPM(1);
   LSSPOS(2) = LSSPOS(1);
        
    %fill in 2nd listbox

    for i=7:12
        Hold_sel = get(ListBox(i),'Value');
        ListBox(i) = uicontrol(f,'Style','ListBox',...
        'Units','characters',...
        'Position',[80 22 34 6],...
        'BackgroundColor','white',...
        'String',hdr(:,1),...
        'Parent',CenterPanel,...
        'TooltipString','Select multiple with ctrl/shift',...
        'Max',2,...
        'Value',[],...
        'Callback',@ListBox_Callback);
        if i>6 set(ListBox(i),'Parent',RightPanel);end;
        if(~isempty(Hold_sel))
            set(ListBox(i),'Value',get(ListBox(i-6),'Value'));
        end
    end
    
     for i=7:12
            set(ListBox(i),'Enable','on');
        end
        set(popup,'Enable','on');
        set(popupd2,'Enable','on');
    
        set(savechartmenu,'Enable','on');
        x2=(0:length(d2)-1)/FPS(2);
    
            %Paul Fleming addition:
        ForceRedraw = true;  %Force a redraw
        ListBox_Callback()

        PanelResize()%Call the panel resize function now to refresh
end

%% Export Chart Callback function
function About_Callback(hObject, eventdata, handles)
% hObject    handle to CloseMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

msgbox('cartplotU - Written by Lee Jay Fingersh and Paul Fleming - July 2011','About cartplotu....')

end

%% CloseMenuItem Callback function
function CloseMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to CloseMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(gcf);
end

%% ListBox Callback function
function ListBox_Callback(hObject, eventdata, handles)
% hObject    handle to ListBoxmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns ListBoxmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ListBoxmenu1

%This function is called when changes in channel selection happen (or
%called from the loaddate function to force a recomputation.  It checks
%what channels are selected in the listbox and plots them to the
%appropriate axes

    for i=1:6
        ListBox_sel_index = get(ListBox(i),'Value');
        ListBox_sel_index2 = get(ListBox(i+6),'Value');
        old_sel_index = get(ListBox(i),'UserData');
        old_sel_index2 = get(ListBox(i+6),'UserData');
        if (~isequal(ListBox_sel_index,old_sel_index) ||...
            ~isequal(ListBox_sel_index2,old_sel_index2) || ...
            ForceRedraw) &&...
           (~isempty(ListBox_sel_index) ||...
            ~isempty(ListBox_sel_index2))
     
            if(~ForceRedraw) %if this is not a forced redraw
                             %save old axes
                HoldAx = get(a(i),'XLim');
            end
        
            if isempty(ListBox_sel_index)
                %decide whether to plot values filtered data,or counts
                if(get(FilterButton2,'Value'))
                    plot(a(i),x2,d_filt2(:,ListBox_sel_index2))
                elseif(get(CountsButton2,'Value'))
                    plot(a(i),x2,d_counts2(:,ListBox_sel_index2))
                else
                    plot(a(i),x2,d2(:,ListBox_sel_index2))
                end
            elseif isempty(ListBox_sel_index2)
                %decide whether to plot values or filtered data
                if(get(FilterButton1,'Value'))
                    plot(a(i),x,d_filt(:,ListBox_sel_index))
                elseif(get(CountsButton1,'Value'))
                    plot(a(i),x,d_counts(:,ListBox_sel_index))
                else
                    plot(a(i),x,d(:,ListBox_sel_index))
                end
            else
                if(~get(FilterButton1,'Value')&&~get(FilterButton2,'Value'))
                    if(get(CountsButton1,'Value') && get(CountsButton2,'Value'))
                        plot(a(i),x,d_counts(:,ListBox_sel_index),x2,d_counts2(:,ListBox_sel_index2));
                    elseif(get(CountsButton1,'Value'))
                        plot(a(i),x,d_counts(:,ListBox_sel_index),x2,d2(:,ListBox_sel_index2));
                    elseif(get(CountsButton2,'Value')) 
                        plot(a(i),x,d(:,ListBox_sel_index),x2,d_counts2(:,ListBox_sel_index2));
                    else
                        plot(a(i),x,d(:,ListBox_sel_index),x2,d2(:,ListBox_sel_index2));
                    end
                elseif(get(FilterButton1,'Value')&&~get(FilterButton2,'Value'))
                    if(get(CountsButton2,'Value'))
                         plot(a(i),x,d_filt(:,ListBox_sel_index),x2,d_counts2(:,ListBox_sel_index2));
                    else
                        plot(a(i),x,d_filt(:,ListBox_sel_index),x2,d2(:,ListBox_sel_index2)); 
                    end
                elseif(~get(FilterButton1,'Value')&&get(FilterButton2,'Value'))
                    if(get(CountsButton1,'Value'))
                        plot(a(i),x,d_counts(:,ListBox_sel_index),x2,d_filt2(:,ListBox_sel_index2));
                    else
                        plot(a(i),x,d(:,ListBox_sel_index),x2,d_filt2(:,ListBox_sel_index2));
                    end
                else                      
                    plot(a(i),x,d_filt(:,ListBox_sel_index),x2,d_filt2(:,ListBox_sel_index2));
                end
            end

            %Label, grid etc plots
            xlabel(a(i),'Seconds');
            
            yl = [hdr(ListBox_sel_index,2)' ...
                  hdr(ListBox_sel_index2,2)'];
            ylt=yl(1);
            for j=2:length(yl)
                ylt=strcat(ylt,{', '},yl(j));
            end
            ylabel(a(i),ylt);
             
            legend(a(i),...
                [hdr(ListBox_sel_index,1)' ...
                 hdr(ListBox_sel_index2,1)']);
            set(ListBox(i),'UserData',ListBox_sel_index);
            
            if get(GridButton,'Value')
                set(a(i),'xgrid','on',...
                         'ygrid','on');
            else
                set(a(i),'xgrid','off',...
                         'ygrid','off');
            end
            
            if(~ForceRedraw) %if this is not a forced redraw
                             %reapply old axes
                set(a(i),'XLim', HoldAx);
            end
            
            %Reset ForceRedraw
            ForceRedraw = false;
        end
    end
end

%% popup menu Callback function
function popup_Callback(hObject, eventdata, handles)
% hObject    handle to ListBoxmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

popup_sel_index=get(popup,'Value');

    for i=1:12
        set(ListBox(i),'Value',...
      charts(popup_sel_index).data(1:...
      length(nonzeros(charts(popup_sel_index).data(:,i))),i));
    end
    
set(GridButton,'Value',charts(popup_sel_index).grid);
set(slider,'Value',charts(popup_sel_index).plots);
set(LinkButton,'Value',charts(popup_sel_index).link);

slider_Callback;
ListBox_Callback;
GridButton_Callback;
LinkButton_Callback;

end

%% slider Callback function
function slider_Callback(hObject, eventdata, handles)
% hObject    handle to ListBoxmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

num=get(slider,'Value');

PanelResize;

    for i=1:6
        set(a(i),'OuterPosition',[0 (num-i)/num 1 1/(num)]);
    end
      
end

%% Clear Button Callback function
function ClearButton_Callback(hObject, eventdata, handles)
% hObject    handle to ListBoxmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    for i=1:12
        if get(ClearButton(i),'Value')
            set(ListBox(i),'Value',[]);
        end
    end

ListBox_Callback;
end

%% Grid Button Callback function
function GridButton_Callback(hObject, eventdata, handles)
% hObject    handle to ListBoxmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    for i=1:6

        if get(GridButton,'Value')
            set(a(i),'xgrid','on',...
                     'ygrid','on');
        else
            set(a(i),'xgrid','off',...
                     'ygrid','off');
        end

    end

end

%% Link Button Callback function
function LinkButton_Callback(hObject, eventdata, handles)
% hObject    handle to ListBoxmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    if get(LinkButton,'Value') == 1
        linkaxes(a,'x');
    else linkaxes(a,'off');
    end

end

%% Multiplot Button Callback function
function MultiPlotButton_Callback(hObject, eventdata, handles)
% hObject    handle to ListBoxmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

   % ColorCountFFT = 1;  %reset color to initial (blue)
    %ColorCountPSD = 1;  %reset color to initial (blue)
end
%% Filter button1 Callback function
function FilterButton1_Callback(hObject, eventdata, handles)
%This function handles clicks of the FilterButton
%There isn't much to do here, just trick the list box call back into
%replotting without rescaling

%Trick it by changing the last values to null so a plot with
%a channel selected will replot without rescaling
for i = 1:6
    set(ListBox(i),'UserData',[]);
end
ListBox_Callback;
end

%% Filter button2 Callback function
function FilterButton2_Callback(hObject, eventdata, handles)
%This function handles clicks of the FilterButton
%There isn't much to do here, just trick the list box call back into
%replotting without rescaling

%Trick it by changing the last values to null so a plot with
%a channel selected will replot without rescaling
for i = 7:12
    set(ListBox(i),'UserData',[]);
end
ListBox_Callback;
end


%% Counts button1 Callback function
function CountsButton1_Callback(hObject, eventdata, handles)
%This function handles clicks of the FilterButton
%There isn't much to do here, just trick the list box call back into
%replotting without rescaling

%Trick it by changing the last values to null so a plot with
%a channel selected will replot without rescaling
for i = 1:6
    set(ListBox(i),'UserData',[]);
end
ListBox_Callback;
end

%% Counts button2 Callback function
function CountsButton2_Callback(hObject, eventdata, handles)
%This function handles clicks of the FilterButton
%There isn't much to do here, just trick the list box call back into
%replotting without rescaling

%Trick it by changing the last values to null so a plot with
%a channel selected will replot without rescaling
for i = 7:12
    set(ListBox(i),'UserData',[]);
end
ListBox_Callback;
end



%% -------------------Analysis buttons-------------------------------------
% The analysis buttons provide a number of analysis tools and generally 
% operate on whatever data is displayed in a given plot
%--------------------------------------------------------------------------

function AnaylsisOptions_Callback(hObject, eventdata, handles)
%If any of the analysis options have changed call this function
    
    %Get the current value for spectral averaging in PSD of FFT functions
    Spa_Av_Num = sscanf(get(PSDAvEdit,'String'),'%d');
    PSDUpper = sscanf(get(PSDUpperEdit,'String'),'%f');
    PSDLower = sscanf(get(PSDLowerEdit,'String'),'%f');
    
                
    WFWindowLength =  sscanf(get(WFWindowLengthEdit,'String'),'%d') ;
    WFWindowStep =  sscanf(get(WFWindowStepEdit,'String'),'%f') ;
    WFResamp = sscanf(get(WFResampEdit,'String'),'%d') ;
    WFDistort = get(WFDistortPop,'Value') - 1;
    WFInterpolate = get(WFInterpolatePop,'Value') - 1;
    WFPCount =sscanf(get(WFPCountEdit,'String'),'%d') ;
    WFFReqRange = [sscanf(get(WFFreqLowerEdit,'String'),'%f') sscanf(get(WFFreqUpperEdit,'String'),'%f')];
    WFBinRange = [sscanf(get(WFBinLowerEdit,'String'),'%f') sscanf(get(WFBinUpperEdit,'String'),'%f')];
    WFNumBins = sscanf(get(WFNumBinsEdit,'String'),'%d') ;
    WFLSS = get(WFLSSPop,'Value') - 1;
    WFControlOnly = get(WFControlOnlyPop,'Value') - 1;
    WFSliceRange = [sscanf(get(WFSliceLowerEdit,'String'),'%f') sscanf(get(WFSliceUpperEdit,'String'),'%f')];
    WFForceMax = sscanf(get(WFForceMaxEdit,'String'),'%f');
end

%% Export All Data Menu Callback function
function exportAllData_Callback(hObject, eventdata, handles)
%Export all data in plots to workspace

%local variables
    %get number of figures
    numFig=get(slider,'Value');
    tdat = [];  %this holds the data matrix
    %legendList = {};  %this will hold all channel names
    legCount = 0; %count of legends in legendList
    
    for i = 1:numFig %loop through figures

        clear tdatCell ttCell
        
        %Get the plot
        pos = get(a(i), 'Children');

        %First grab the representative data
        %tdat for time data
        %tt for time time
        tdatCell = get(pos,'YData');
        ttCell = get(pos,'XData');

        %check if there is only one signal in the plot
        if ~iscell(tdatCell)
            tdat = [tdat;tdatCell];
            tt = ttCell;
            legCount = legCount + 1;
            tempList = hdr(get(ListBox(i),'Value'),1);
            legendList{legCount} = tempList{1};
        else
            %for some reason the rows of tdatCell need to be reversed
            numSig = size(tdatCell,1);
            
            %if there is more than one signal
            %Now loop through all signals in the plot and add to tdat
            tempList = hdr(get(ListBox(i),'Value'),1);
            for sig = numSig : -1 : 1 %for some reason must be done backward
                tdat = [tdat;tdatCell{sig,1}]; %for some reason must be done backwards
                tt = ttCell{sig,1};
                legCount = legCount + 1;
                legendList{legCount} = tempList{numSig - sig + 1}; %correct to forwards
            end
        end
    end

    %Now trim all the data
    %Get the current xlimits
    txlim = get(a(1),'XLim');

    %Now find the given limits within data
    tstart = find(tt>=txlim(1),1);
    tend = find(tt>=txlim(2),1);

    %Trim the data to match
    tdat=tdat(:,tstart:tend);
    tt=tt(tstart:tend);

    %Now export the data to the workspace
    assignin('base','dat',tdat);
    assignin('base','t',tt);
    assignin('base','legendList',legendList);
end

%% Export Button Callback function
function ExpButton_Callback(hObject, eventdata, handles)
%   AS: new code for gathering multiple channels from the export button for a
%   single plot
    %local variables
    tdat = [];  %this holds the data matrix
    legCount = 0; %count of legends in legendList

    for i=1:6
        if get(ExpButton(i),'Value')
            %If we pushed the export button for plot i

            %Get the plot
            pos = get(a(i), 'Children');

            %First grab the representative data
            tdatCell = get(pos,'YData'); %tdatCell for time data
            ttCell = get(pos,'XData'); %ttCell for time time

            %check if there is only one signal in the plot
            if ~iscell(tdatCell)
                %not a cell; only one signal
                tdat = [tdat;tdatCell];
                tt = ttCell;
                legCount = legCount + 1;
                tempList = hdr(get(ListBox(i),'Value'),1);
                legendList{legCount} = tempList{1};
            else
                %for some reason the rows of tdatCell need to be reversed
                numSig = size(tdatCell,1);

                %if there is more than one signal
                %Now loop through all signals in the plot and add to tdat
                tempList = hdr(get(ListBox(i),'Value'),1);
                for sig = numSig : -1 : 1 %for some reason must be done backward
                    tdat = [tdat;tdatCell{sig,1}]; %for some reason must be done backwards
                    tt = ttCell{sig,1};
                    legCount = legCount + 1;
                    legendList{legCount} = tempList{numSig - sig + 1}; %correct to forwards
                end
            end

            %Now trim all the data
            %Get the current xlimits
            txlim = get(a(1),'XLim');

            %Now find the given limits within data
            tstart = find(tt>=txlim(1),1);
            tend = find(tt>=txlim(2),1);

            %Trim the data to match
            tdat=tdat(:,tstart:tend);
            tt=tt(tstart:tend);

            %Now export the data to the workspace
            assignin('base','dat',tdat);
            assignin('base','t',tt);
            assignin('base','legendList',legendList);
        end
    end
    
%   AS: old code for exporting a single channel from a given plot.  It
%   would error if multiple channels were selected for the given plot.  If
%   Paul is okay with the new code, we can get rid of this.
%Export data in plot to workspace
%     for i=1:6
%         if get(ExpButton(i),'Value')
%             %If we pushed the export button for plot i
%             
%             %Get the current xlimits
%             txlim = get(a(i),'XLim');
%                       
%             %Get the plot
%             pos = get(a(i), 'Children');
%             
%             %First grab the representative data
%             %tdat for time data
%             %tt for time time
%             tdat = get(pos,'YData');
%             tt = get(pos,'XData');
%             
%             %Now find the given limits within data
%             tstart = find(tt>=txlim(1),1);
%             tend = find(tt>=txlim(2),1);
%             
%             %Trim the data to match
%             tdat=tdat(tstart:tend);
%             tt=tt(tstart:tend);
%             
%             %Now export the data to the workspace
%             assignin('base','dat',tdat);
%             assignin('base','t',tt);
%         end
%     end
end

%% Collective Button Callback function
function CollectiveButton_Callback(hObject, eventdata, handles)
%Sun the plotted signals into a single plot
    for i=1:6
        if get(CollectiveButton(i),'Value')
            %If we pushed the sum button for plot i
            
            %Get the current xlimits
            txlim = get(a(i),'XLim');
            
            %Get the current ylabel
            ylt = get(a(i),'ylabel');
            
            %Get the plot
            pos = get(a(i), 'Children');
            
            %First grab the representative data
            %tdat for time data
            %tt for time time
            tdat = get(pos,'YData');
            tt = get(pos,'XData');
            
            %Compute the collective signal (for all time)
            tdat_sum = zeros(size(tdat{1}));
            for ser = 1:size(tdat,1)
                tdat_sum=tdat_sum+tdat{ser};
            end
            tt=tt{1};
            
            %Divide the signal by 3 for 3-bladed, 2 for 2-bladed
            tdat_sum = tdat_sum/length(tdat);
            
            %Now plot the data and label
            plot(a(i),tt,tdat_sum)
            xlabel(a(i),'Seconds');
            ylabel(a(i),ylt);
            xlim(txlim);        
            legend(a(i),'MBC Collective of signals');
        %   legend(a(i),['Collective of signals' hdr(ListBox_sel_index,1)' hdr(ListBox_sel_index2,1)']);
            if get(GridButton,'Value')
                set(a(i),'xgrid','on',...
                         'ygrid','on');
            else
                set(a(i),'xgrid','off',...
                         'ygrid','off');
            end
        end
    end
end

%% Cosine Button Callback function
function CosineButton_Callback(hObject, eventdata, handles)
%Find the cosine cyclic signal
    for i=1:6
        if get(CosineButton(i),'Value')
            %If we pushed the sum button for plot i
            
            %Get the current xlimits
            txlim = get(a(i),'XLim');
            
            %Get the current ylabel
            ylt = get(a(i),'ylabel');
            
            %Get the plot
            pos = get(a(i), 'Children');
            
            %First grab the representative data
            %tdat for time data
            %tt for time time
            tdat = get(pos,'YData');
            tt = get(pos,'XData');
            
            %Design a High-pass filter to remove static component
            [bParam,aParam] = butter(4,0.2/(400/2),'high');
            
            
            %Grab the azimuth data
            ListBox_sel_index = get(ListBox(i),'Value');
            if(isempty(ListBox_sel_index)) %If the 1st list box is empty use the second's
                az = d2(:,LSSPOS(2));
            else %Use the first
                az = d(:,LSSPOS(1));
            end
            
            %Convert azimuth to radiuns
            az = az * pi/180;
            
            %Compute the cosine-cyclic signal (for all time)
            tdat_cos = zeros(size(tdat{1}));
            for ser = 1:3 %note that the rows of tdat are backwards
        %        tdat{ser} = detrend(tdat{ser});
                tdat{4 - ser} = filtfilt(bParam,aParam,tdat{4 - ser}); %4 - ser due to backwardness
                tdat_cos = tdat_cos + tdat{4 - ser} .* cos( az' + (ser - 1) * 120 * pi/180);
                %for idx = 1 : size(tdat_cos,2)                 
                %    tdat_cos(idx) = tdat_cos(idx) + tdat{ser}(idx) * cos( az(idx) + (ser - 1) * 120 * pi/180);
                %end
            end
            tt=tt{1};
            
            %Multiply the signal by 2/3
            tdat_cos = tdat_cos * 2/3;
            
            %Now plot the data and label
            plot(a(i),tt,tdat_cos)
            xlabel(a(i),'Seconds');
            ylabel(a(i),ylt);
            xlim(txlim);        
            legend(a(i),'MBC Cosine-Cyclic of signals');
        %   legend(a(i),['Collective of signals' hdr(ListBox_sel_index,1)' hdr(ListBox_sel_index2,1)']);
            if get(GridButton,'Value')
                set(a(i),'xgrid','on',...
                         'ygrid','on');
            else
                set(a(i),'xgrid','off',...
                         'ygrid','off');
            end
        end
    end
end

%% Sine Button Callback function
function SineButton_Callback(hObject, eventdata, handles)
%Find the sine cyclic signal
    for i=1:6
        if get(SineButton(i),'Value')
            %If we pushed the sum button for plot i
            
            %Get the current xlimits
            txlim = get(a(i),'XLim');
            
            %Get the current ylabel
            ylt = get(a(i),'ylabel');
            
            %Get the plot
            pos = get(a(i), 'Children');
            
            %First grab the representative data
            %tdat for time data
            %tt for time time
            tdat = get(pos,'YData');
            tt = get(pos,'XData');
            
            %Design a High-pass filter to remove static component
            [bParam,aParam] = butter(4,0.2/(400/2),'high');
            
            %Grab the azimuth data
            ListBox_sel_index = get(ListBox(i),'Value');
            if(isempty(ListBox_sel_index)) %If the 1st list box is empty use the second's
                az = d2(:,LSSPOS(2));
            else %Use the first
                az = d(:,LSSPOS(1));
            end
            
            %Convert azimuth to radiuns
            az = az * pi/180;
            
            %Compute the cosine-cyclic signal (for all time)
            tdat_sin = zeros(size(tdat{1}));
            for ser = 1:3
                
                tdat{4-ser} = filtfilt(bParam,aParam,tdat{4-ser});
                tdat_sin = tdat_sin + tdat{4-ser} .* sin( az' + (ser - 1) * 120 * pi/180);
                
       %         tdat{ser} = detrend(tdat{ser});
               % for idx = 1 : size(tdat_sin,2)              
               %     tdat_sin(idx) = tdat_sin(idx) + tdat{ser}(idx) * sin( az(idx) + (ser - 1) * 120 * pi/180);
               % end
            end
            tt=tt{1};
           
            
            
            %Multiply the signal by 2/3
            tdat_sin = tdat_sin * 2/3;
            
            %Now plot the data and label
            plot(a(i),tt,tdat_sin)
            xlabel(a(i),'Seconds');
            ylabel(a(i),ylt);
            xlim(txlim);        
            legend(a(i),'MBC Sine-Cyclic of signals');
        %   legend(a(i),['Collective of signals' hdr(ListBox_sel_index,1)' hdr(ListBox_sel_index2,1)']);
            if get(GridButton,'Value')
                set(a(i),'xgrid','on',...
                         'ygrid','on');
            else
                set(a(i),'xgrid','off',...
                         'ygrid','off');
            end
        end
    end
end

%% Minus Button Callback function
function MinusButton_Callback(hObject, eventdata, handles)
    
  %%%Temporary make this button compute shaft moment
  %Find the shaft moment
    for i=1:6
        if get(MinusButton(i),'Value')
            %If we pushed the sum button for plot i
            
            %Get the current xlimits
            txlim = get(a(i),'XLim');
            
            %Get the current ylabel
            ylt = get(a(i),'ylabel');
            
            %Get the plot
            pos = get(a(i), 'Children');
            
            %First grab the representative data
            %tdat for time data
            %tt for time time
            tdat = get(pos,'YData');
            tt = get(pos,'XData');
            
%             %Design a High-pass filter to remove static component
%             [bParam,aParam] = butter(4,0.2/(400/2),'high');
%             
%             %Grab the azimuth data
%             ListBox_sel_index = get(ListBox(i),'Value');
%             if(isempty(ListBox_sel_index)) %If the 1st list box is empty use the second's
%                 az = d2(:,LSSPOS(2));
%             else %Use the first
%                 az = d(:,LSSPOS(1));
%             end
            
            %Convert azimuth to radiuns
%             az = az * pi/180;
            
            %Compute the cosine-cyclic signal (for all time)
            tdat_hub = zeros(size(tdat{1}));
            tdat_hub = tdat_hub + tdat{3} - 0.5 * tdat{2} - 0.5 * tdat{1};
            
%             for ser = 1:3
%                 
%                 tdat{4-ser} = filtfilt(bParam,aParam,tdat{4-ser});
%                 tdat_sin = tdat_sin + tdat{4-ser} .* sin( az' + (ser - 1) * 120 * pi/180);
%                 
%        %         tdat{ser} = detrend(tdat{ser});
%                % for idx = 1 : size(tdat_sin,2)              
%                %     tdat_sin(idx) = tdat_sin(idx) + tdat{ser}(idx) * sin( az(idx) + (ser - 1) * 120 * pi/180);
%                % end
%             end
            tt=tt{1};
           
            
            
            %Multiply the signal by 2/3
%             tdat_sin = tdat_sin * 2/3;
            
            %Now plot the data and label
            plot(a(i),tt,tdat_hub)
            xlabel(a(i),'Seconds');
            ylabel(a(i),ylt);
            xlim(txlim);        
            legend(a(i),'Hub moment');
        %   legend(a(i),['Collective of signals' hdr(ListBox_sel_index,1)' hdr(ListBox_sel_index2,1)']);
            if get(GridButton,'Value')
                set(a(i),'xgrid','on',...
                         'ygrid','on');
            else
                set(a(i),'xgrid','off',...
                         'ygrid','off');
            end
        end
    end
  
%   
% %Sun the plotted signals into a single plot
%     for i=1:6
%         if get(MinusButton(i),'Value')
%             %If we pushed the sum button for plot i
%             
%             %Get the current xlimits
%             txlim = get(a(i),'XLim');
%             
%             %Get the current ylabel
%             ylt = get(a(i),'ylabel');
%             
%             %Get the plot
%             pos = get(a(i), 'Children');
%             
%             %First grab the representative data
%             %tdat for time data
%             %tt for time time
%             tdat = get(pos,'YData');
%             tt = get(pos,'XData');
%             
%             %Compute the difference signal (for all time)
%             tdat_diff = tdat{1} - tdat{2};
%             %tdat_sum = zeros(size(tdat{1}));
%             %for ser = 1:size(tdat,1)
%             %    tdat_sum=tdat_sum+tdat{ser};
%             %end
%             tt=tt{1};
%             
%             %Now plot the data and label
%             plot(a(i),tt,tdat_diff)
%             xlabel(a(i),'Seconds');
%             ylabel(a(i),ylt);
%             xlim(txlim);        
%             legend(a(i),'Difference of signals');
%         %   legend(a(i),['Collective of signals' hdr(ListBox_sel_index,1)' hdr(ListBox_sel_index2,1)']);
%             if get(GridButton,'Value')
%                 set(a(i),'xgrid','on',...
%                          'ygrid','on');
%             else
%                 set(a(i),'xgrid','off',...
%                          'ygrid','off');
%             end
%         end
%     end
end

%% Oop Button Callback function
function OopButton_Callback(hObject, eventdata, handles)
%Find the cosine cyclic signal
    for i=1:6
        if get(OopButton(i),'Value')
            %If we pushed the sum button for plot i
            
            %Get the current xlimits
            txlim = get(a(i),'XLim');
            
            %Get the current ylabel
            ylt = get(a(i),'ylabel');
            
            %Get the plot
            pos = get(a(i), 'Children');
            
            %First grab the representative data
            %tdat for time data
            %tt for time time
            tdat = get(pos,'YData');
            tt = get(pos,'XData');
            
            %Grab pitch angle data
            ListBox_sel_index = get(ListBox(i),'Value');
            if(isempty(ListBox_sel_index)) %If the 1st list box is empty use the second's
                pitch1 = d2(:,B1COL(2));
                pitch2 = d2(:,B2COL(2));
                if (B3COL(2) ~= 0)
                    pitch3 = d2(:,B3COL(2));
                else
                    pitch3 = 0;
                end
                %and switch to second listbox
                 ListBox_sel_index = get(ListBox(i+6),'Value');
                 %grab first name for signle blade case
                 tempList = get(ListBox(i+6),'String');
                 bendName = tempList(ListBox_sel_index(1));
                 
            else %Use the first
                pitch1 = d(:,B1COL(1));
                pitch2 = d(:,B2COL(1));
                if (B3COL(1) ~= 0)
                    pitch3 = d(:,B3COL(1));
                else
                    pitch3 = 0;
                end
                 %grab first name for signle blade case
                 tempList = get(ListBox(i),'String');
                 bendName = tempList(ListBox_sel_index(1));
            end
            
            %Convert pitch to radiuns
            pitch1 = pitch1 * pi/180;
            pitch2 = pitch2 * pi/180;
            pitch3 = pitch3 * pi/180;
            
            %This where things get tricky, we need to figure out what the
            %user wants.  If there are 2 signals, then assume user wants
            %Oop bending for single blade, figure out which blade and use
            %the the appropriate pitch.  If there are 4, assume this is
            %2-bladed average, and if there are 6 assume this is 3-bladed
            %average
            
            if (length(tdat) == 2) %single blade case
                %work out which blade this is
                if (~isempty(strfind(bendName{1},'1'))) %this is blade 1
                    pitch = pitch1;
                    legName = 'Blade 1 Out of Plane';
                elseif (~isempty(strfind(bendName{1},'2'))) %blade 2
                    pitch = pitch2;
                    legName = 'Blade 2 Out of Plane';
                else %blade3
                    pitch = pitch3;
                    legName = 'Blade 3 Out of Plane';
                end
                
                %Grab edge and flap bending
                edge = tdat{2};
                flap = tdat{1};
                
                %Compute Oop
                Oop = flap .* cos(pitch') - edge .* sin(pitch');
            
            elseif (length(tdat) == 4) %two-bladed case
                legName = '2-bladed out of plane';
                
                %Grab edge and flap bending
                edge1 = tdat{4};
                flap1 = tdat{3};
                edge2 = tdat{2};
                flap2 = tdat{1};
                
                %Compute Oop
                Oop1 = flap1 .* cos(pitch1') - edge1 .* sin(pitch1');
                Oop2 = flap2 .* cos(pitch2') - edge2 .* sin(pitch2');
                Oop = mean([Oop1;Oop2]);
             elseif (length(tdat) == 6) %3-bladed case
                legName = '3-bladed out of plane';
                
                %Grab edge and flap bending
                edge1 = tdat{6};
                flap1 = tdat{5};
                edge2 = tdat{4};
                flap2 = tdat{3};
                edge3 = tdat{2};
                flap3 = tdat{1};
                
                %Compute Oop
                Oop1 = flap1 .* cos(pitch1') - edge1 .* sin(pitch1');
                Oop2 = flap2 .* cos(pitch2') - edge2 .* sin(pitch2');
                Oop3 = flap3 .* cos(pitch3') - edge3 .* sin(pitch3');
                Oop = mean([Oop1;Oop2;Oop3]);
            end
            
            %Compress the time to an array
            tt=tt{1};
            
           
            %Now plot the data and label
            plot(a(i),tt,Oop)
            xlabel(a(i),'Seconds');
            ylabel(a(i),'kNm');
            xlim(txlim);        
            legend(a(i),legName);
            if get(GridButton,'Value')
                set(a(i),'xgrid','on',...
                         'ygrid','on');
            else
                set(a(i),'xgrid','off',...
                         'ygrid','off');
            end
        end
    end
end

%% Inp Button Callback function
function InpButton_Callback(hObject, eventdata, handles)
%Find the cosine cyclic signal
    for i=1:6
        if get(InpButton(i),'Value')
            %If we pushed the sum button for plot i
            
            %Get the current xlimits
            txlim = get(a(i),'XLim');
            
            %Get the current ylabel
            ylt = get(a(i),'ylabel');
            
            %Get the plot
            pos = get(a(i), 'Children');
            
            %First grab the representative data
            %tdat for time data
            %tt for time time
            tdat = get(pos,'YData');
            tt = get(pos,'XData');
            
            %Grab pitch angle data
            ListBox_sel_index = get(ListBox(i),'Value');
            if(isempty(ListBox_sel_index)) %If the 1st list box is empty use the second's
                pitch1 = d2(:,B1COL(2));
                pitch2 = d2(:,B2COL(2));
                if (B3COL(2) ~= 0)
                    pitch3 = d2(:,B3COL(2));
                else
                    pitch3 = 0;
                end
                %and switch to second listbox
                 ListBox_sel_index = get(ListBox(i+6),'Value');
                 %grab first name for signle blade case
                 tempList = get(ListBox(i+6),'String');
                 bendName = tempList(ListBox_sel_index(1));
                 
            else %Use the first
                pitch1 = d(:,B1COL(1));
                pitch2 = d(:,B2COL(1));
                if (B3COL(1) ~= 0)
                    pitch3 = d(:,B3COL(1));
                else
                    pitch3 = 0;
                end
                 %grab first name for signle blade case
                 tempList = get(ListBox(i),'String');
                 bendName = tempList(ListBox_sel_index(1));
            end
            
            %Convert pitch to radiuns
            pitch1 = pitch1 * pi/180;
            pitch2 = pitch2 * pi/180;
            pitch3 = pitch3 * pi/180;
            
            %This where things get tricky, we need to figure out what the
            %user wants.  If there are 2 signals, then assume user wants
            %Oop bending for single blade, figure out which blade and use
            %the the appropriate pitch.  If there are 4, assume this is
            %2-bladed average, and if there are 6 assume this is 3-bladed
            %average
            
            if (length(tdat) == 2) %single blade case
                %work out which blade this is
                if (~isempty(strfind(bendName{1},'1'))) %this is blade 1
                    pitch = pitch1;
                    legName = 'Blade 1 In Plane';
                elseif (~isempty(strfind(bendName{1},'2'))) %blade 2
                    pitch = pitch2;
                    legName = 'Blade 2 In Plane';
                else %blade3
                    pitch = pitch3;
                    legName = 'Blade 3 In Plane';
                end
                
                %Grab edge and flap bending
                edge = tdat{2};
                flap = tdat{1};
                
                %Compute Inp
                Inp = flap .* sin(pitch') + edge .* cos(pitch');
            
            elseif (length(tdat) == 4) %two-bladed case
                legName = '2-bladed in plane';
                
                %Grab edge and flap bending
                edge1 = tdat{4};
                flap1 = tdat{3};
                edge2 = tdat{2};
                flap2 = tdat{1};
                
                %Compute Inp
                Inp1 = flap1 .* sin(pitch1') + edge1 .* cos(pitch1');
                Inp2 = flap2 .* sin(pitch2') + edge2 .* cos(pitch2');
                Inp = mean([Inp1;Inp2]);
             elseif (length(tdat) == 6) %3-bladed case
                legName = '3-bladed in plane';
                
                %Grab edge and flap bending
                edge1 = tdat{6};
                flap1 = tdat{5};
                edge2 = tdat{4};
                flap2 = tdat{3};
                edge3 = tdat{2};
                flap3 = tdat{1};
                
                %Compute Inp
                Inp1 = flap1 .* sin(pitch1') + edge1 .* cos(pitch1');
                Inp2 = flap2 .* sin(pitch2') + edge2 .* cos(pitch2');
                Inp3 = flap3 .* sin(pitch3') + edge3 .* cos(pitch3');
                Inp = mean([Inp1;Inp2;Inp3]);
            end
            
            %Compress the time to an array
            tt=tt{1};
            
           
            %Now plot the data and label
            plot(a(i),tt,Inp)
            xlabel(a(i),'Seconds');
            ylabel(a(i),'kNm');
            xlim(txlim);        
            legend(a(i),legName);
            if get(GridButton,'Value')
                set(a(i),'xgrid','on',...
                         'ygrid','on');
            else
                set(a(i),'xgrid','off',...
                         'ygrid','off');
            end
        end
    end
end


%% FFT Button Callback function
function FFTButton_Callback(hObject, eventdata, handles)
%This function displays an FFT of a given window
    for i=1:6
        if get(FFTButton(i),'Value')
            %If we pushed the fft button for plot i
            
            %Get the current xlimits
            txlim = get(a(i),'XLim');
            
            %Get the plot
            pos = get(a(i), 'Children');
            
            %First grab the representative data
            %tdat for time data
            %tt for time time
            tdat = get(pos,'YData');
            tt = get(pos,'XData');
            
            %Now find the given limits within data
            tstart = find(tt>=txlim(1),1);
            tend = find(tt>=txlim(2),1);
            
            %Trim the data to match
            tdat=tdat(tstart:tend);
            tt=tt(tstart:tend);
            
            %Determine which FPS to use (data set 1 or two)
            ListBox_sel_index = get(ListBox(i),'Value');

            %Set up plot depending on if using multiplot
            if(get(MultiPlotButton,'Value'))
                figure(99)
            else
                figure
            end
            
            %Plot depending on whether plotting data set 1 or 2
            if(isempty(ListBox_sel_index)) %If the 1st list box is empty use the second's
                 %fastfft(tdat, FPS(2),true); 
                 [w,junk2,fftCplx] = spectrum_FFT_PSD(tdat,1/FPS(2),Spa_Av_Num,[],[],'hamming');
                 freq = w / (2 * pi);
                 fftAmp = abs(squeeze(fftCplx));
                 SampleRate = FPS(2);
            else %Use the first
                %fastfft(tdat, FPS(1),true);   
                 [w,junk2,fftCplx] = spectrum_FFT_PSD(tdat,1/FPS(1),Spa_Av_Num,[],[],'hamming');                 freq = w / (2 * pi);
                 fftAmp = abs(squeeze(fftCplx));
                 SampleRate = FPS(1);
            end
              
            subplot(2,1,1)
            plot(freq, fftAmp);
            xlabel('Frequency (Hz)');
            ylabel('Amplitude');
            xlim([0.5 10])
            grid on
            subplot(2,1,2)
            plot(freq, fftAmp);
            xlabel('Frequency (Hz)');
            ylabel('Amplitude');
            xlim([0.5 SampleRate/2])
            grid on
                        
            %Make the title the current channel
            for j =1:2
                subplot(2,1,j)
                title([hdr(get(ListBox(i),'Value'),1)' hdr(get(ListBox(i+6),'Value'),1)']);
                if(get(MultiPlotButton,'Value'))
                    hold all
                end
            end           
        end
    end
end

%% PSD Button Callback function
function PSDButton_Callback(hObject, eventdata, handles)
%This function displays a PSD of a given window
    for i=1:6
        if get(PSDButton(i),'Value')
            %If we pushed the PSD button for plot i

            %Get the current xlimits
            txlim = get(a(i),'XLim');

            %Get the plot
            pos = get(a(i), 'Children');

            %First grab the representative data
            %tdat for time data
            %tt for time time
            tdat = get(pos,'YData');
            tt = get(pos,'XData');

            %Now find the given limits within data
            tstart = find(tt>=txlim(1),1);
            tend = find(tt>=txlim(2),1);

            %Trim the data to match
            tdat=tdat(tstart:tend);

           %Determine which FPS to use (data set 1 or two)
            ListBox_sel_index = get(ListBox(i),'Value');

            %Store the appropriate FPS value
            if(isempty(ListBox_sel_index)) %If the 1st list box is empty use the second's
                psdFPS = FPS(2);
            else %Use the first
                psdFPS = FPS(1);
            end

           %Generate PSD with TU DELFT's spa_average 
           [w,psdVals,junk] = spectrum_FFT_PSD(tdat,1/FPS(1),Spa_Av_Num,[],[],'hamming');
            freq = w / (2 * pi);
           psdVals = abs(squeeze(psdVals));
            
            
%             %%%%%%%%%%%%%%%%%%%%%%
%             %Now generate a psd from the time series data
%             %Code taken from M Buhl's MCrunch Software of NWTC
%             %In some cases directly copied
% 
%             %First detrend the data
%             tdat = detrend(tdat);
%             
%             %Now cosine damp the dat
%             TSlen = length(tdat);
%             LenTap         = round( 0.05*TSlen );
%             TapIX          = 1:LenTap;
%             Taper          = [ 0.5*( 1 - cos( double( TapIX )*pi/double( LenTap ) ) ), zeros( 1, 2*LenTap ) ];
%             Taper          = [ Taper(1:LenTap), Taper(LenTap:-1:1) ];               %the taper, bringing the signal to zero at the endpoints
%             TapIX          = round( [ TapIX, TapIX+(TSlen-LenTap) ] );  %the indicies to taper
%             for ii = 1:length(TapIX)
%                 tdat(TapIX(ii)) = tdat(TapIX(ii)).*Taper(ii);
%             end
%             
%             
%             % Set up the spectrum object and specify the window type.
%              % Generate the PSD.
% 
%              HdlSp = spectrum.periodogram( 'hamming' );
%              HdlOp = psdopts( HdlSp );
%              set( HdlOp, 'Fs',psdFPS, 'SpectrumType','onesided', 'NFFT',double( TSlen ) );
%              HdlPSD   = psd( HdlSp, tdat, HdlOp );
%              NumFreqs = length( HdlPSD.Frequencies );

             %Now plot twice in two frequency ranges
             
             %If multiplot use figure 98 for psd
             if(get(MultiPlotButton,'Value'))  %If multiplot increment color
                figure(98)
             else
                 figure
             end
             
  %           subplot(2,1,1)
             %loglog(freq, psdVals);
             semilogy(freq, psdVals);
             xlim([PSDLower PSDUpper])
             
           %  ylim([10^-5 10^6])
             %grid on
             %xlim([0.1 200])
             title('PSD of data');
             xlabel('Frequency (Hz)');
             if(get(MultiPlotButton,'Value'))
                   hold all
             end

%              subplot(2,1,2)
%              semilogy(freq, psdVals);
%              grid on
%              xlim([0.5 psdFPS/2])
%              title('PSD of data');
%              xlabel('Frequency (Hz)');
%              if(get(MultiPlotButton,'Value'))
%                   hold all
%              end          
        end
    end
end

%% OnePFFT Button Callback function
function OnePFFTButton_Callback(hObject, eventdata, handles)
%This function displays an FFT of a given window scaled by 1P
    for i=1:6
        if get(OnePFFTButton(i),'Value')
            %If we pushed the PSD button for plot i
            
            %Get the current xlimits
            txlim = get(a(i),'XLim');
            
            %Get the plot
            pos = get(a(i), 'Children');
            
            %First grab the representative data
            %tdat for time data
            %tt for time time
            tdat = get(pos,'YData');
            tt = get(pos,'XData');
            
            %Determine which FPS to use (data set 1 or two) and also grab
            %LSSRPM
            ListBox_sel_index = get(ListBox(i),'Value');
            if(isempty(ListBox_sel_index)) %If the 1st list box is empty use the second's
                OnePfps = FPS(2);
                OnePRPM = d2(:,LSSRPM(2));
            else %Use the first
                OnePfps = FPS(1);
                OnePRPM = d(:,LSSRPM(1));
            end
            
            %Now find the given limits within data
            tstart = find(tt>=txlim(1),1);
            tend = find(tt>=txlim(2),1);
            
            %Trim the data to match
            tdat=tdat(tstart:tend);
            trpm = OnePRPM(tstart:tend);

             %fastfft(tdat, FPS(2),true); 
   %          [junk1,w,junk2,junk3,junk4,fftCplx,junk5] = spa_average(tdat,tdat,1/OnePfps,20,[],[],'hamming');
   %          freq = w / (2 * pi);
   %          fftAmp = abs(squeeze(fftCplx));
             
                        %Generate PSD with TU DELFT's spa_average 
           [w,junk2,psdVals]= spectrum_FFT_PSD(tdat,1/OnePfps,20,[],[],'hamming');
           freq = w / (2 * pi);
           fftAmp = abs(squeeze(psdVals));

 
            %Compute 1P Frequency for this area
            meanLSSHz = mean(trpm)/60;

            %Now scale the frequency array
            vFrequencyScaled = freq/meanLSSHz;


             %If multiplot use figure 98 for psd
             if(get(MultiPlotButton,'Value'))  %If multiplot increment color
                figure(97)
             else
                 figure
             end
             
            
            % plot figure
            %plot(vFrequencyScaled, fftAmp);
            semilogy(vFrequencyScaled, fftAmp);
            title(['Bode Plot in terms of P (1P = ' num2str(meanLSSHz) ')']);
            xlabel('Frequency (P)');
            ylabel('Amplitude');
            xlim([0.5 10])
            grid on
            
            if(get(MultiPlotButton,'Value'))
                hold all
            end       


%Add a note
%text(5,yinfo(2)/.6,['1P for this section = ' num2str(meanLSSHz)]); 
            
        end
    end
end



%% Waterfall Button Callback function
function WFButton_Callback(hObject, eventdata, handles)
%This function displays an FFT of a given window
    for i=1:6
        if get(WFButton(i),'Value')
            %If we pushed the Watefall button for plot i
            
            %Get the current xlimits
            txlim = get(a(i),'XLim');
            
            %Get the plot
            pos = get(a(i), 'Children');
            
            %First grab the representative data
            %tdat for time data
            %tt for time time
            tdat = get(pos,'YData');
            tt = get(pos,'XData');
            
            %Now find the given limits within data
            tstart = find(tt>=txlim(1),1);
            tend = find(tt>=txlim(2),1);
            
            %Trim the data to match
            tdat=tdat(tstart:tend);
            tt=tt(tstart:tend);
            
            %Determine which FPS to use (data set 1 or two)
            ListBox_sel_index = get(ListBox(i),'Value');


            
            if(isempty(ListBox_sel_index)) %If the 1st list box is empty use the second's
                WFPS = FPS(2); 
                WFRPM = d2(tstart:tend,LSSRPM(2));
                WWS = d2(tstart:tend,MET37WSCOL(2));
                if (WFControlOnly ~= 0) %if we not using all data
                    WCOM = d2(tstart:tend,COMCOL(2));
                    WCNT = d2(tstart:tend,CNTCOL(2));
                end
            else %Use the first
                WFPS = FPS(1);
                WFRPM = d(tstart:tend,LSSRPM(1));
                WWS = d(tstart:tend,MET37WSCOL(1));
                if (WFControlOnly ~= 0) %if we are not using all data
                    WCOM = d(tstart:tend,COMCOL(1));
                    WCNT = d(tstart:tend,CNTCOL(1));
                end
            end

            if (WFControlOnly == 0) %if we are using all data
                WCOM = []; %setting WCOM to null means use all
            else
                WCOM =  (WCOM == 2 | WCOM == 3) & WCNT == 2; %put ones on all valid points
            end
                
            if (WFLSS == 0) %if doing time based
                WFPlot(tt,tdat,WFPS,WFWindowLength,WFWindowStep,WFResamp,WFDistort,WFInterpolate,WFPCount,WFFReqRange,WFRPM,WFRPM,[0 0],-1,'',WCOM,WFForceMax);
            elseif (WFLSS == 1) %if doing RPM based
            	WFPlot(tt,tdat,WFPS,WFWindowLength,WFWindowStep,WFResamp,WFDistort,WFInterpolate,WFPCount,WFFReqRange,WFRPM,WFRPM,WFBinRange,WFNumBins,'LSSRPM',WCOM,WFForceMax);
            else %doing wind speed based
                WFPlot(tt,tdat,WFPS,WFWindowLength,WFWindowStep,WFResamp,WFDistort,WFInterpolate,0,WFFReqRange,WFRPM,WWS,WFBinRange,WFNumBins,'Wind speed (m/s)',WCOM,WFForceMax);
            end
            %WFPLOT(tt,tdat,WFPS,get(WFCB(i),'Value'),WFRPM);
           % WFPlot(Wt,Wdata,WFPS,windowLength,windowStep,resamp,distort,pCount,freqRange,LSSRPM,numBins,WCom)
            %Make the title the current channel
%            for j =1:2
%                subplot(2,1,j)
%                title([hdr(get(ListBox(i),'Value'),1)' hdr(get(ListBox(i+6),'Value'),1)']);
%            end
           
        end
    end
end
     

%% Waterfall Slice Button Callback function
function WFSliceButton_Callback(hObject, eventdata, handles)
%This function displays an FFT of a given window
    for i=1:6
        if get(WFSliceButton(i),'Value')
            %If we pushed the Watefall button for plot i
            
            %Get the current xlimits
            txlim = get(a(i),'XLim');
            
            %Get the plot
            pos = get(a(i), 'Children');
            
            %First grab the representative data
            %tdat for time data
            %tt for time time
            tdat = get(pos,'YData');
            tt = get(pos,'XData');
            
            %Now find the given limits within data
            tstart = find(tt>=txlim(1),1);
            tend = find(tt>=txlim(2),1);
            
            %Trim the data to match
            tdat=tdat(tstart:tend);
            tt=tt(tstart:tend);
            
            %Determine which FPS to use (data set 1 or two)
            ListBox_sel_index = get(ListBox(i),'Value');

            if(isempty(ListBox_sel_index)) %If the 1st list box is empty use the second's
                WFPS = FPS(2); 
                WFRPM = d2(tstart:tend,LSSRPM(2));
                WCOM = d2(tstart:tend,COMCOL(2));
            else %Use the first
                WFPS = FPS(1);
                WFRPM = d(tstart:tend,LSSRPM(1));
                WCOM = d(tstart:tend,COMCOL(1));
            end

            if (WFControlOnly == 0) %if we are using all data
                WCOM = []; %setting WCOM to null means use all
            else
                WCOM =  (WCOM == 2 | WCOM == 3); %put ones on all valid points
            end

            %Get waterfall and magnitude in band
          	[amp freq WFRPM2] = WFPlot(tt,tdat,WFPS,WFWindowLength,WFWindowStep,WFResamp,0,0,0,WFFReqRange,WFRPM,WFNumBins,WCOM);
            avIdx = find(freq > WFSliceRange(1) & freq < WFSliceRange(2));
            mag = max(amp(avIdx,:));
            
            %Now make the figure
            
             %If multiplot use figure 96 fow WF Slice
             if(get(MultiPlotButton,'Value'));
                figure(96)
             else
                 figure
             end
             


            semilogy(WFRPM2,mag)
            xlabel('LSS RPM')
            ylabel('Mean PSD')
            grid on
            
            if(get(MultiPlotButton,'Value'))
                hold all
            end       
            
            
%             %plot plines
%             for p = 1:WFPCount
%                 vline(mean(WFSliceRange) * 60 / p,'m--',[num2str(p) ' P']);
%             end
%             xlim([0 42])
        end
    end
end


%% ---------------FFT helper functions-------------------------------------
% These functions are called by callback functions for some basic
% calculations
%--------------------------------------------------------------------------


% %% fastfft function
% function [vFrequency, vAmplitude] = fastfft(vData, SampleRate, Plot)
%  
% %FASTFFT   Create useful data from an FFT operation.
% %   Usage: [vFrequency, vAmplitude] = fastfft(vData, SampleRate, [Plot])
% %   
% %   (no plot will be shown if the last input == 0 or is not included)
% %
% %   This function inputs 'vData' as a vector (row or column),
% %   'SampleRate' as a number (samples/sec), 'Plot' as anything,
% %   and does the following:
% %
% %     1: Removes the DC offset of the data
% %     2: Puts the data through a hanning window
% %     3: Calculates the Fast Fourier Transform (FFT)
% %     4: Calculates the amplitude from the FFT
% %     5: Calculates the frequency scale
% %     6: Optionally creates a Bode plot
% %           If plot = 0 no plot is drawn
% %           If plot = 1 plot is drawn 
% %
% %   Created 7/22/03, Rick Auch, mekaneck@campbellsville.com
%  
% %Paul edit for this script (if plot number unspecificed use 1)
% 
% 
% %Make vData a row vector
% if size(vData,2)==1
%     vData = vData';
% end
%  
% %Calculate number of data points in data
% n = length(vData);
%  
% %Remove DC Offset
% vData = vData - mean(vData);
%  
% %Put data through hanning window using hanning subfunction
% vData = hanning(vData);
%  
% %Calculate FFT
% vData = fft(vData);
%  
% %Calculate amplitude from FFT (multply by sqrt(8/3) because of effects of hanning window)
% vAmplitude = abs(vData)*sqrt(8/3);
% 
% %Make actual magnitudes
% %vAmplitude = vAmplitude/n;
%  
% %Calculate frequency scale
% vFrequency = linspace(0,n-1,n)*(SampleRate/n);
%  
% %Limit both output vectors due to Nyquist criterion
% DataLimit = ceil(n/2);
% vAmplitude = vAmplitude(1:DataLimit);
% vFrequency = vFrequency(1:DataLimit);
% 
% 
% %if plot is true go ahead and plot
% if (Plot == true)
%     subplot(2,1,1)
%     plot(vFrequency, vAmplitude,ColorList(ColorCountFFT));
%     xlabel('Frequency (Hz)');
%     ylabel('Amplitude');
%     xlim([0.5 10])
%     grid on
%     subplot(2,1,2)
%     plot(vFrequency, vAmplitude,ColorList(ColorCountFFT));
%     xlabel('Frequency (Hz)');
%     ylabel('Amplitude');
%     xlim([0.5 SampleRate/2])
%     grid on
% end
% 
%  
% end
%------------------------------------------------------------------------------------------
% %Hanning Subfunction
% function vOutput = hanning(vInput)
% % This function takes a vector input and outputs the same vector,
% % multiplied by the hanning window function
%  
% %Determine the number of input data points
% n = length(vInput);
%  
% %Initialize the vector
% vHanningFunc = linspace(0,n-1,n);
%  
% %Calculate the hanning funtion
% vHanningFunc = .5*(1-cos(2*pi*vHanningFunc/(n-1)));
%  
% %Output the result
% vOutput = vInput.*vHanningFunc;
% 
% end

%% Compute1P function
function Compute1P(vData,SampleRate,LSSRPM)
%edited version of the above FASTFFFT function for producing ffts scaled by
%1P
 
            %Plot depending on whether plotting data set 1 or 2
            if(isempty(ListBox_sel_index)) %If the 1st list box is empty use the second's
                 %fastfft(tdat, FPS(2),true); 
                 [w,junk2,fftCplx] = spectrum_FFT_PSD(tdat,1/FPS(2),1,[],[],'hamming');
                 freq = w / (2 * pi);
                 fftAmp = abs(squeeze(fftCplx));
                 SampleRate = FPS(2);
            else %Use the first
                %fastfft(tdat, FPS(1),true);   
                 [w,junk4,fftCplx] = spectrum_FFT_PSD(tdat,1/FPS(1),1,[],[],'hamming');
                 freq = w / (2 * pi);
                 fftAmp = abs(squeeze(fftCplx));
                 SampleRate = FPS(1);
            end
 
%Compute 1P Frequency for this area
meanLSSHz = mean(LSSRPM)/60;

%Now scale the frequency array
vFrequencyScaled = vFrequency/meanLSSHz;


% plot figure
plot(vFrequencyScaled, vAmplitude);
title(['Bode Plot in terms of P (1P = ' num2str(meanLSSHz) ')']);
xlabel('Frequency (P)');
ylabel('Amplitude');
xlim([0 10])
%yinfo = get(gca,'YLim');

%Add a note
%text(5,yinfo(2)/.6,['1P for this section = ' num2str(meanLSSHz)]); 
end


end % cartplot

