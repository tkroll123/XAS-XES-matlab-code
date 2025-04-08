classdef data_read
    % define the keyword options:
    properties (Constant)
    end

    % local fundtions here:
    methods (Static)

        % ---- get motor value ------------------------------------
        function [motor_pos,motor_found] = get_motor_position(motor, fname)
            motor_pos = 0;
            motor_found = false;
            
            motor_str = [motor '='];
            % check if file exists:
            if isfile(fname)
                fid=fopen(fname,'r');
                while(~feof(fid))
                    oneline=fgetl(fid);
                    if ~isempty(strfind(oneline, motor))  % it found the motor
                            newStr = extractAfter(oneline,motor_str);
                            strList = split(newStr);
                            Index = 1;
                            motor_pos = str2num(strList{Index});
                            motor_found = true;
                            break;
                    end
            
                    if ~isempty(strfind(oneline,'#L'))  % it found #L in the file
        	            disp(['*** motor ' motor 'not found']) 
                        break
                    end
                end

                if motor_found == false
                    disp(['   !!! Motor ' motor ' not found!'])
                    disp(' ')
                end
                
                fclose(fid);
            else
	            disp(['   !!! file ' fname ' does not exist']) 
                disp(' ')
            end
        end
        
        
        
        % ---- correct for values of 1 ------------------------------------
        function vector_corr = correct_one_values(vector)
            
            % first sum all vectors
            vector = sum(vector,2);

            m = size(vector,1);
            vector_corr = vector;
            if vector(1) == 1
                vector_corr(1) = vector(2);
            end
            if vector(m) == 1
                vector_corr(m) = vector(m-1);
            end
            
            for i = 2:m-2
                if vector(i) == 1
                    vector_corr(i) = 0.5*(vector(i-1)+vector(i+1));
                end
                
            end
        end

        % ---- get length of header ---------------------------------------
        function [skip_lines, counter_str] = get_header_length_spec(fname)
            skip_lines = 0;
            
            if isfile(fname)
                counter_str = '';
                fid=fopen(fname,'r');
                while(~feof(fid))
                    oneline=fgetl(fid);
                    skip_lines = skip_lines + 1;
                    if ~isempty(strfind(oneline,'#L '))
                        counter_str = oneline;
                        break
                    end
                end
                fclose(fid);
            else
                skip_lines = -1;
                counter_str = '';
            end
        end

        % ---- get counter column -----------------------------------------
        function index = find_counter_column(counter_str, counter)
            % split discards the space characters and returns the result as a string array.
            counter_list = split(counter_str);
            
            % get the index of the required counter in the list
            ind = find(ismember(counter_list, counter));
            if ind > 0
                index = ind(1);            
            else
                index = -1;
            end
        end
        
        % ---- read XAS beam lines ----------------------------------------
        function [data,column] = read_XAS_BLs(fname, counter, arg)
            % arg.file, arg.exclude, arg.beamline

            data = 0;
            column.FF = [];
            column.mono = 0;
            column.I0 = 0;
            column.I1 = 0;
            column.I2 = 0;

            skip_lines = 0;
            
            if isfile(fname)
                counter_str = '';
                fid=fopen(fname,'r');
                while(~feof(fid))
                    oneline=fgetl(fid);
                    skip_lines = skip_lines + 1;
                    if ~isempty(strfind(oneline,'Weights:'))
                        oneline=fgetl(fid);
                        skip_lines = skip_lines + 1;
                        if strcmp(oneline(1), ' ')
                            oneline(1) = [];
                        end
                        if strcmp(oneline(end),' ')
                            oneline(end) = [];
                        end

                        % read the number of elements in Weights:
                        weights = split(oneline);
                        break
                    end
                end

                % Offsets:
                oneline=fgetl(fid);
                skip_lines = skip_lines + 1;
                % Offsets values:
                oneline=fgetl(fid);
                skip_lines = skip_lines + 1;
                % Data:
                oneline=fgetl(fid);
                skip_lines = skip_lines + 1;
                
                % run through the counter
                column_cnt = 0;
                counter_list = [];
                for i = 1:size(weights,1)
                    oneline=fgetl(fid);
                    skip_lines = skip_lines + 1;
                    column_cnt = column_cnt + 1;
                    counter_list = [counter_list, {oneline}];
                    if ~isempty(strfind(oneline,'Achieved Energy'))
                        column.mono = column_cnt;
                    end
                    if ~isempty(strfind(oneline,'I0'))
                        column.I0 = column_cnt;
                    end
                    if ~isempty(strfind(oneline,'I1'))
                        column.I1 = column_cnt;
                    end
                    if ~isempty(strfind(oneline, arg.ref))  % this is the reference channel for the foil transmission
                        column.I2 = column_cnt;
                    end
                    if ~isempty(strfind(oneline,counter))
                        column.FF = [column.FF  column_cnt];
                    end
                end
                % an empty line
                oneline=fgetl(fid);
                skip_lines = skip_lines + 1;

                fclose(fid);
            else
                skip_lines = -1;
                counter_str = '';
            end
            
            if column.I2 == 0
                disp(['    *** A non-existent energy reference channel has been given: ' arg.ref '. Use the standard channel for beamline ' arg.beamline])

                % find the reference channel
                for i = 1:length(counter_list)
                    if ~isempty(strfind(char(counter_list(i)),arg.ref_standard))
                        column.I2 = i;
                    end
                end
            
            end

            % read the data:
            data = readmatrix(fname, 'Delimiter',' ', 'NumHeaderLines', skip_lines, 'FileType','text', 'ConsecutiveDelimitersRule', 'join');

            % shift all columns by 1 if the first column is empty
            if isnan(data(1,1))
                if column.mono >0 column.mono = column.mono + 1; end
                if column.I0 >0 column.I0 = column.I0 + 1; end
                if column.I1 >0 column.I1 = column.I1 + 1; end
                if column.I2 >0 column.I2 = column.I2 + 1; end
                if column.FF >0 column.FF = column.FF + 1; end
            end

        end


        % ---- read 15-2 --------------------------------------------------
        function [data,column] = read_15_2(file,counter,mono_str, arg)
            
            % read the sec file:
            [skip_lines, counter_str] = data_read.get_header_length_spec(file);
            data = readmatrix(file, 'Delimiter',' ', 'NumHeaderLines', skip_lines, 'FileType','text', 'ConsecutiveDelimitersRule', 'join');
            
            % get the columns for all counters needed
            column.FF = data_read.find_counter_column(counter_str, counter)-1;
            column.mono = data_read.find_counter_column(counter_str, mono_str)-1;  % that's the mono energy, we are reading out the encoder
            column.I0 = data_read.find_counter_column(counter_str, 'I0')-1;
            column.I1 = data_read.find_counter_column(counter_str, 'I1')-1;
            column.I2 = data_read.find_counter_column(counter_str, arg.ref)-1;     % this is the channel for the diode after foil.
            column.spear = data_read.find_counter_column(counter_str, 'spear')-1;

            if column.I2 < 1
                disp(['    *** A non-existent energy reference channel has been given: ' arg.ref '. Use the standard channel for beamline ' arg.beamline])
                column.I2 = data_read.find_counter_column(counter_str, arg.ref_standard)-1;
            end

        end

        % ---- determine edge ---------------------------------------------
        function [edge, calib_mono, norm] = XAS_edge(mono, calib_mono, norm, spectrum, verbose)
            edge = 'unknown';
            % give an edge list:
            edges = {'P', 2145.5;
                     'S',2472.0;
                     'Cl',2822.4;
                     'Ar',3206.0;
                     'K',3607.4;
                     'Ca',4038.1;
                     'Sc',4492.8;
                     'Ti',4966.4;
                     'V',5465.1;
                     'Cr',5989.2;
                     'Mn',6539.0;
                     'Fe',7112.0;
                     'Co',7708.9;
                     'Ni',8332.8;
                     'Cu',8978.9;
                     'Zn',9658.6;
                     'Ga',10367.1;
                     'Ge',11103.1;
                     'As',11866.7;
                     'Se',12657.8;
                     'Br',13473.7;
                     'Kr',14325.6;
                     'Rb',15199.7;
                     'Sr',16104.6;
                     'Y', 17038.4;
                     'Zr',17997.6;
                     'Ru',22117.2;
                     'Pd',24350.3;
                     'IrL1',13418.5;
                     'IrL2',12824.1;
                     'IrL3',11215.2;
                     'PtL1',13990.5;
                     'PtL2',13272.6;
                     'PtL3',11563.8;
                     'AuL1',14352.8;
                     'AuL2',13733.6;
                     'AuL3',11918.7;
                     'HgL1',14829.2;
                     'HgL2',14208.7;
                     'HgL3',12283.9;
                     'PbL1',15860.8;
                     'PbL2',15200.0;
                     'PbL3',13035.2;
                     'CeL1',6548.8;
                     'CeL2',6164.2;
                     'CeL3',5723.4;
                     };

            % run through all possible edges and check if one or more fit
            possible_edges = {};
            % find first inflection point:
            spectrum_diff = diff(spectrum);
            [~,loc] = max(spectrum_diff);
