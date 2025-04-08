classdef data_calibration
    % define the keyword options:
    properties (Constant)
    end

    % local fundtions here:
    methods (Static)

        % ----------------------------------------------------------------
        % ------ XES -----------------------------------------------------

        % ---- XES calibrate  --------------------------------------------
        function [emiss_calib, SF, use_calib] = XES_calibrate(emiss, specDir, paramFile)

            % check if calibration file exists:
            filename = [specDir paramFile];
            if isfile(filename)
                disp(['   *** use calibration file' filename])
                
                % check if the file was created by the matlab script from Tsu-Chien
                % or by the python script from Thomas:
                param = readmatrix(filename, 'Delimiter',' ', 'NumHeaderLines', 5, 'FileType','text', 'ConsecutiveDelimitersRule', 'join');
                
                if size(param,1) == 4   % Tsu-Chien version
                    emiss_calib = param(2,3) + param(2,2) * emiss + param(2,1) * emiss .* emiss;
                    E0 = param(4,1);
                    SF = param(3,1) * (emiss/1000 - E0).^2 + param(3,2) * (emiss/1000 - E0) + param(3,3);
                    use_calib = 1;
                else      % Thomas version
                    emiss_calib = param(2,1) + param(2,2) * emiss + param(2,3) * emiss .* emiss;
        %            SF = emiss.*0 + 1;
                    SF = param(3,3) * emiss.*emiss + param(3,2) * emiss + param(3,1);
                    use_calib = 1;
                end
                
            else
                if strcmp(paramFile, '')
                    disp('   *** No energy calibration file chosen. Use the raw emission energy data. ')
                else
                    disp('   *** ATTENTION!!  CALIBRATION FILE ')
                    disp(['         ' filename])
                    disp('         DOES NOT EXIST! CONTINUE WITHOUT CALIBRATION!')
                end
                emiss_calib = 0;
                SF = 0;
                use_calib = 0;
            end
        
        end


        % ----------------------------------------------------------------
        % ------ XAS -----------------------------------------------------

        % ----- glitch ---------------------------------------------------
        function mono_shift = XAS_glitch(glitch_energy, mono, i0, plotit)
            mono_shift = 0;
        
            % the glitch should be at ~8985.1
            width = 3;
            e1 = glitch_energy - width;
            e2 = glitch_energy + width;
            
            % bring the data onto a uniform x-axis
            xx = e1:0.05:e2;
            yy = interp1(mono, i0, xx, 'spline');
        
            % fit with a Gaussian and two linear curves
            % Convert x and y into a table, which is the form fitnlm() likes the input data to be in.
            tbl = table(xx', yy');
            modelfun = @(b,x) b(1) + b(2) * x + b(3) * exp(-(x - b(4)).^2/b(5)) + b(6) + b(7) * x;
            b1 = yy(1);
            b2 = 0.0;
            b6 = yy(1);
            b7 = 0.0;
            [minY, pos] = min(yy);
            b3 = minY-yy(1);
            b4 = xx(pos);
            b5 = 0.5;
            beta0 = [b1, b2, b3, b4, b5, b6, b7]; % Guess values to start with.  Just make your best guess.

            lin_bkg = 2;

            % Now the next line is where the actual model computation is done.
            try
                % Code that might cause an error
                mdl = fitnlm(tbl, modelfun, beta0);
            catch ME
                % An error orrured, try with only one linear background:
                modelfun = @(b,x) b(1) + b(2) * x + b(3) * exp(-(x - b(4)).^2/b(5));
                beta0 = [b1, b2, b3, b4, b5]; % Guess values to start with.  Just make your best guess.

                % try again:
                try
                    % Code that might cause an error
                    mdl = fitnlm(tbl, modelfun, beta0);
                    lin_bkg = 1;
                catch ME
                    % There is still an error!
                    % Code to handle the error
                    disp(['An error occurred: ' ME.message]);
                    % Optionally, take alternative actions or re-throw the error
                    return
                end
            end

            mdl = fitnlm(tbl, modelfun, beta0);
            % Extract the coefficient values from the the model object.
            % The actual coefficients are in the "Estimate" column of the "Coefficients" table that's part of the mode.
            coefficients = mdl.Coefficients{:, 'Estimate'};
            % create smaller line space for fit  curve
            X = min(xx):0.01:max(xx); 
            % Create data using the model:
            if lin_bkg == 2
                yFitted = coefficients(1) + coefficients(2) * X + ...
                    coefficients(3) * exp(-(X - coefficients(4)).^2 / coefficients(5)) + ...
                    coefficients(6) + coefficients(7) * X;
            else
                yFitted = coefficients(1) + coefficients(2) * X + ...
                    coefficients(3) * exp(-(X - coefficients(4)).^2 / coefficients(5));
            end
            
            if strcmp(plotit, 'plot')
                figure()
                plot(mono, i0)
                hold on
                plot(X, yFitted, 'r-');
                xlim([e1 e2])
                xlabel('energy  (eV)')
                ylabel('intensity  arb. units)')
                title('fit the glitch in i0')
            end
            
            mono_shift = glitch_energy - coefficients(4);
        end


        % ----- fip ------------------------------------------------------
        function mono_shift = XAS_fip(ref_energy, mono, I0, I, calib_mono)

            mono_shift = 0; 
            width = 5;

            % get the first derivative
            mysignal = log(I0./I);
            signal_raw = mysignal;
            
            if calib_mono.fip_smooth_data

                % Savitzky-Golay filtering:
                if strcmp(calib_mono.fip_smooth_method,'Savitzky-Golay')
                    order = calib_mono.fip_smooth_SG_order;
                    framelen = calib_mono.fip_smooth_SG_frame_length;
                    if calib_mono.cnt == 1 disp(['    *** Apply ' calib_mono.fip_smooth_method ' smoothing with order ' num2str(order) ' and frame length ' num2str(framelen)]); end
                    signal = sgolayfilt(mysignal,order,framelen);

                % Gaussian window or moving average:
                elseif strcmp(calib_mono.fip_smooth_method,'gaussian') || strcmp(calib_mono.fip_smooth_method, 'movmean')
                    if calib_mono.cnt == 1 disp(['    *** Apply ' calib_mono.fip_smooth_method ' smoothing with window ' num2str(calib_mono.fip_smooth_window)]); end
                    signal = smoothdata(mysignal,calib_mono.fip_smooth_method, calib_mono.fip_smooth_window);

                % None of these selected (or typo):
                else
                    disp('    !!! No proper smoothing mechanism has been selected. Proceed without smoothing!')
                    signal = mysignal;
                end
            else
                signal = mysignal;
            end
            
            signal_diff = gradient(signal(:));
            signal_diff_raw = gradient(signal_raw(:));
            
            % create the data with very small stepsize
            e1 = ref_energy(1)-width;
            e2 = ref_energy(1)+width;
            mono_ref = e1:0.01:e2;
            diff_ref = interp1(mono, signal_diff, mono_ref, 'spline');
            diff_ref_raw = interp1(mono, signal_diff_raw, mono_ref, 'spline');

            mysignal_region = interp1(mono, mysignal, mono_ref, 'spline');
            signal_region = interp1(mono, signal, mono_ref, 'spline');
        
            [~, loc] = max(diff_ref);
            mono_shift = ref_energy(1) - mono_ref(loc);
                        
            if strcmp(calib_mono.plot, 'plot')

                figure()
                subplot(2,1,1)
                plot(mono_ref, mysignal_region)
                if calib_mono.fip_smooth_data
                    hold on
                    plot(mono_ref, signal_region, 'red')
                end
                axis([e1 e2 min(mysignal_region) max(mysignal_region)]);
                if calib_mono.fip_smooth_data
                    legend('interpolated raw data', 'smoothed data')
                else
                    legend('interpolated raw data')
                end    
                title('data')

                subplot(2,1,2)
                plot(mono_ref,diff_ref)
                hold on
                plot(mono, signal_diff, '*')
                axis([e1 e2 min(diff_ref) max(diff_ref)*1.05]);
                if calib_mono.fip_smooth_data
                    legend('interpolated derivative', 'derivative of smoothed foil data')
                else
                    legend('interpolated derivative', 'derivative of raw foil data')
                end    
                title('first inflection point')
            end
        end


        % ---- XAS calibrate  --------------------------------------------
        function [shift, mono_reference_energy, calibrate_mono] = XAS_calibrate(arg, data, column, calib_mono, verbose)

            calibrate_mono = 0;
            shift = 0;
            mono = data(:,column.mono);
            mono_reference_energy = 0;
        
            % MONO CALIBRATION:
            if strcmp(calib_mono.calibrate_mono_method, 'fip') == 1
                if column.I0 > 0 I0 = data_read.correct_one_values(data(:,column.I0)); end
                if column.I1 > 0 I1 = data_read.correct_one_values(data(:,column.I1)); end
                if column.I2 > 0 I2 = data_read.correct_one_values(data(:,column.I2)); end

                I_0 = I0;
                I_ = I2;

                shift = data_calibration.XAS_fip(calib_mono.fip_reference, mono, I_0, I_, calib_mono);
                mono_reference_energy = calib_mono.fip_reference;
                disp(['*** shift from first inflection point: ' num2str(shift) ' eV']);
                calibrate_mono = 1;
                
            elseif strcmp(calib_mono.calibrate_mono_method, 'glitch') == 1
                I0 = data_read.correct_one_values(data(:,column.I0));
                % check if the spear data exist:
                if any(strcmp('spear',column))
                    spear = correct_one_values(data(:,column.spear));
                else
                    spear = 1;
                end
                I0 = I0./spear;  % this is to correct for the refill

                shift = data_calibration.XAS_glitch(calib_mono.glitch_reference, mono, I0, calib_mono.plot);

                disp(['*** shift from glitch fit using a Gaussian: ' sprintf('%0.2f', shift) ' eV']);
                calibrate_mono = 1;




            elseif strcmp(calib_mono.calibrate_mono_method, 'glitch old') == 1
                I0 = data_read.correct_one_values(data(:,column.I0));
                spear = correct_one_values(data(:,column.spear));
                I0 = I0./spear;  % this is to correct for the refill
                if strcmp(element, 'Cu') == 1 
                    shift = fit_glitch_Cu_Si311(calibrate_mono_glitch_reference, mono, I0, calib_mono.plot);
                elseif strcmp(element, 'Fe') == 1 
                    shift = fit_glitch(calibrate_mono_glitch_reference, mono, I0, mono_crystal, calib_mono.plot);
                elseif strcmp(element, 'Mn') == 1 
                    shift = fit_glitch(calibrate_mono_glitch_reference, mono, I0, mono_crystal, calib_mono.plot);
                end
                mono_reference_energy = calibrate_mono_glitch_reference;
                disp(['*** shift from glitch fit using a Gaussian: ' sprintf('%0.2f', shift) ' eV']);
                calibrate_mono = 1;
                
            elseif strcmp(calib_mono.calibrate_mono_method, 'foil') == 1   % i.e. foil is used
                I1 = data_read.correct_one_values(data(:,column.I1));
                I2 = data_read.correct_one_values(data(:,column.I2));
                disp(' ')
                disp('Need to work on the full foil energy calibration again! ')
                disp(' ')
                %shift = xas_energy_calibration_foil(homeDir, calibrate_mono_foil_reference, mono, I1, I2, runs(i));
                shift = 0;
                calibrate_mono = 1;
            
            elseif strcmp(calib_mono.calibrate_mono_method, 'foil_peak') == 1
                I1 = data_read.correct_one_values(data(:,column.I1));
                I2 = data_read.correct_one_values(data(:,column.I2));
                shift = xas_energy_calibration_foil_peak(calibrate_mono_foil_peak_reference, mono, I1, I2, 'smooth', calib_mono.plot);
                disp(['*** shift from foil pre-edge peak: ' sprintf('%0.2f', shift) ' eV']);
                calibrate_mono = 1;
            
            elseif strcmp(calib_mono.calibrate_mono_method, 'constant') == 1
                shift = calib_mono.rigid_shift;
                disp(['*** use constant shift: ' sprintf('%0.2f', shift) ' eV']);
                calibrate_mono = 1;
            
            else
                if verbose == 1
                    disp('!!! No mono calibration method is given. Continue without energy calibration.')
                    calibrate_mono = 0;
                    shift = 0;
                end
            end
        end  

    end
end
