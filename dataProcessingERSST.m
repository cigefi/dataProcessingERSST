% Function dataProcessingERSST
%
% Prototype: dataProcessingERSST(dirName,var2Read)
%
% dirName = Path of the directory that contents the files 
% var2Read = Variable to be read (use 'ncdump' to check variable names)
function [] = dataProcessingERSST(dirName,var2Read)
    if nargin < 1
        error('dataProcessing: dirName is a required input');
    else
        dirName = strrep(dirName,'\','/'); % Clean dirName var
    end
    if nargin < 2
        error('dataProcessing: var2Read is a required input');
    end
    
    dirData = dir(char(dirName(1)));  % Get the data for the current directory
    path = java.lang.String(dirName(1));
    if(path.charAt(path.length-1) ~= '/')
        path = path.concat('/');
    end
    if(length(dirName)>1)
        savePath = java.lang.String(dirName(2));
        if(length(dirName)>2)
            logPath = java.lang.String(dirName(3));
        else
            logPath = java.lang.String(dirName(2));
        end
	else
		savePath = java.lang.String(dirName(1));
		logPath = java.lang.String(dirName(1));
    end
    if(savePath.charAt(savePath.length-1) ~= '/')
        savePath = savePath.concat('/');
    end
    if(logPath.charAt(logPath.length-1) ~= '/')
        logPath = logPath.concat('/');
    end
    if(exist(strcat(char(logPath),'log.txt'),'file'))
        delete(strcat(char(logPath),'log.txt'));
    end
    firstOne = 1;
    cf = 1; % Current file position
    newData = [];
    for f = 3:length(dirData)
        fileT = path.concat(dirData(f).name);
        if(fileT.substring(fileT.lastIndexOf('.')+1).equalsIgnoreCase('nc'))
            try
                % Catching data from original file
                [timeDataSet,err] = readNC(fileT,var2Read);
                if ~isnan(err)
                    fid = fopen(strcat(char(logPath),'log.txt'), 'at');
                    fprintf(fid, '[ERROR][%s] %s\n %s\n\n',char(datetime('now')),char(fileT),char(err));
                    fclose(fid);
                    continue;
                end
                %timeDataSet = nc_varget(char(fileT),var2Read);
                if(firstOne == 1)
                    [latDataSet,err] = readNC(fileT,'lat');
                    if ~isnan(err)
                        fid = fopen('log2.txt', 'at+');
                        fprintf(fid, '[ERROR][%s] %s\n %s\n\n',char(datetime('now')),char(fileT),char(err));
                        fclose(fid);
                        continue;
                    end
                    [lonDataSet,err] = readNC(fileT,'lon');
                    if ~isnan(err)
                        fid = fopen('log2.txt', 'at+');
                        fprintf(fid, '[ERROR][%s] %s\n %s\n\n',char(datetime('now')),char(fileT),char(err));
                        fclose(fid);
                        continue;
                    end
                    newName = strcat('ERSST.v4.nc');
                    firstOne = 0;
                    
                    % Catching data from original file
                    ncoid = netcdf.open(char(fileT));
                    GLOBALNC = netcdf.getConstant('NC_GLOBAL');
                    
                    % New file configuration
                    newFile = char(savePath.concat(newName));
                    if exist(newFile,'file')
                        delete(newFile);
                    end
                    ncid = netcdf.create(newFile,'NETCDF4');

                    % Adding file dimensions
                    latdimID = netcdf.defDim(ncid,'lat',length(latDataSet));
                    londimID = netcdf.defDim(ncid,'lon',length(lonDataSet));
                    timedimID = netcdf.defDim(ncid,'time',netcdf.getConstant('NC_UNLIMITED'));

                    % Global params
                    netcdf.copyAtt(ncoid,GLOBALNC,'id',ncid,GLOBALNC);
                    netcdf.copyAtt(ncoid,GLOBALNC,'naming_authority',ncid,GLOBALNC);
                    netcdf.copyAtt(ncoid,GLOBALNC,'title',ncid,GLOBALNC);
                    netcdf.copyAtt(ncoid,GLOBALNC,'institution',ncid,GLOBALNC);
                    netcdf.copyAtt(ncoid,GLOBALNC,'production_version',ncid,GLOBALNC);
                    netcdf.copyAtt(ncoid,GLOBALNC,'cdm_data_type',ncid,GLOBALNC);
                    netcdf.copyAtt(ncoid,GLOBALNC,'processing_level',ncid,GLOBALNC);
                    netcdf.copyAtt(ncoid,GLOBALNC,'source',ncid,GLOBALNC);
                    %netcdf.putAtt(ncid,GLOBALNC,'frequency','monthly');
                    netcdf.putAtt(ncid,GLOBALNC,'data_analysis_institution','CIGEFI - Universidad de Costa Rica');
                    netcdf.putAtt(ncid,GLOBALNC,'data_analysis_institution',char(datetime('today')));
                    netcdf.putAtt(ncid,GLOBALNC,'data_analysis_contact','Roberto Villegas D: roberto.villegas@ucr.ac.cr');

                    % Adding file variables
                    monthlyvarID = netcdf.defVar(ncid,var2Read,'float',[latdimID,londimID,timedimID]);
                    [~] = netcdf.defVar(ncid,'time','float',timedimID);
                    latvarID = netcdf.defVar(ncid,'lat','float',latdimID);
                    lonvarID = netcdf.defVar(ncid,'lon','float',londimID);

                    netcdf.endDef(ncid);

                    % Writing the data into file
                    netcdf.putVar(ncid,latvarID,latDataSet);
                    netcdf.putVar(ncid,lonvarID,lonDataSet);
                end
                newData = cat(3,newData,timeDataSet);
                cf = cf +1;
%                 [~,~,t] = size(newData);
%                 %Writing the data into file
%                 if t > 1
%                     nc_varput(newFile,var2Read,newData);
%                 end
                if(mod(cf,100)==0)
                    disp(strcat('Data saved:  ',char(fileT.substring(fileT.lastIndexOf('/')+1))));
                end
            catch exception
                netcdf.close(ncid);
                netcdf.close(ncoid);
                fid = fopen('log2.txt', 'at+');
                fprintf(fid, '[ERROR][%s] %s\n %s\n\n',char(datetime('now')),char(fileT),char(exception.message));
                fclose(fid);
            end
        end
    end
    try
        % Writing the data into file
        netcdf.putVar(ncid,monthlyvarID,[0 0 0],[length(latDataSet) length(lonDataSet) length(newData(1,1,:))],newData);
        netcdf.close(ncid);
        netcdf.close(ncoid);
    catch exception
        netcdf.close(ncid);
        netcdf.close(ncoid);
        fid = fopen('log2.txt', 'at+');
        fprintf(fid, '[ERROR][%s] %s\n %s\n\n',char(datetime('now')),char(fileT),char(exception.message));
        fclose(fid);
    end
end
function [data,error] = readNC(path,var2Read)
    var2Readid = 99999;
	error = NaN;
    try
        % Catching data from original file
        ncid = netcdf.open(char(path));%,'NC_NOWRITE');
        [~,nvar,~,~] = netcdf.inq(ncid);
        for i=0:1:nvar-1
            [varname,~,~,~] = netcdf.inqVar(ncid,i);
            switch(varname)
                case var2Read
                    var2Readid = i;
                    break;
            end
        end
        data = netcdf.getVar(ncid,var2Readid,'double')';
        %data = permute(netcdf.getVar(ncid,var2Readid,'double'),[3 2 1]);%ncread(char(fileT),var2Read);
        if isempty(data)
            error = 'Empty dataset';
        end
        netcdf.close(ncid)
    catch exception
        data = [];
        try
            netcdf.close(ncid)
        catch
            error = 'I/O ERROR';
            return;
        end
        error = exception.message;
    end
end
