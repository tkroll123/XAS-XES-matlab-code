classdef data_xes
    % define the keyword options:
    properties (Constant)
    end

    % local fundtions here:
    methods (Static)

        % ---- xes prosessing for Rowland geometry ------------------------
        function xes_rowland(homeDir, saveDir, arg, norm)
        %function xes_rowland(directory, filename, counter, runs)
                        
            cd(homeDir)
        
            % unspec the file, just in case.
            data_unspec.unspec(arg.file, homeDir);      % automatically changes into the file_dir directory
        
            run_list = [];
            cnt = 1;
            for i = 1:length(arg.runs)
                % read in the data for each individual scan
                run = sprintf('%03d',arg.runs(i));
                file = [homeDir arg.file '_dir/' arg.file '_' run '.dat'];
                % check if file exists:
                if isfile(file) == 0
                    disp(['*** File ' file ' does not exist! Abort.'])
                    return
                end

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                % print the sample position:
                if isfield(arg, 'print_sample_position')
                    if arg.print_sample_position == true
                        data_read.print_motor_positions(arg.runs(i), file)
                    end
                end

                % exclude runs if it is at a certain position:
                skip_run = false;
                if (isfield(arg, 'exclude_Sx') || isfield(arg, 'exclude_Sy') || isfield(arg, 'exclude_Sz'))
                    skip_run = data_read.exclude_runs(arg, arg.runs(i), file);
                end
                if skip_run == true
                    break
                end

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
        
                [skip_lines, counter_str] = data_read.get_header_length_spec(file);
                data = readmatrix(file, 'Delimiter',' ', 'NumHeaderLines', skip_lines, 'FileType','text', 'ConsecutiveDelimitersRule', 'join');
        
                % get the columns for all counters needed
                column_emiss = data_read.find_counter_column(counter_str, 'emiss')-1;
                if column_emiss < 0
                    disp(['   !!! ' arg.file ' run ' num2str(run) ' is not an emission scan!'])
                    counter_list = split(counter_str);
                    disp(['       scan type: ' char(counter_list(2))])
                    disp(' ')
                    return
                end

                run_list = [run_list arg.runs(i)];

                column_FF = data_read.find_counter_column(counter_str, arg.counter)-1;
                column_I0 = data_read.find_counter_column(counter_str, 'I0')-1;
        
                % initialize the summed data and energy axis
                if cnt == 1
                    i0_sum = zeros(length(data(:,1)),1);
                    
                    FF_sum = zeros(length(data(:,1)),1);
                    emiss = data(:,column_emiss);
                    % correct for energy calibration

                    [emiss_corr, SF, use_calib] = data_calibration.XES_calibrate(emiss, homeDir, arg.calib);
                end
                
                % sum the data
                % check for entries with value 1 and correct them with the average
                % of the neighboring values:
                
                i0_sum = i0_sum + data_read.correct_one_values(data(:,column_I0));
                FF_sum = FF_sum + data_read.correct_one_values(data(:,column_FF));

                cnt = cnt + 1;
            end

            % create a string for the run numbers:
            run_str = data_save.create_run_string(run_list);

            % Data processing:
            emiss_calib = emiss;
            FF_sum_calib = FF_sum;
        
            % correct for calibration
            if use_calib > 0
                FF_sum_calib = FF_sum_calib .* SF;
                emiss_calib = emiss_corr;
            end
        
            % compare corrected and uncorrected spectra:
            %figure()
            %plot(emiss, FF_sum)
            %hold on
            %plot(emiss_calib, FF_sum)
            %legend('emiss', 'emiss_calib', 'Interpreter', 'none')
            
            % get the spectrum in actual number of photons
            spectrum_ph = FF_sum_calib ./ i0_sum * mean(i0_sum);
            
            % plot the uncorrected spectrum with background
            figure()
            plot(emiss_calib, spectrum_ph)
            hold on
            xlabel('Emission energy  (eV)')
            ylabel('Intensity  (#photons)')
            title({['file: ' arg.file], ['runs: ' run_str]}, 'Interpreter','none')

            % subtract background and normalize spectrum
            bkg_high_1 = norm.bkg_data_points_high;
            if norm.bkg_data_points_high_width == 0
                bkg_high_2 = 1;
            else
                bkg_high_2 = max(1, norm.bkg_data_points_high-norm.bkg_data_points_high_width);
            end
            % mark the fitting region:
            scatter(emiss_calib(bkg_high_1), spectrum_ph(bkg_high_1), 'green', 'filled')
            scatter(emiss_calib(bkg_high_2), spectrum_ph(bkg_high_2), 'green', 'filled')
            
            bkg_low_1 = length(spectrum_ph)-norm.bkg_data_points_low;
            if norm.bkg_data_points_low_width == 0
                bkg_low_2 = length(spectrum_ph);
            else
                bkg_low_2 = min(length(spectrum_ph), length(spectrum_ph) - (norm.bkg_data_points_low-norm.bkg_data_points_low_width));
            end
            % mark the fitting region:
            scatter(emiss_calib(bkg_low_1), spectrum_ph(bkg_low_1), 'red', 'filled')
            scatter(emiss_calib(bkg_low_2), spectrum_ph(bkg_low_2), 'red', 'filled')

            % determine background             
            %  (i) create equal distant curves:
            bkg_equal = emiss_calib(end):0.1:emiss_calib(1);
            spectrum_equal = interp1(emiss_calib, spectrum_ph, bkg_equal);
            
            [~,bkg_low_1_eq] = min(abs((bkg_equal - emiss_calib(bkg_low_1))));
            [~,bkg_low_2_eq] = min(abs((bkg_equal - emiss_calib(bkg_low_2))));
            [~,bkg_high_1_eq] = min(abs((bkg_equal - emiss_calib(bkg_high_1))));
            [~,bkg_high_2_eq] = min(abs((bkg_equal - emiss_calib(bkg_high_2))));

            bkg_low_spec = mean(spectrum_equal(min(bkg_low_1_eq,bkg_low_2_eq):max(bkg_low_1_eq,bkg_low_2_eq)));
            bkg_high_spec = mean(spectrum_equal(min(bkg_high_1_eq,bkg_high_2_eq):max(bkg_high_1_eq,bkg_high_2_eq)));
    
            bkg_low_en = 1/2*(max(bkg_equal(bkg_low_1_eq),bkg_equal(bkg_low_2_eq))+min(bkg_equal(bkg_low_1_eq),bkg_equal(bkg_low_2_eq)));
            bkg_high_en = 1/2*(max(bkg_equal(bkg_high_1_eq),bkg_equal(bkg_high_2_eq))+min(bkg_equal(bkg_high_1_eq),bkg_equal(bkg_high_2_eq)));

            scatter(bkg_low_en, bkg_low_spec, 'blue', 'filled')
            scatter(bkg_high_en, bkg_high_spec, 'blue', 'filled')
            
            b = (bkg_high_spec-bkg_low_spec)/(bkg_high_en-bkg_low_en);
            a = bkg_high_spec - b*bkg_high_en;
            
            bkg = a + b*emiss_calib;

            % plot the background
            plot(emiss_calib, bkg);

            % subtract background and normalize data:
            spectrum_bkg = spectrum_ph - bkg;
            
            area = -trapz(emiss_calib, spectrum_bkg);    % the - sign comes from the fact that emiss runs from higher to lower values
            spectrum_norm = spectrum_bkg ./ area;

            % plot the data corrected data:
            figure()
            plot(emiss_calib, spectrum_norm)
            xlabel('Emission energy  (eV)')
            ylabel('Normalized intensity  (arb. units)')
            title({['file: ' arg.file], ['runs: ' run_str]}, 'Interpreter','none')
            

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            % save the data:
            if arg.save > 0
                
                p.scan_type = 'emiss';
                p.calibrate_xes = use_calib;
                p.runs = run_list;
                p.saveDir = saveDir; 
                p.file = arg.file;
                p.counter = arg.counter;
                p.run_str = run_str;

                if use_calib == 0
                    header = {'# XES calibration: ', 'none','','','',''};
                else
                    header = {'# XES calibration: ', 'configuration file',arg.calib,'','',''};
                end
                titles = {'emiss_calib','emiss','spectrum_ph','spectrum_norm','FF_sum','FF_sum_calib'};
                mydata = [emiss_calib emiss spectrum_ph spectrum_norm  FF_sum FF_sum_calib];
                p.data_cell = [header; titles; num2cell(mydata)];
                
                data_save.save(p);
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
                
            cd(homeDir)
        end



    end
end





