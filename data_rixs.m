classdef data_rixs
    % define the keyword options:
    properties (Constant)
    end

    % local fundtions here:
    methods (Static)

        function [Sx, Sz, conc_matrix] = concentration_matrix(arg, path, plotit)
        
            for i = 1:length(arg.conc)
                % read in the data for each individual scan
                scan = sprintf('%03d',arg.conc(i));
                file = [path arg.file '_dir/' arg.file '_' scan '.dat'];
                
                [skip_lines, counter_str] = data_read.get_header_length_spec(file);
                data = readmatrix(file, 'Delimiter',' ', 'NumHeaderLines', skip_lines, 'FileType','text', 'ConsecutiveDelimitersRule', 'join');
            
                % get the columns for all counters needed
                column_FF = data_read.find_counter_column(counter_str, arg.counter)-1;
                column_Sz = data_read.find_counter_column(counter_str, 'Sz')-1;
                column_I0 = data_read.find_counter_column(counter_str, 'I0')-1;

                if column_Sz < 0
                    disp([' !!! run' scan ' is not a Sz scan. Ignore the concentration correction.'])
                    conc_matrix = 0;
                    return
                end
                
                FF = data_read.correct_one_values(data(:,column_FF));
                I0 = data_read.correct_one_values(data(:,column_I0));
                Sz = data_read.correct_one_values(data(:,column_Sz));
                
                if i == 1
                    conc_matrix = zeros(size(FF,1), length(arg.conc));
                    Sx = zeros(length(arg.conc),1);
                end
                
                Sx(i) = data_read.get_motor_position('Sx', file);
                conc_matrix(:,i) = FF./I0;
                
            end
            
            % normalize the concentration matrix
            mean_value = mean(mean(conc_matrix));
            conc_matrix = conc_matrix / mean_value;
            
            if strcmp(plotit, 'plot')==1
                % plot the concentration matrix
                figure()
                imagesc(Sx, Sz, conc_matrix)
                xlabel('Sx')
                ylabel('Sz')
                % create a string for the run numbers:
                conc_str = data_save.create_run_string(arg.conc);
                title({['file: ' arg.file], ['runs: ' conc_str]}, 'Interpreter','none')
                colorbar
                
            end
        
        end


        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 
        % % ---- scan energy at constant emiss ------------------------------
        % function rixs_scan_energy_fix_emiss(homeDir, saveDir, arg, calib_mono)
        % 
        % 
        %     % get the concentration profile if requested:
        %     if length(arg.conc)>1
        %         [Sx, Sz, conc_matrix] = data_rixs.concentration_matrix(arg, homeDir, 'plot');
        %     end
        % 
        %     % create a string for the run numbers:
        %     run_str = data_save.create_run_string(arg.runs);
        % 
        % 
        %     % read in the emission energy and sort the scans in decreasing order
        %     d = containers.Map('KeyType', 'double', 'ValueType', 'any');
        % 
        %     for i = 1:length(arg.runs)
        %         % read in the data for each individual scan
        %         scan = sprintf('%03d',arg.runs(i));
        %         file = [homeDir arg.file '_dir/' arg.file '_' scan '.dat'];
        %         emiss = data_read.get_motor_position('emiss', file);
        %         if emiss == 0  % i.e. file did not exist
        %             return
        %         end
        % 
        %         % check if that emission energy already exists
        %         if isKey(d, emiss)
        %             d(emiss) = [d(emiss) arg.runs(i)];
        %         else
        %             d(emiss) = [arg.runs(i)];
        %         end
        %     end
        % 
        %     keys_cell = d.keys;        % cell array
        %     keys_array = cell2mat(keys_cell);  % numeric array
        %     % sort in decreasing emission energy:
        %     keys_array = sortrows(keys_array','descend');
        % 
        %     % load the data to put it into the RIXs matrix
        %     cnt = 0;
        %     for i = 1:length(keys_array)
        %         emiss_en = keys_array(i);
        %         runNbrs = d(emiss_en);
        %         for j = 1:length(runNbrs)
        %             cnt = cnt + 1;
        %             runNbr = runNbrs(j);
        %             % read in the data for each individual scan
        %             scan = sprintf('%03d',runNbr);
        %             file = [homeDir arg.file '_dir/' arg.file '_' scan '.dat'];
        %             [skip_lines, counter_str] = data_read.get_header_length_spec(file);
        %             data = readmatrix(file, 'Delimiter',' ', 'NumHeaderLines', skip_lines, 'FileType','text', 'ConsecutiveDelimitersRule', 'join');
        % 
        %             % get the columns for all counters needed
        %             column_FF = data_read.find_counter_column(counter_str, arg.counter)-1;
        %             column_mono = data_read.find_counter_column(counter_str, 'absev')-1;  % that's the mono energy, we are reading out the encoder
        %             column_I0 = data_read.find_counter_column(counter_str, 'I0')-1;
        % 
        %             % shift energy and define reference energy axis.
        %             mono = data(:,column_mono);
        % 
        %             % XAS energy correction
        %             shift = 0;
        %             if strcmp(calib_mono.calibrate_mono_method,'none') == 0
        %                 calib_mono.cnt = cnt;
        %                 [shift, reference_energy_tabulated, calibrate_mono] = ...
        %                     data_calibration.XAS_calibrate(arg, data, column, calib_mono, cnt);
        %             else
        %                 if cnt == 1
        %                     fprintf(' !!! No mono calibration method set (''none''). Continue without energy calibration. \n')
        %                     calibrate_mono = 0;
        %                     shift = 0;
        %                     reference_energy_tabulated = 0;
        %                 end
        %             end
        %             mono = mono + shift;    
        % 
        %             if cnt==1
        %                 % get the lowest step size in the mono scan and create an equal
        %                 % stepsize reference mono:
        %                 step = mono(1:end-1);
        %                 for j=1:length(step)
        %                     step(j) = mono(j+1)-mono(j);
        %                 end
        %                 round(min(step),2);
        %                 mono_ref = mono(1):round(min(step),2):mono(end);
        %                 %mono_ref = mono;
        % 
        %                 % initialize the RIXS plane and energy axis
        %                 RIXS_EE = zeros(length(keys_array), length(mono_ref));
        % 
        %             end
        % 
        %             FF = interp1(mono, data_read.correct_one_values(data(:,column_FF)),mono_ref); % alternative: spline, pchip
        %             i0 = interp1(mono, data_read.correct_one_values(data(:,column_I0)),mono_ref);
        % 
        %             spectrum_ph = FF./i0 * mean(i0, 'omitnan');
        % 
        %             % correct for concentration:
        %             if size(arg.conc,2) > 1
        %                 if size(conc_matrix,2) > 1
        %                     Sx_pos = data_read.get_motor_position('Sx', file);
        %                     Sz_pos = data_read.get_motor_position('Sz', file);
        %                     [Sx_difference, Sx_min] = min(abs(Sx - Sx_pos));
        %                     [Sz_difference, Sz_min] = min(abs(Sz - Sz_pos));
        % 
        %                     if Sx_difference > 0.05
        %                         disp([' !!! Sx difference too large: Sx position: ' num2str(Sx_pos) ', difference: ' num2str(Sx_difference) ', run:' num2str(runNbr)])
        %                     end
        %                     if Sz_difference > 0.05
        %                         disp([' !!! Sx difference too large: Sx position: ' num2str(Sz_pos) ', difference: ' num2str(Sz_difference) ', run:' num2str(runNbr)])
        %                     end
        %                     conc_factor = conc_matrix(Sz_min, Sx_min);
        % 
        %                     spectrum_ph = spectrum_ph / conc_factor;
        %                 end
        %             end
        % 
        %             % fill the RIXS plane:
        %             if j == 1
        %                 RIXS_EE(i, :) = spectrum_ph;
        %             else
        %                 RIXS_EE(i, :) = RIXS_EE(i, :) + spectrum_ph;
        %             end
        % 
        %         end  % for j
        %     end   % for i
        % 
        %     values = d.values;
        %     for i = 1:length(values)
        %         RIXS_EE(i,:) = RIXS_EE(i,:) / length(values{length(values)-i+1});
        %     end
        % 
        %     % emission energy axis:
        %     EE_as_is = keys_array';
        % 
        %     % apply the calibration correction:
        %     [emiss_corr, SF, use_calib] = data_calibration.XES_calibrate(EE_as_is, homeDir, arg.calib);
        %     if use_calib == 1
        %         RIXS_EE = RIXS_EE.*SF;
        %         EE = emiss_corr;
        %     else
        %         EE = EE_as_is;
        %     end
        % 
        %     % plot the emission energy RIXS plane:
        %     figure()
        %     %imagesc(mono_ref, EE, RIXS_EE)
        %     map=pcolor(mono_ref, EE, RIXS_EE);
        %     %map.FaceColor = 'interp';
        %     set(map, 'EdgeColor', 'none');
        %     title({['file: ' arg.file], ['runs: ' run_str]}, 'Interpreter','none')
        %     xlabel('incident energy  (eV)')
        %     ylabel('emission energy  (eV)')
        %     colorbar;
        % 
        %         disp("--------")
        %         size(mono_ref)
        %         size(EE)
        %         size(RIXS_EE)
        %         disp("--------")
        % 
        %     emission_steps = size(EE,1)-1;
        %     for i=1:size(EE,1)-1
        %         emission_steps(i) = EE(i+1)-EE(i);
        %     end
        % 
        %     % convert into energy transfer
        %     ET = mono_ref(1)-EE(1):0.2:mono_ref(end)-EE(end);
        % 
        %     RIXS_ET = nan(size(ET,2), length(mono_ref));
        %     for i = 1:length(mono_ref)
        %         emission = RIXS_EE(:,i); % the vertical cut
        %         spectrum_em = interp1(mono_ref(i)-EE, emission, ET);
        %         RIXS_ET(:,i) = spectrum_em;
        %     end
        % 
        %     figure()
        %     %clims = [-inf inf];
        %     clims = [0 4000];
        %     ET_map = imagesc(mono_ref, ET, RIXS_ET, clims);
        %     set(gca,'YDir','normal');
        %     title({['file: ' arg.file], ['runs: ' run_str]}, 'Interpreter','none')
        %     xlabel('incident energy  (eV)')
        %     ylabel('energy transfer  (eV)')
        %     colorbar;
        % 
        %     aspect_ratio = ( (max(ET)-min(ET)) / (max(mono_ref)-min(mono_ref)) );
        %     pbaspect([1 aspect_ratio 1]);
        % 
        %     % save the data:
        %     if arg.save > 0
        % 
        %         p.scan_type = 'rixs_energy';
        %         p.calibrate_rixs = use_calib;
        %         p.runs = arg.runs;
        %         p.saveDir = saveDir; 
        %         p.file = arg.file;
        %         p.counter = arg.counter;
        %         p.run_str = run_str;
        %         p.calibrate_mono = calibrate_mono;
        % 
        % 
        %         if use_calib == 0
        %             p.header1 = '# XES calibration: none \n';
        %         else
        %             p.header1 = ['# XES calibration: configuration file ' arg.calib '\n'];
        %         end
        %         if length(arg.conc) > 1
        %             conc_str = data_save.create_run_string(arg.conc);
        %             p.header2 = ['# concentration scans: ' conc_str '\n'];
        %         else
        %             p.header2 = '# concentration scans: none ';
        %         end
        %         p.header3 = {'# Mono calibration: ',calib_mono.calibrate_mono_method,'   reference energy: ',reference_energy_tabulated,'',''};
        % 
        %         p.data_names_ET = 'incident_energy \t energy_transfer \t counts \n';
        %         p.data_names_EE = 'incident_energy \t emission_energy \t counts \n';
        % 
        %         data_save.save_rixs(p, mono_ref, EE, RIXS_EE, 'EE');
        %         data_save.save_rixs(p, mono_ref, ET, RIXS_ET, 'ET');
        %     end
        % 
        % end   % function rixs_scan_energy_fix_emiss


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % ---- scan energy at constant emiss ------------------------------
        function rixs_scan_energy_fix_emiss(homeDir, saveDir, arg, calib_mono)


            % get the concentration profile if requested:
            if length(arg.conc)>1
                [Sx, Sz, conc_matrix] = data_rixs.concentration_matrix(arg, homeDir, 'plot');
            end

            % create a string for the run numbers:
            run_str = data_save.create_run_string(arg.runs);


            % read in the emission energy and sort the scans in decreasing order
            d = containers.Map('KeyType', 'double', 'ValueType', 'any');

            for i = 1:length(arg.runs)
                % read in the data for each individual scan
                scan = sprintf('%03d',arg.runs(i));
                file = [homeDir arg.file '_dir/' arg.file '_' scan '.dat'];
                emiss = data_read.get_motor_position('emiss', file);
                if emiss == 0  % i.e. file did not exist
                    return
                end

                % check if that emission energy already exists
                if isKey(d, emiss)
                    d(emiss) = [d(emiss) arg.runs(i)];
                else
                    d(emiss) = [arg.runs(i)];
                end
            end

            keys_cell = d.keys;        % cell array
            keys_array = cell2mat(keys_cell);  % numeric array
            % sort in decreasing emission energy:
            keys_array = sortrows(keys_array','descend');

            % load the data to put it into the RIXs matrix
            cnt = 0;
            for i = 1:length(keys_array)
                emiss_en = keys_array(i);
                runNbrs = d(emiss_en);
                for j = 1:length(runNbrs)
                    cnt = cnt + 1;
                    runNbr = runNbrs(j);
                    % read in the data for each individual scan
                    scan = sprintf('%03d',runNbr);
                    file = [homeDir arg.file '_dir/' arg.file '_' scan '.dat'];
                    [skip_lines, counter_str] = data_read.get_header_length_spec(file);
                    data = readmatrix(file, 'Delimiter',' ', 'NumHeaderLines', skip_lines, 'FileType','text', 'ConsecutiveDelimitersRule', 'join');
                
                    % get the columns for all counters needed
                    column_FF = data_read.find_counter_column(counter_str, arg.counter)-1;
                    column_mono = data_read.find_counter_column(counter_str, 'absev')-1;  % that's the mono energy, we are reading out the encoder
                    column_I0 = data_read.find_counter_column(counter_str, 'I0')-1;
                
                    % shift energy and define reference energy axis.
                    mono = data(:,column_mono);
                
                    % XAS energy correction
                    shift = 0;
                    if strcmp(calib_mono.calibrate_mono_method,'none') == 0
                        calib_mono.cnt = cnt;
                        [shift, reference_energy_tabulated, calibrate_mono] = ...
                            data_calibration.XAS_calibrate(arg, data, column, calib_mono, cnt);
                    else
                        if cnt == 1
                            fprintf(' !!! No mono calibration method set (''none''). Continue without energy calibration. \n')
                            calibrate_mono = 0;
                            shift = 0;
                            reference_energy_tabulated = 0;
                        end
                    end
                    mono = mono + shift;    
    
                    if cnt==1
                        % the first scna acts as a reference energy for all
                        % other scans:
                        mono_ref = mono;

                        % initialize the RIXS plane and energy axis
                        RIXS_EE = zeros(length(keys_array), length(mono_ref));


                        % % get the lowest step size in the mono scan and create an equal
                        % % stepsize reference mono:
                        % step = mono(1:end-1);
                        % for j=1:length(step)
                        %     step(j) = mono(j+1)-mono(j);
                        % end
                        % round(min(step),2);
                        % mono_ref = mono(1):round(min(step),2):mono(end);
                        % %mono_ref = mono;
                        
    
                    end
                
                    FF = interp1(mono, data_read.correct_one_values(data(:,column_FF)),mono_ref); % alternative: spline, pchip
                    i0 = interp1(mono, data_read.correct_one_values(data(:,column_I0)),mono_ref);
                
                    spectrum_ph = FF./i0 * mean(i0, 'omitnan');
                    
                    % correct for concentration:
                    if size(arg.conc,2) > 1
                        if size(conc_matrix,2) > 1
                            Sx_pos = data_read.get_motor_position('Sx', file);
                            Sz_pos = data_read.get_motor_position('Sz', file);
                            [Sx_difference, Sx_min] = min(abs(Sx - Sx_pos));
                            [Sz_difference, Sz_min] = min(abs(Sz - Sz_pos));
    
                            if Sx_difference > 0.05
                                disp([' !!! Sx difference too large: Sx position: ' num2str(Sx_pos) ', difference: ' num2str(Sx_difference) ', run:' num2str(runNbr)])
                            end
                            if Sz_difference > 0.05
                                disp([' !!! Sx difference too large: Sx position: ' num2str(Sz_pos) ', difference: ' num2str(Sz_difference) ', run:' num2str(runNbr)])
                            end
                            conc_factor = conc_matrix(Sz_min, Sx_min);
        
                            spectrum_ph = spectrum_ph / conc_factor;
                        end
                    end
                
                    % fill the RIXS plane:
                    if j == 1
                        RIXS_EE(i, :) = spectrum_ph;
                    else
                        if size(RIXS_EE(i,:),1) ~= size(spectrum_ph,1)
                            RIXS_EE(i, :) = RIXS_EE(i, :) + spectrum_ph';
                        else
                            RIXS_EE(i, :) = RIXS_EE(i, :) + spectrum_ph;
                        end
                    end
                    
                end  % for j
            end   % for i

            % divide by the number of scans for each emission energy
            values = d.values;
            for i = 1:length(values)
                RIXS_EE(i,:) = RIXS_EE(i,:) / length(values{length(values)-i+1});
            end

            % emission energy axis:
            EE_as_is = keys_array';

            % apply the emission energy calibration correction:
            [emiss_corr, SF, use_calib] = data_calibration.XES_calibrate(EE_as_is, homeDir, arg.calib);
            if use_calib == 1
                RIXS_EE = RIXS_EE.*SF;
                EE = emiss_corr;
            else
                EE = EE_as_is;
            end

            % plot the emission energy RIXS plane:
            figure()
            map=pcolor(mono_ref, EE, RIXS_EE);
            %map.FaceColor = 'interp';
            set(map, 'EdgeColor', 'none');
            title({['file: ' arg.file], ['runs: ' run_str]}, 'Interpreter','none')
            xlabel('incident energy  (eV)')
            ylabel('emission energy  (eV)')
            colorbar;

            % create an energy transfer map:
            % (i) create an equal stepsize map 
            delta_emiss_min = min(diff(sort(EE)));
            delta_mono_min = min(diff(sort(mono_ref)));
            % round to first significant decimal, but not lower than 0.1
            delta = max(0.1, round(min(delta_emiss_min,delta_mono_min), 1, 'significant'));
            mono_fine = mono_ref(1):delta:mono_ref(end);
            EE_fine = min(EE(1),EE(end)):delta:max(EE(1),EE(end));
            RIXS_EE_fine = zeros(length(EE_fine), length(mono_fine));

            [X_old, Y_old] = meshgrid(mono_ref, EE);
            [X_new, Y_new] = meshgrid(mono_fine, EE_fine);
            RIXS_EE_fine = interp2(X_old, Y_old, RIXS_EE, X_new, Y_new);            

            % % plot the fine emission energy RIXS plane:
            % figure()
            % map=pcolor(mono_fine, EE_fine, RIXS_EE_fine);
            % %map.FaceColor = 'interp';
            % set(map, 'EdgeColor', 'none');
            % title({['Fine EE plane, file: ' arg.file], ['runs: ' run_str]}, 'Interpreter','none')
            % xlabel('incident energy  (eV)')
            % ylabel('emission energy  (eV)')
            % colorbar;

            % convert to energy tranfer map:
            ET = mono_fine(1)-max(EE_fine(1),EE_fine(end)):delta:mono_fine(end)-min(EE_fine(1),EE_fine(end));
            RIXS_ET = nan(length(ET), length(mono_fine));
            for i = 1:length(mono_fine)
                emission = RIXS_EE_fine(:,i); % the vertical cut
                spectrum_em = interp1(mono_fine(i)-EE_fine, emission, ET);
                RIXS_ET(:,i) = spectrum_em;
            end
        
            figure()
            %clims = [-inf inf];
            clims = [0 4000];
            ET_map = imagesc(mono_fine, ET, RIXS_ET, clims);
            set(gca,'YDir','normal');
            title({['file: ' arg.file], ['runs: ' run_str]}, 'Interpreter','none')
            xlabel('incident energy  (eV)')
            ylabel('energy transfer  (eV)')
            colorbar;

            aspect_ratio = ( (max(ET)-min(ET)) / (max(mono_ref)-min(mono_ref)) );
            pbaspect([1 aspect_ratio 1]);

            % save the data:
            if arg.save > 0
                
                p.scan_type = 'rixs_energy';
                p.calibrate_rixs = use_calib;
                p.runs = arg.runs;
                p.saveDir = saveDir; 
                p.file = arg.file;
                p.counter = arg.counter;
                p.run_str = run_str;
                p.calibrate_mono = calibrate_mono;


                if use_calib == 0
                    p.header1 = '# XES calibration: none \n';
                else
                    p.header1 = ['# XES calibration: configuration file ' arg.calib '\n'];
                end
                if length(arg.conc) > 1
                    conc_str = data_save.create_run_string(arg.conc);
                    p.header2 = ['# concentration scans: ' conc_str '\n'];
                else
                    p.header2 = '# concentration scans: none ';
                end
                p.header3 = {'# Mono calibration: ',calib_mono.calibrate_mono_method,'   reference energy: ',reference_energy_tabulated,'',''};

                p.data_names_ET = 'incident_energy \t energy_transfer \t counts \n';
                p.data_names_EE = 'incident_energy \t emission_energy \t counts \n';
                
                data_save.save_rixs(p, mono_ref, EE, RIXS_EE, 'EE');
                data_save.save_rixs(p, mono_fine, ET, RIXS_ET, 'ET');
            end

        end   % function rixs_scan_energy_fix_emiss
        


        % ---- RIXS processing --------------------------------------------
        function rixs(homeDir, saveDir, arg, calib_mono)
        
            % determine what motor is scanned, either energy or emiss
            % then do the proper processing

            % check if directory exists:
            if ~isfolder(homeDir)
                disp('   !!! Folder does not exist! \n')
                disp(['   ' homeDir])
                return
            end
            cd(homeDir);

            % read the first file:
            run = sprintf('%03d',arg.runs(1));
            file = [homeDir arg.file '_dir/' arg.file '_' run '.dat'];
            % check if file exists
            if ~isfile(file)
                disp(['   !!! File ' arg.file ' does not exist in ' homeDir])
                disp(' ')
                return
            else
                % unspec the specfile (format: specfile_xxx.dat)
                data_unspec.unspec(arg.file, homeDir);      % automatically changes into the specfile_dir directory
            end                        
            % read data and columns
            % read the spec file:
            [skip_lines, counter_str] = data_read.get_header_length_spec(file);
 
            counters = split(counter_str);
                
            if strcmp(counters{2},'energy') == 1   % i.e. energy is scanned
                data_rixs.rixs_scan_energy_fix_emiss(homeDir, saveDir, arg, calib_mono)
            elseif strcmp(counters{2},'emiss') == 1   % i.e. emission is scanned
                data_rixs.rixs_scan_emiss_fix_energy(homeDir, saveDir, arg)
            else
                disp([' !!! Cannot interpret the motor that is scanned. It is ' counters{2} ' but should be either energy or emiss. \n'])
                return
            end


        end
    end
end
