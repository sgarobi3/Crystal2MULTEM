function MultemFile=crystal2multem(InputFile,FileType,save,sizeX,sizeY,dz,rms,occupancy,region,charge,saveatomfile)
%% Created by Alex Robinson, University of Liverpool, 2021. 
%% a.w.robinson@liverpool.ac.uk
%% If this code has helped you, please reference.
%%
% THIS CODE WILL TURN EITHER CRYSTAL MAKER
% COORDINATE FILES INTO APPROPRIATE FORM, OR TAKE ALREADY ADJUSTED DATA
% (USING coordinateConvert.m) AND
% DO THE SAME. THE FORM OF DATA, IF NOT CONVERTED ALREADY MUST BE:

% Z NUMBER  \\ X \\ Y \\ Z \\ RMS \\ OCCUPANCY \\ REGION \\ CHARGE
% EXAMPLE (NO HEADERS SHOULD BE USED) :

% 14 0 0 0 0.085 1 0 0
% 14 1 0 0 0.085 1 0 0
% 14 0 1 0 0.085 1 0 0
% 14 0 0 1 0.085 1 0 0

% FOR CRSYTAL MAKER COORDINATE FILES, USE FILETYPE=1.
% FOR ALREADY ADJUSTED DATA, USE FILETYPE=2.
% FOR ALREADY ADJUSTED DATA, CALL IT AS NORMAL. 

% IF RMS, OCCUPANCY, REGION AND CHARGE ARE LEFT EMPTY, THEN 0.085, 1, 0, 0
% WILL BE AUTOMATICALLY USED. 
% DZ INDICATES THE SLICE THICKNESS FOR YOUR SPECIMEN. 
% 'save' WILL SAVE THE OUTPUT FILE IF 'save'== 1
% saveatomfile (position 11) will save the coordinateConvert.m output if it is needed.
% Will save if saveatomfile=1, otherwise it can be left blank and won't
% save. Likely not needed if using this code.
%%
if nargin<11
    saveatomfile=0;
end
if nargin<10
    charge=0;
    warning('No argument for charge. Setting charge=0.');
end
if nargin<9
    region=0;
    warning('No argument for region. Setting region=0.');
end
if nargin<8
    occupancy=1;
    warning('No argument for occupancy. Setting occupancy=1.');
end
if nargin<7
    rms=0.085;
    warning('No argument for rms. Setting rms=0.085.');
end
if nargin<6
    sizeX=0;
    warning('No argument for X dimension of sample. Setting X dimension to maximum x-coordinate value of sample.');
end
if nargin<5
    sizeY=0;
    warning('No argument for Y dimension of sample. Setting Y dimension to maximum y-coordinate value of sample.');
end
if nargin<4
    dz=0;
    warning('No argument for slice thickness of sample. Setting slice thickness to minimum z-step of sample.');
end
if nargin<2
    error('Not enough arguments given. Please check FileType argument (position 2). FOR CRSYTAL MAKER COORDINATE FILES, USE FileType=1. IF THE FILE ONLY NEEDS TRANSLATING, USE FileType=2. Not enough arguments given. Please indicate whether to save output file in position 3. SAVE==1, DO NOT SAVE==0.');
end
if nargin<3
    error('Not enough arguments given. Please indicate whether to save output file (position 3). SAVE==1, DO NOT SAVE==0.');
end

%% Build up MultemFile structure
clear MultemFile
MultemFile.Data=[];
MultemFile.NumAtoms=[];
MultemFile.Translata=[];
MultemFile.TopLine=[];
MultemFile.PreparedData=[];
MultemFile.Output=[];
MultemFile.downloadmessage='';

%% If the file ends with '.txt', converts to correct form for saving. 
% The code will accept without .txt extension.
if endsWith(InputFile,'.txt')
    InputFile=InputFile(1:end-4);
end

% Name of file to save will end with MULTEMFILE, starting with original
% input name.
MULTEMFILE=append(InputFile,'MULTEMFILE.txt');
MultemFile.FileName=MULTEMFILE;
%% 
% Runs the input file to the correct data style. At the end of this
% section, the data should be of the form:
% Z NUMBER  \\ X \\ Y \\ Z \\ RMS \\ OCCUPANCY \\ REGION \\ CHARGE
% example line:
% 14 \\ 5.42000000000000 \\ 16.2600000000000 \\ -5.42000000000000 \\ 0.0850000000000000 \\ 1 \\ 0 \\ 0
% This section prepares the data to be translated into the correctc form. 
if FileType==1 %.txt coordinate file straight out of CrystalMaker
    try 
        atomdata=coordinateConvert(InputFile,saveatomfile);  % Restructures the .txt file from CrystalMaker
        UnitData=atomdata.AtomData; 
        disp(atomdata.message); % Indicates success/failure
        MultemFile.downloadmessage='File Successfully Uploaded';
    catch 
        MultemFile.downloadmessage='Incorrect FileType or File Not Read Correctly';
    end