%             figure()
%             plot(mono,spectrum)
%             title('HERE')
%             hold on
%             scatter(mono(loc), spectrum(loc), 'red', 'filled')

            for i = 1:size(edges,1)
                if mono(loc) > edges{i,2}-50 && mono(loc) < edges{i,2}+50
                    possible_edges{end+1} = edges{i,1};
                end
            end

            n = length(possible_edges);
            if n > 0
                my_edge = possible_edges{1};
                if n > 1
                    possible_edges_str = '';
                    for j = 1:n
                        possible_edges_str = sprintf('%s %s', possible_edges_str, possible_edges{j});
                    end
                    if verbose == 1
                        disp(' ')
                        disp(['!!! Two or more edges are possible!  (' possible_edges_str ')'])
                        disp('    Cannot determine proper edge (edit data_read.XAS_edge). ')
                        disp('    Continue without energy calibration and normalization.')
                        disp('    --> setting the calib_mono.calibrate_mono_method = ''none''. ')
                        disp('    --> setting the norm.normalize = ''false''. ')
                    end
                    calib_mono.calibrate_mono_method = 'none';
                    norm.normalize = 'false';
                else
                    edge = my_edge;
                end
            else
                if verbose == 1
                    disp(' ')
                    disp('!!! Cannot find a proper edge (edit data_read.XAS_edge). ')
                    disp('    Cannot determine proper edge (edit data_read.XAS_edge). ')
                    disp('    Continue without energy calibration and normalization.')
                    disp('    --> setting the calib_mono.calibrate_mono_method = ''none''. ')
                    disp('    --> setting the norm.normalize = ''false''. ')
                end
                calib_mono.calibrate_mono_method = 'none';
                norm.normalize = 'false';
            end

            % check if calibration values are given:
            % fip values:
            if strcmp(calib_mono.calibrate_mono_method,'fip') == 1      % fip selected
                myStruct = calib_mono.fip_values;
                fieldNames = fieldnames(myStruct);
                if ~any(strcmp(my_edge,fieldNames))
                    disp('')
                    disp(['!!! The value for calib_mono.fip_values.' my_edge ' is not given in the xas.m file.'])
                    disp('    Continue without energy calibration.')
                    disp('    --> setting the calib_mono.calibrate_mono_method = ''none''. ')
                    calib_mono.calibrate_mono_method = 'none';
                else
                    calib_mono.fip_reference = calib_mono.fip_values.(my_edge);
                end
            % glitch values:
            elseif strcmp(calib_mono.calibrate_mono_method,'glitch') == 1
                myStruct = calib_mono.glitch_values;
                fieldNames = fieldnames(myStruct);
                if ~any(strcmp(my_edge,fieldNames))
                    disp('')
                    disp(['!!! The value for calib_mono.glitch_values.' my_edge ' is not given in the xas.m file.'])
                    disp('    Continue without energy calibration.')
                    disp('    --> setting the calib_mono.calibrate_mono_method = ''none''. ')
                    calib_mono.calibrate_mono_method = 'none';
                else
                    calib_mono.glitch_reference = calib_mono.glitch_values.(my_edge);
                end
            end


            % check if values for normalization are given:
            bkg_treshold_energy = true;
            edge_jump_start = true;

            if norm.normalize == true
                % norm.bkg_treshold_energy:
                myStruct = norm.bkg_treshold_energy;
                fieldNames = fieldnames(myStruct);
                if ~any(strcmp(my_edge,fieldNames))
                    bkg_treshold_energy = false;
                end
                % norm.edge_jump_start values:
                myStruct = norm.edge_jump_start;
                fieldNames = fieldnames(myStruct);
                if ~any(strcmp(my_edge,fieldNames))
                    edge_jump_start = false;
                end
    
                if edge_jump_start == false || bkg_treshold_energy == false
                    disp('')
                    disp(['!!! The values for norm.bkg_treshold_energy.' my_edge ' and/or norm.edge_jump_start.' my_edge ' are not given in the xas.m file.'])
                    disp('    Continue without normalization.')
                    disp('    --> setting the norm.normalize = ''false''. ')
                    norm.normalize = 'false';
                else
                    norm.bkg_treshold_energy.value = norm.bkg_treshold_energy.(my_edge);
                    norm.edge_jump_start.value = norm.edge_jump_start.(my_edge);
                end

            end
        end


    end
end



