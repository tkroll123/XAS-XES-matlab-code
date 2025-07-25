classdef data_save

    properties
    end

    methods (Static)

        % ---------------------------
        function str = create_run_string(runs)
            runs = sort(runs);

            str = '';
            if length(runs) < 4
                for ii = 1:length(runs)
                    if ii == 1
                        str = [num2str(runs(ii))];
                    else
                        str = [str '_' num2str(runs(ii))];
                    end
                end
            else    % i.e. more than five files used
                %scanStr = create_run_string(arg.runs);
                str = num2str(runs(1));
                runs(end+1) = runs(end);
                sequence_length = 1;
                for i = 2:length(runs)-1
                    if runs(i)-runs(i-1)==1 && runs(i+1)-runs(i)==1     % the previous and next element exists.
                        sequence = true;
                        sequence_length = sequence_length + 1;
                    else
                        sequence = false;
                    end

                    if sequence == false && sequence_length > 1
                        str = [str '-' num2str(runs(i))];
                        sequence_length = 1;
                    elseif sequence == false && sequence_length == 1
                        str = [str '_' num2str(runs(i))];
                    end
                end
            end
        end

        % ---------------------------
        function str = create_scan_string(scans)

            if length(scans) == 1
                str = num2str(scans(1));
            else
                str = [num2str(scans(1)) '-' num2str(scans(end))];
            end
        end

        % ---------------------------
        function [y] = save_rixs(p, mono, emiss_en, RIXS_plane, method)
            y = 0;

            % check if folder average exists and create if not
            if ~exist(p.saveDir, 'dir')
                mkdir(p.saveDir);
            end

            cd(p.saveDir);

            % BL 15-2: RIXS
            runStr = p.run_str; %data_save.create_run_string(p.runs);
            if p.calibrate_rixs == 0
                savefile_Str = [p.file '__' p.counter  '_' runStr '_' method '_uncalibrated.dat'];
            else
                savefile_Str = [p.file '__' p.counter  '_' runStr '_' method '.dat'];
            end

            fname = [pwd '/' savefile_Str];
            fid=fopen(fname,'w');
            fprintf(fid, p.header1);
            fprintf(fid, p.header2);
            fprintf(fid, '# data \n');
            if strcmp(method,'EE')
                fprintf(fid, p.data_names_EE);
            elseif strcmp(method,'ET')
                fprintf(fid, p.data_names_ET);
            end
            
            size(RIXS_plane)
            size(mono)
            size(emiss_en)

            for i=1:length(mono)
                for j=1:length(emiss_en)
                    fprintf(fid, '%f\t%f\t%f\t%f\n', mono(i), emiss_en(j), RIXS_plane(j,i), RIXS_plane(j,i));
                end
                fprintf(fid, '\n');
            end
            fclose(fid);

            disp(['save dir  = ', pwd])
            disp(['save file = ', savefile_Str])
            

        end

        % ---------------------------
        function [y] = save(p)
            y = 0;

            % check if folder average exists and create if not
            if ~exist(p.saveDir, 'dir')
                mkdir(p.saveDir);
            end

            cd(p.saveDir);

            % BL 15-2: XAS
            if strcmp(p.scan_type, 'energy') && strcmp(p.beamline, '15-2')
                %runStr = data_save.create_run_string(p.runs);
                if p.calibrate_mono == 0
                    savefile_Str = [p.file '__xas_' p.run_str '_not_aligned.dat'];
                else
                    savefile_Str = [p.file '__xas_' p.run_str '.dat'];
                end

            % BL 7-3, 9-3: XAS
            elseif strcmp(p.scan_type, 'energy') && any(strcmp(p.beamline,p.XAS_BLs))
                runStr = data_save.create_run_string(p.runs);
                scanStr = data_save.create_scan_string(p.scans);
                if p.calibrate_mono == 0
                    savefile_Str = [p.file '__xas_' runStr '.' scanStr '_not_aligned.dat'];
                else
                    savefile_Str = [p.file '__xas_' runStr '.' scanStr '.dat'];
                end

            % BL 15-2: pump-probe, delay
            elseif strcmp(p.scan_type, 'delay')
                runStr = data_save.create_run_string(p.runs);
                savefile_Str = [p.file '__delay_' runStr '.dat'];

            % BL 15-2: XES
            elseif strcmp(p.scan_type, 'emiss')
                runStr = p.run_str; %data_save.create_run_string(p.runs);
                if p.calibrate_xes == 0
                    savefile_Str = [p.file '__' p.counter  '_' runStr '_uncalibrated.dat'];
                else
                    savefile_Str = [p.file '__' p.counter  '_' runStr '.dat'];
                end

            end
            savefile = [pwd '/' savefile_Str];

            writecell(p.data_cell, savefile);
            disp(['save dir  = ', pwd])
            disp(['save file = ', savefile_Str])

        end

    end
end



