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
                timeDataSet = nc_varget(char(fileT),var2Read);
                if(firstOne == 1)
                    latDataSet = nc_varget(char(fileT),'lat');
                    lonDataSet = nc_varget(char(fileT),'lon');
                    newName = strcat('[CIGEFI] ERSST. v4.nc');
                    firstOne = 0;
                    
                    % New file configuration
                    newFile = char(path.concat(newName));
                    nc_create_empty(newFile,'netcdf4-classic');

                    % Adding file dimensions
                    nc_add_dimension(newFile,'latitude',length(latDataSet));
                    nc_add_dimension(newFile,'longitude',length(lonDataSet));
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
                    nc_attput(newFile,nc_global,'reinterpreted_institution','CIGEFI - Universidad de Costa Rica');
                    nc_attput(newFile,nc_global,'reinterpreted_date',char(datetime('today')));
                    nc_attput(newFile,nc_global,'reinterpreted_contact','Roberto Villegas D: roberto.villegas@ucr.ac.cr');

                    % Adding file variables
                    monthlyData.Name = var2Read;
                    monthlyData.Datatype = 'single';
                    monthlyData.Dimension = {'time','latitude', 'longitude'};
                    nc_addvar(newFile,monthlyData);

                    timeData.Name = 'time';
                    timeData.Dimension = {'time'};
                    nc_addvar(newFile,timeData);

                    latData.Name = 'latitude';
                    latData.Dimension = {'latitude'};
                    nc_addvar(newFile,latData);

                    lonData.Name = 'longitude';
                    lonData.Dimension = {'longitude'};
                    nc_addvar(newFile,lonData);

                    % Writing the data into file
                    nc_varput(newFile,'latitude',latDataSet);
                    nc_varput(newFile,'longitude',lonDataSet);
                end
                newData = cat(3,newData,squeeze(timeDataSet(1,:,:,:)));
                %for i=1:1:length(latDataSet)
                %    for j=1:1:length(lonDataSet)
                %        newData(cf,i,j) = timeDataSet(1,1,i,j); %#ok<AGROW>
                %    end
                %end
                cf = cf +1;
                disp(strcat('Data saved:  ',char(fileT.substring(fileT.lastIndexOf('/')+1))));
            catch exception
                fid = fopen('log.txt', 'at+');
                fprintf(fid, '[ERROR][%s] %s\n %s\n\n',char(datetime('now')),char(fileT),char(exception.message));
                fclose(fid);
            end
        end
    end
    if ~empty(newData)
        try
            % Writing the data into file
            nc_varput(newFile,var2Read,newData);
        catch exception
            fid = fopen('log.txt', 'at+');
            fprintf(fid, '[ERROR][%s] %s\n %s\n\n',char(datetime('now')),char(fileT),char(exception.message));
            fclose(fid);
        end 
    end
end
