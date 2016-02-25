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
        latid = 0;
        latid = 0;
        var2Readid = 0;
        if(fileT.substring(fileT.lastIndexOf('.')+1).equalsIgnoreCase('nc'))
            try
                ncid = netcdf.open(char(fileT),'NC_NOWRITE');
                [ndim,nvar,natt,unlim] = netcdf.inq(ncid);
                for i=0:1:nvar-1
                   [varname,xtype,dimid,natt] = netcdf.inqVar(ncid,i);
                   switch(varname)
                       case 'latitude'
                           latid = i;
                       case 'longitude'
                           lonid = i;
                       case 'lat'
                           latid = i;
                       case 'lon'
                           lonid = i;
                       case var2Read
                           var2Readid = i;
                   end
                end
                % Catching data from original file
                timeDataSet = netcdf.getVar(ncid,var2Readid);%nc_varget(char(fileT),var2Read);
                if(firstOne == 1)
                    latDataSet = netcdf.getVar(ncid,latid);%nc_varget(char(fileT),'lat');
                    lonDataSet = netcdf.getVar(ncid,lonid);%nc_varget(char(fileT),'lon');
                    newName = strcat('ERSST. v4.nc');
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
                    nc_attput(newFile,nc_global,'data_analysis_institution','CIGEFI - Universidad de Costa Rica');
                    nc_attput(newFile,nc_global,'data_analysis_date',char(datetime('today')));
                    nc_attput(newFile,nc_global,'data_analysis_contact','Roberto Villegas D: roberto.villegas@ucr.ac.cr');

                    % Adding file variables
                    monthlyData.Name = var2Read;
                    monthlyData.Datatype = 'single';
                    monthlyData.Dimension = {'latitude', 'longitude','time'};
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
                newData = cat(3,newData,timeDataSet);
                %newData = cat(3,newData,squeeze(timeDataSet(1,:,:,:)));
                %for i=1:1:length(latDataSet)
                %    for j=1:1:length(lonDataSet)
                %        newData(cf,i,j) = timeDataSet(1,1,i,j); %#ok<AGROW>
                %    end
                %end
                cf = cf +1;
                if(mod(cf,100)==0)
                    disp(strcat('Data saved:  ',char(fileT.substring(fileT.lastIndexOf('/')+1))));
                end
                % Writing the data into file
                nc_varput(newFile,var2Read,newData);
            catch exception
                fid = fopen('log.txt', 'at+');
                fprintf(fid, '[ERROR][%s] %s\n %s\n\n',char(datetime('now')),char(fileT),char(exception.message));
                fclose(fid);
            end
        end
    end
%     if ~isempty(newData)
%         try
%             % Writing the data into file
%             nc_varput(newFile,var2Read,newData);
%         catch exception
%             fid = fopen('log.txt', 'at+');
%             fprintf(fid, '[ERROR][%s] %s\n %s\n\n',char(datetime('now')),char(fileT),char(exception.message));
%             fclose(fid);
%         end 
%     end
end
