classdef data_xas_to_spec

    properties
    end

    methods (Static)

        % ---------------------------
        function create_spec_file(homeDir, file, exclude_channels, beamline, counter, arg)
            cd(homeDir)
            
            % find all files that contain the file name
            listing = dir(sprintf('%s*',file));
            if size(listing,1) == 0
                disp(['  !!! The file ' file ' does not exist in directory'])
                disp(['      ' homeDir])
                disp(' ')
                return
            end

            % open the new spec file:
            fid=fopen([homeDir file '.spec'],'w');
            fprintf(fid, '#F %s.spec\n',file);

            % make a table out of the structure 'listing':
            tbl = struct2table(listing);
            % selection rules:
            % - cannot be a directory
            % - the filename must the 10 characters longer than the
            %   filename (*_xxx_A.yyy)
            cnt = 0;
            for i = 1:size(listing,1)
                % select only the matching files:
                if length(char(tbl.name(i))) == length(file)+10 && ...
                        tbl.isdir(i) == 0

                    cnt = cnt + 1;

                    data_file = char(tbl.name(i));
            
                    % read the data file and extract the spectra
                    [data,column] ...
                        = data_read.read_XAS_BLs([homeDir data_file], counter, arg);
                    % exclude channels:
                    if size(exclude_channels) > 0
                        column.FF(exclude_channels) = [];
                    end                
                    % sum all channels:
                    fluorescence = sum(data(:,column.FF),2);
                    % single channels:
                    mono = data(:,column.mono);
                    I0 = data(:,column.I0);
                    I1 = data(:,column.I1);
                    I2 = data(:,column.I2);

                    % write to spec file:
                    run = str2num(data_file(end-8:end-6));
                    scan = str2num(data_file(end-2:end));
                    fprintf(fid,'\n#S %d.%d  XAS %s\n', run,scan,beamline);
                    fprintf(fid,'#L  energy  spectrum  I0  I1  I2\n');
                    for j = 1:size(data,1)
                        fprintf(fid,'%f  %f  %f  %f  %f\n', mono(j), fluorescence(j), I0(j), I1(j), I2(j));
                    end
                end
            end

            % close the file
            fclose(fid);
        end
    end
end



