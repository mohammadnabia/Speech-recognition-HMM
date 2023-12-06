StartDate=datestr(now);
%% Initial Setting
numState = 8; % because of 4 = chahar 
numMixture = 14;
vectorSize = 39;
WordNumber = 5; 
modelPath = 'models\';
methodName = ['Window_25ms_monophone_39MFCC_16GMM'];
scriptPath = 'SCRIPTS\\';
configPathName1 = 'lib\htk_config.txt'; 
configPathName2 = 'lib\htk_config2.txt'; 
word={'sil','one','two','four','eight'};
%% Feature Extraction
%% Train
trainScript = 'SCRIPTS\Train_HCopy.scp';
HCopyCommand_train = ['HCopy -T 1 -C ', configPathName1, ' -S ', trainScript ];
dos(HCopyCommand_train)
display ('Features of TRAIN files are being extracted successfully.');
CMVN('SCRIPTS\Train.scp');
display('Features of TRAIN files have been normalized successfully.');
%% Test
testScript = 'SCRIPTS\Test_HCopy.scp';
HCopyCommand_test = ['HCopy -T 1 -C ', configPathName1, ' -S ', testScript ];
dos(HCopyCommand_test)
display ('Features of TEST files are being extracted successfully.');
CMVN('SCRIPTS\Test.scp');
EndDate=datestr(now)
%% Create Model Directories
mkdir(['Results\',methodName]);
mkdir(['models\',methodName]);
mkdir(['models\',methodName,'\word0']);
mkdir(['models\',methodName,'\word1']);
for i = 1:15
    mkdir(['models\',methodName,'\hmm',int2str(i)]);
end

protoNamePath = [modelPath,methodName,'/word0/proto.mod'];
createproto('proto',numState,numMixture,vectorSize,protoNamePath);

%% HInit
trainMlfPath = 'labels\Train_Labels.mlf';
scriptPathName = 'Scripts\Train.scp';
protoNamePath = [modelPath,methodName,'\word0\proto.mod'];
newModelPath = strcat(modelPath, methodName,'\word0');
for k = 1:WordNumber
    HInitCommand = ['HInit -A -T 1  -l ', word{k}, ' -o ', word{k}, ' -M ', newModelPath,' -I ',trainMlfPath,' -S ', scriptPathName, ' ', protoNamePath];
    dos(HInitCommand);
end

%% HRest
preModelPath = strcat(modelPath, methodName,'\\word0\\');
newModelPath = strcat(modelPath, methodName,'\\word1');
for k =1:WordNumber
    HRestCommand = ['HRest -A -T 1  -l ', word{k}, ' -M ', newModelPath,' -I ',trainMlfPath,' -S ', scriptPathName,' ', preModelPath, word{k} ];
    dos(HRestCommand);
end
%% HCompV
protoNamePath = [modelPath,methodName,'\word0\proto.mod'];
preModelPath = strcat(modelPath, methodName,'\\word0\\');
newModelPath = strcat(modelPath, methodName,'\\word1');
HCompVCommand = ['HCompV -A -T 1 -C ',configPathName2,' -f 0.01 -m -S ', scriptPathName, ' -M ', newModelPath, ' -I ',trainMlfPath,' ', protoNamePath];
dos(HCompVCommand);

copyCommand = ['copy lib\macros ', modelPath, methodName, '\word1\macros'];
dos( copyCommand );

delCommand = ['del ', modelPath, methodName, '\word1\proto'];
dos( delCommand );

modelsPath = [modelPath, methodName, '\'];
MergeModels(modelsPath, word,WordNumber);

%% HEREST
macroFilePathName = [modelPath, methodName,'\word1\macros'];
hmmdefsFilePathName = [modelPath, methodName,'\word1\hmmdefs'];
preModelPath = strcat(modelPath, methodName,'\word1');
newModelPath = strcat(modelPath, methodName,'\hmm1');
HERestCommand1 = ['HERest -A  -T 1 -d ', preModelPath, ' -I ',trainMlfPath,' -t 250.0 150.0 1000.0 -S ', scriptPathName,' -H ', macroFilePathName, ' -H ',hmmdefsFilePathName, ' -M ', newModelPath, ' Keywords '];
dos( HERestCommand1 );

for hmmNum = 2:15
    preModelPath = strcat(modelPath, methodName,'\\hmm',int2str(hmmNum-1));
    newModelPath = strcat(modelPath, methodName,'\\hmm',int2str(hmmNum));
    hmmdefsFilePathName=strcat(modelPath,'\',methodName,'\hmm',int2str(hmmNum-1),'\hmmdefs');
    macroFilePathName = strcat(modelPath,'\',methodName,'\hmm',int2str(hmmNum-1),'\macros');
    HERestCommand2 = ['HERest -A  -T 1   -I ',trainMlfPath,' -t 250.0 150.0 1000.0 -S ', scriptPathName, ' -H ', macroFilePathName, ' -H ', hmmdefsFilePathName, ' -M  ', newModelPath, ' Keywords '];
    dos(HERestCommand2);
    display (['--- HERest ',int2str(hmmNum),' is done successfully ---'])
end
%% HVITE 
HViteCommand = ['HVite -A -T 1 -o N -C ',configPathName2,' -H models\', methodName,'\hmm15\hmmdefs -S SCRIPTS\Test.scp -i Results\', methodName,'\WordLevel_recout.mlf -w dictionary\wordNet -s ' num2str(1) ' -p ' num2str(-120) ' dictionary\wordDict Keywords > Results\', methodName,'\WordLevel_hvite.log']
dos(HViteCommand);
HResultCommand = ['HResults -A  -n -A -T 1  -I labels\Test_Labels.mlf Keywords Results\', methodName,'\WordLevel_recout.mlf >> Results\',methodName,'\WordLevel_hresult.txt']
dos(HResultCommand); 
%% StartDate
EndDate=datestr(now)
