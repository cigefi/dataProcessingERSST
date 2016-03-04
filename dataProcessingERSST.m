% Function dataProcessingERSST
%
% Prototype: dataProcessingERSST(dirName,var2Read)
%
% dirName = Path of the directory that contents the files 
% var2Read = Variable to be read (use 'ncdump' to check variable names)
function [] = dataProcessingERSST(dirName,var2Read)
    if nargin < 1
        error('dataProcessing: dirName is a required input')
    end
    if nargin < 2
        error('dataProcessing: var2Read is a required input')
    end
    
    dirData = dir(dirName);  % Get the data for the current directory
    path = java.lang.String(dirName);
    if(path.charAt(path.length-1) ~= '/')
        path = path.concat('/');
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
                    fid = fopen('log2.txt', 'at+');
                    fprintf(fid, '[ERROR][%s] %s\n %s\n\n',char(datetime('now')),char(fileT),char(err));
                    fclose(fid);
                    continue;
                end
                %timeDataSet = nc_varget(char(fileT),var2Read);
                if(firstOne == 1)
                    %latDataSet = nc_varget(char(fileT),'lat');
                    %lonDataSet = nc_varget(char(fileT),'lon');
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
                    
                    % New file configuration
                    newFile = char(path.concat(newName));
                    nc_create_empty(newFile,'netcdf4-classic');

                    % Adding file dimensions
                    nc_add_dimension(newFile,'lat',length(latDataSet));
                    nc_add_dimension(newFile,'lon',length(lonDataSet));
                    nc_add_dimension(newFile,'time',0); % 0 means UNLIMITED dimension

                    % Global params
                    nc_attput(newFile,nc_global,'id',nc_attget(char(fileT),nc_global,'id'));
                    nc_attput(newFile,nc_global,'naming_authority',nc_attget(char(fileT),nc_global,'naming_authority'));
                    nc_attput(newFile,nc_global,'title',nc_attget(char(fileT),nc_global,'title'));
                    nc_attput(newFile,nc_global,'institution',nc_attget(char(fileT),nc_global,'institution'));
                    nc_attput(newFile,nc_global,'production_version',nc_attget(char(fileT),nc_global,'production_version'));
                    nc_attput(newFile,nc_global,'cdm_data_type',nc_attget(char(fileT),nc_global,'cdm_data_type'));
                    nc_attput(newFile,nc_global,'processing_level',nc_attget(char(fileT),nc_global,'processing_level'));
                    nc_attput(newFile,nc_global,'source',nc_attget(char(fileT),nc_global,'source'));
                    nc_attput(newFile,nc_global,'frequency','monthly');
                    nc_attput(newFile,nc_global,'data_analysis_institution','CIGEFI - Universidad de Costa Rica');
                    nc_attput(newFile,nc_global,'data_analysis_date',char(datetime('today')));
                    nc_attput(newFile,nc_global,'data_analysis_contact','Roberto Villegas D: roberto.villegas@ucr.ac.cr');

                    % Adding file variables
                    monthlyData.Name = var2Read;
                    monthlyData.Datatype = 'single';
                    monthlyData.Dimension = {'lat', 'lon','time'};
                    nc_addvar(newFile,monthlyData);

                    timeData.Name = 'time';
                    timeData.Dimension = {'time'};
                    nc_addvar(newFile,timeData);

                    latData.Name = 'lat';
                    latData.Dimension = {'lat'};
                    nc_addvar(newFile,latData);

                    lonData.Name = 'lon';
                    lonData.Dimension = {'lon'};
                    nc_addvar(newFile,lonData);

                    % Writing the data into file
                    nc_varput(newFile,'lat',latDataSet);
                    nc_varput(newFile,'lon',lonDataSet);
                end
                newData = cat(3,newData,timeDataSet);
                cf = cf +1;
                [~,~,t] = size(newData);
                %Writing the data into file
                if t > 1
                    nc_varput(newFile,var2Read,newData);
                end
                if(mod(cf,100)==0)
                    disp(strcat('Data saved:  ',char(fileT.substring(fileT.lastIndexOf('/')+1))));
                end
            catch exception
                fid = fopen('log2.txt', 'at+');
                fprintf(fid, '[ERROR][%s] %s\n %s\n\n',char(datetime('now')),char(fileT),char(exception.message));
                fclose(fid);
            end
        end
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