elseif FileType==2 
    try
        UnitData=readtable(InputFile);   
        MultemFile.downloadmessage='File Successfully Uploaded';
    catch
        MultemFile.downloadmessage='Incorrect FileType or File Not Read Correctly';
    end
end

% The input file is the atom data file 
if FileType==2 && saveatomfile==1
    warning(append('Atom Data File already saved as ',MultemFile.FileName));
end
disp(MultemFile.downloadmessage);
timeFormat='HH:MM:SS'; % timer start
dt=datestr(clock,timeFormat);
disp(append('Start: ',dt));
disp('_____________');

[numberAtoms,~]=size(UnitData);
UnitForChange=zeros(size(numberAtoms,8));
MultemFile.NumAtoms=numberAtoms;
for i=1:MultemFile.NumAtoms %ammend to correct MULTEM form w.out translation
    UnitForChange(i,1)=atomicNumber(UnitData{i,1});
    UnitForChange(i,2)=UnitData{i,6};
    UnitForChange(i,3)=UnitData{i,7};
    UnitForChange(i,4)=UnitData{i,8};
    UnitForChange(i,5)=rms;
    UnitForChange(i,6)=occupancy;
    UnitForChange(i,7)=region;
    UnitForChange(i,8)=charge;
    try
        dispstat(append(num2str(round(i*100/MultemFile.NumAtoms)),'% Complete')); 
    catch
        disp(append(num2str(round(i*100/MultemFile.NumAtoms)),'% Complete'));
    end
end
data=UnitForChange;
MultemFile.Data=data;
%% This section is where the translation of coordinates occurs.
% All translations are linear, and act so that no coordinates are zero. All
% points are translated by the minimum value of each axis. 

[NumAtoms,NumCol]=size(data);
MultemFile.NumAtoms=NumAtoms;
xCoordinates=data(:,2);
yCoordinates=data(:,3);
zCoordinates=data(:,4);

minx=min(xCoordinates);
miny=min(yCoordinates);
minz=min(zCoordinates);

translata=data;

for i=1:NumAtoms
    translata(i,2)=data(i,2)-minx;
    translata(i,3)=data(i,3)-miny;
    translata(i,4)=data(i,4)-minz;
end

MultemFile.Translata=translata;

%% Generating the output file.
% Generating the top line for the output file which can be read by MULTEM.
% The top line should be of the form:
% X dimension \\ Y dimension \\ slice thickness \\ 0 \\ 0 \\ 0 \\ 0 \\ 0

xCoordinates=translata(:,2);
yCoordinates=translata(:,3);
zCoordinates=translata(:,4);
maxx=max(xCoordinates);
maxy=max(yCoordinates);
uniquez=sort(unique(zCoordinates));
difz=uniquez(2,1)-uniquez(1,1);
MultemFile.DifZ=difz;

if dz==0
    thick=difz;
else
    thick=dz;
end

if sizeX==0
    X=maxx;
else
    X=sizeX;
end

if sizeY==0
    Y=maxy;
else
    Y=sizeY;
end

topLine=[X Y thick 0 0 0 0 0];

MultemFile.TopLine=topLine;

% Building the output file including the top line. Here, we are putting the
% top line above the translated data (translata) and then simply making
% sure there are enough decimal points such thaat when the .txt file is
% created, the columns are correctly delimited. 

OutputFile=zeros([NumAtoms+1 NumCol]);
for i=1:NumAtoms+1
    if i==1
        OutputFile(i,:)=topLine;
    else
        OutputFile(i,:)=translata(i-1,:);
    end
end

MultemFile.PreparedData=OutputFile;
[row,col]=size(OutputFile);
FinalOutput={OutputFile};

for i=1:row
    for j=1:col
        strOut=OutputFile(i,j);
        strIn={sprintf('%.5f',strOut)};
        strIn=append(strIn,'000000');
        if length(strIn)>7
            dif=length(strIn)-7;
            strIn=strIn(1:end-dif);
        end
        FinalOutput(i,j)=strIn;
    end
end



MultemFile.NewOutputArray=FinalOutput;
FinalOutput=cell2table(FinalOutput);
MultemFile.Output=FinalOutput;
dtend=datestr(clock,timeFormat);
disp(append('End: ',dtend));  
disp('File Ready');
if save==1
    disp(append('File saved to path as: ', MULTEMFILE));
    writetable(FinalOutput, MULTEMFILE, 'Delimiter','\t','WriteVariableNames', false);
end

end %creates structure as output. Allows user to investigate any issues. 

