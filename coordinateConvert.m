function atomdata=coordinateConvert(InputFile,saveatomfile)
%% Created by Alex Robinson, University of Liverpool, 2021. 
%% a.w.robinson@liverpool.ac.uk
%% If this code has helped you, please reference.
%%
% This code is designed to convert CrystalMaker Coordinate txt files into a
% way that can be read by the crystal2multem.m function (see my other files). 

%% Generating structure.
clear atomdata
atomdata.AtomData=[];
atomdata.message='';


%% Adjust the InputFile name. Can contain .txt extension or not. 
if endsWith(InputFile,'.txt')
    InputFile=InputFile(1:end-4);
end
%% Changing file names.
inputFile=append(InputFile,'.txt');
atomDataFile=append(InputFile,'AtomData.txt');
tempfile2='tempfile2.txt'; % a temporary file name to store writetable() onto.
% Attempting to run code. If it fails, crystal2multem.m will have error
% indicating the error came from here.
try
    data2sort = readtable(inputFile, 'HeaderLines',1 , 'ReadVariableNames', false);
    [datrow,datcol]=size(data2sort);
    %Samples with coordinates order 1x10 and over do not follow same
    %patern as smaller samples due to delimiter. Hence the following.
    if datcol>1  
        del=0;
        num_atoms=data2sort{3,4};
        
        atomdataout={zeros([num_atoms 8])};
        for i=1:8
            for j=1:num_atoms
                atomdataout{j,i}=data2sort{j+(datrow-num_atoms-1),i};
            end
        end
        atomdataout=cell2table(atomdataout);
    else
        del=1;
        outputFile='tempfile1.xlsx'; %create temporary xlsx file for writing.
        writetable(data2sort, outputFile, 'WriteVariableNames', false, 'Range', 'A1');
        content2write = strsplit(fileread(inputFile), {'\n', '\r'});  
        writetable(cell2table(content2write(1)), outputFile, 'WriteVariableNames', false, 'Range', 'A1');
        [rows,columns]=size(data2sort);
        num_atoms=rows-10;
        i_start=9;
        atom_data={zeros([num_atoms columns])};
        for i=1:num_atoms
            for j=1:columns
                atom_data(i,j)=data2sort{i+i_start,j};
            end
        end
        atomdataout=cell2table(atom_data);    
        atomdata.atoms=atom_data;
        
    end
    if del==1 %deletes temp file if used.
        !del tempfile1.xlsx 
    end
    writetable(atomdataout, tempfile2, 'Delimiter','\t');
    atomdataout=readtable(tempfile2,'HeaderLines',1);
    % deletes other temp file. Can be saved though, if required.
    !del tempfile2.txt
    if saveatomfile==1
        writetable(atomdataout, atomDataFile, 'Delimiter','\t');
        disp(append('File saved to path as: ', atomDataFile));
    end
    atomdata.AtomData=atomdataout;
    atomdatamessage='Successful run through coordinateConvert.m function. The data should be of the correct form.'; 
catch
    atomdatamessage='Failed to Convert within coordinateConvert.m function, likely error due to file type.';
end
atomdata.message=atomdatamessage;
end
