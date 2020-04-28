% Run this script after scriptSetupML, it will connect to jupyter, copy
% files and can terminate the instance

%% Inputs
id = '';
dns = '';

%% Jenkins

if exist('id_','var')
    id = id_;
end
if exist('dns_','var')
    dns = dns_;
end

if isempty(id) || isempty(dns)
    error('Please set id and dns to connect');
end

%% Re-connect with instance
% This function is generated by awsSetCredentials_Private.
awsSetCredentials();
ec2RunStructure = My_ec2RunStructure_DeepLearning();
ec2Instance = awsEC2RunstructureToInstance(ec2RunStructure, id, dns);

%% Run Jupyter 

% Build ssh command to generate a terminal
sshCmd = sprintf('-L localhost:8888:localhost:8888 -i "%s" ubuntu@%s ',...
    ec2Instance.pemFilePath, ec2Instance.dns);

% Present user what to do
waitfor(msgbox({...
    'Copy URL from the terminal that will appear after closing this dialog box.',...
    'Paste to browser, this will be your access to jupyter',...
    'Once online, navigate to ml/runme.ipynb - continue from there'}));

ssh([sshCmd '"jupyter notebook"'],true);

%% Once done, exit

answer = inputdlg({'Path to folder to save:', 'Experiment Name:'},'Click Ok to Save, Cancel to Skip Save',[1 100],{'~/ml/',''});

if ~isempty(answer)
    % Generate a directory for output.
    modelDirectory = awsModifyPathForCompetability(sprintf('%s/%s %s/', ...
        s3SubjectPath('','_MLModels'), ...
        datestr(now,'yyyy-mm-dd'),answer{2}),true);
    awsMkDir(modelDirectory);
    modelDirectoryLinux = strrep(modelDirectory,' ','\ ');
    % Copy what the user wanted
    userFolder = awsModifyPathForCompetability([answer{1} '/']);
    userFolder = strrep(userFolder,'\','/');
    [~,folderName] = fileparts(userFolder(1:(end-1))); % Get folder's name
    userFolder = strrep(userFolder,'\ ',' ');
    userFolder = strrep(userFolder,' ','\ ');
    dest = awsModifyPathForCompetability(modelDirectory,true);
    awsEC2RunCommandOnInstance(ec2Instance,...
        ['aws s3 sync ' userFolder ' ' modelDirectoryLinux folderName '/']);

    % Copy configuration
    awsEC2RunCommandOnInstance(ec2Instance,...
        {...
        ['aws s3 cp ~/ml/RunConfig.json ' modelDirectoryLinux], ...
        ['aws s3 cp ~/ml/runme.ipynb ' modelDirectoryLinux], ...
        });
end

% Should we terminate instance
answer = questdlg('Should I Terminate EC2 Machine?','?','Yes','No','No');
if strcmp(answer,'Yes')
    % Terminate instance
    awsEC2TerminateInstance(ec2Instance);
end
