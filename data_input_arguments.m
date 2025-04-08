classdef data_input_arguments
    % define the keyword options:
    properties (Constant)
        options = {'save', 'calib', 'pre-edge', 'xes_fit', 'scans', 'exclude', 'spec', 'ref'};
    end

    % local fundtions here:
    methods (Static)

        % ------------------
        function print_input_options(argin)
            if strcmp(argin{end},'XAS Rowland')
                script = 'xas';
            elseif strcmp(argin{end},'XES rowland')
                script = 'xes';
            elseif strcmp(argin{end},'pump probe')
                script = 'pump_probe';
            end
            
            disp(' ')
            disp(' ')
            disp('-- Input syntax:')
            if strcmp(argin{end},'XES rowland')
                disp(['   ' script '(beamline, directory, file, counter, [run numbers], options)'])
            elseif strcmp(argin{end},'XAS Rowland')
                disp('   Beam line 15-2:')
                disp(['     ' script '(beamline, directory, file, counter, [run numbers], options)'])
                disp('      example:')
                disp(['     ' script '(''15-2'', ''2025-01_User'', ''filename'', ''vortDT'', [1:5])'])
                disp('   Beam lines 7-3 and 9-3:')
                disp(['     ' script '(beamline, directory, filename, counter, [run numbers], options)'])
                disp('      example:')
                disp(['     ' script '(''7-3'', ''2025-01_User'', ''filename'', ''vortDT'', [1:5])'])
            elseif strcmp(argin{end},'pump probe')
                disp(['   ' script '(beamline, directory, filename, [run numbers])'])
            end

            disp(' ')
            disp('   NOTE: beamline, directory, file, counter, [run numbers] are mandatory in exactly this order!!')

            disp(' ')
            disp('   options: - for beam lines 7-3 and 9-3 only: ''scans'', [scan numbers]: Includes the given scans for that run. ')
            disp('                                               ''exclude'', [channel numbers]: Channels that are excluded. ')
            disp('                                               ''spec'': Create a spec file from all the data files. ')
            disp('            - ''save'', [0,1]:  The 0 or 1 argument is optional ')
            disp('            - ''calib'', [calib_file]:  Only for XES. If no calib_file is given, a filename of xes_calib is assumed')
            disp('            - ''pre-edge'':  Only for XAS and pump-probe. Here, only the pre-edge back ground fitting is done, but not ')
            disp('                the post edge normalization.')
            disp('            - ''xes_fit'': Only XES. It fits the spectrum with two reference spectra. Not functioning at the moment.')
            disp('            - ''2D'': Only for pum-probe. It indicates that 2D map (time vs energy (XAS or XES)) is done.')
            disp('            - ''norm'': Only for pum-probe. The full background and normalization process is done on the on and off signals.')
            disp('            - ''t0'', value: Only for pum-probe. Value of the delay where t0 was found.')
            disp(' ')
            disp(' ')
            disp('-- General description: ')
            disp('   - xas: If no other argument is given besides the folder, filename, detector and runs, the spectrum is processed without')
            disp('     an incident energy calibration, but including a background correction and edge jump normalization. This can be changed to only')
            disp('     background correction using the keyword ''pre-edge''')
            disp('   - xes: If no other argument is given besides the folder, filename, detector and runs, the spectrum is processed without')
            disp('     an emission energy calibration. I am working on an easy fit with reference spectra, but not done yet.')
            disp('   - pump_probe: If no other argument is given besides the folder, filename and runs, the spectrum is processed without an indident')
            disp('     energy calibration, no background or edge-jump processing, and no t0 shift. If these are desired, the keywords ''pre-edge'',')
            disp('     ''norm'', or ''t0'' are required. ''norm'' is not yet included and also ''pre-edge'' needs be be included. ')
            disp('     Note that the background is determined from the average of laser on and off shots so that the same background is ')
            disp('     subtracted from both so that the difference after background subtraction remains meaningfull. The same is true for the')
            disp('     edge-jump normalization.')
            disp('     ''2D'' is not done yet ')
            disp(' ')
            disp(' ')

        end

        % ------------------
        function [y,error] = norm()
            error = 0;
            y = 1;
        end   % calib

        % ------------------
        function [y,error] = twoDmap()
            error = 0;
            y = 1;
        end   % calib

        % ------------------
        function [y,error] = xes_fit()
            error = 0;
            y = 1;
        end   % calib
        % ------------------
        function [y,error] = pre_edge()
            error = 0;
            y = 1;
        end   % calib
        % ------------------
        function [y,error] = calib(argin, options)
            error = 0;
            index = find(strcmp(argin,'calib'));
            % (i) check if it is the last element:
            if index == length(argin)-1
                y = 'xes_calib.param';
            else
                % check if the next element is a character, if so, check if
                % the next element is a option keyword. If it is, then use
                % xes_calib.param, otherwise it is the calib file
                next_element = argin{index+1};
                if ischar(next_element)
                    % next element is in options
                    if any(strcmp(options, next_element))
                        y = 'xes_calib.param';
                    else
                        y = [next_element '.param'];
                    end
                % it is not a character
                else
                    error = 1;
                    y = '';
                end
            end
        end   % calib

         % ------------------
        function [y,error] = ref(argin, options)
            error = 0;

            index = find(strcmp(argin,'ref'));
            % (i) check if it is the last element:
            if index == length(argin)-1
                disp(['    !!!! No reference channel given, use the standard channel ' arg.ref_standard])
                arg.ref = arg.ref_standard;
            else
                % check if the next element is a character, if so, check if
                % the next element is a option keyword. If it is, then use
                % xes_calib.param, otherwise it is the calib file
                next_element = argin{index+1};
                if ischar(next_element)
                    % next element is in options
                    if any(strcmp(options, next_element))
                        disp(['    !!!! No reference channel given, use the standard channel ' arg.ref_standard])
                        arg.ref = arg.ref_standard;
                    else
                        y = next_element;
                    end
                % it is not a character
                else
                    error = 1;
                    y = '';
                end
            end
        end   % calib

       % ------------------
        function [y,error] = save(argin, options)
            error = 0;
            index = find(strcmp(argin,'save'));
            % (i) check if it is the last element:
            if index == length(argin)-1
                y=1;
            else
                % check if the next element is a character, if so, save = 1
                if ischar(argin(index+1))
                    y=1;
                    % check if the next element is part of options,
                    % otherwise it is an input error:
                    if ~any(strcmp(options, argin{index+1}))
                        error = 1;
                    end
                % the next element must be the value for save
                else
                    y=cell2mat(argin(index+1));
                end
            end
        end   % save

        % ------------------
        function [y,error] = scans(argin, options)
            error = 0;
            index = find(strcmp(argin,'scans'));
            % (i) check if it is the last element:
            if index == length(argin)-1
                y=1;
            else
                % check if the next element is a character, if so, save = 1
                if ischar(argin(index+1))
                    y=1;
                    % check if the next element is part of options,
                    % otherwise it is an input error:
                    if ~any(strcmp(options, argin{index+1}))
                        error = 1;
                    end
                % the next element must be the value for save
                else
                    y=cell2mat(argin(index+1));
                end
            end
        end   % scans

        % ------------------
        function [y,error] = exclude(argin, options)
            error = 0;
            index = find(strcmp(argin,'exclude'));
            % (i) check if it is the last element:
            if index == length(argin)-1
                y=[];
            else
                % check if the next element is a character, if so, save = 1
                if ischar(argin(index+1))
                    y=[];
                    % check if the next element is part of options,
                    % otherwise it is an input error:
                    if ~any(strcmp(options, argin{index+1}))
                        error = 1;
                    end
                % the next element must be the value for exclude
                else
                    y=cell2mat(argin(index+1));
                end
            end
        end   % exclude

        % ------------------
        function [y,error] = t0(argin)
            error = 0;
            y = 0;
            index = find(strcmp(argin,'t0'));
            % (i) check if it is the last element:
            if index == length(argin)-1
                error = 1;
                disp('!!! ''t0'' needs to be follwed by a value! ')
            else
                % check if the next element is a character, if so, error = 1
                if ischar(argin(index+1))
                    error = 1;
                    disp('!!! ''t0'' needs to be follwed by a numerical value! ')
                else
                    y=cell2mat(argin(index+1));
                end
            end
        end   % t0

        % ------------------
        function [arg] = read(varargin, ref)

            %argin = varargin{1};  % I don't understand why I need to do that.
            argin = varargin;  % I don't understand why I need to do that.
            options = data_input_arguments.options;
            arg = [];
            arg.error = 0;

            XAS_BLs = {'7-3', '9-3'};

            % first, check if the symbol '?' apper in the arguments. If it
            % does, plot the input options:
            if any(strcmp(argin,'?'))
                arg.error = 1;
                data_input_arguments.print_input_options(argin)
            end

            % not enough input arguments
            if length(argin) < 6
                disp(' ')
                disp('!!! Not enough input arguments!')
                arg.error = 1;
                data_input_arguments.print_input_options(argin)
            end

            % all good, let's do it!
            if arg.error == 0
                if strcmp(argin{end},'XAS Rowland') == 1
                    % fixed first arguments:
                    if strcmp(argin{1},'15-2') == 0 && ~any(strcmp(argin{1}, XAS_BLs))
                        % no SSRL XAS beam line has been selected
                        disp('   !!! No SSRL XAS beam line has been chosen.')
                        disp('       Options: 15-2, 9-3, 7-3')
                        disp('       For more information add ''?'' to the argument list')
                        arg.error = 1;
                        return
                    end
                    arg.beamline = argin{1};
                    % mandatory input arguments in specific order:
                    % directory
                    % filename
                    % counter
                    % runs
                    arg.dir  = char(argin(2));
                    arg.file = char(argin(3));
                    arg.counter  = char(argin(4));
                    arg.runs     = cell2mat(argin(5));

                elseif strcmp(argin{end},'XES Rowland') == 1
                    % mandatory input arguments in specific order:
                    % directory
                    % filename
                    % counter
                    % runs

                    % if the first argument is a beam line, and delete it
                    if strcmp(argin{1},'15-2') == 0 || ~any(strcmp(argin{1}, XAS_BLs))
                        argin(1)=[];
                    end

                    arg.dir  = char(argin(1));
                    arg.file = char(argin(2));
                    arg.counter  = char(argin(3));
                    arg.runs     = cell2mat(argin(4));

                elseif strcmp(argin{end},'pump probe') == 1
                    % mandatory input arguments in specific order:
                    % ddirectory
                    % filename
                    % runs
                    arg.dir  = char(argin(1));
                    arg.file = char(argin(2));
                    arg.runs     = cell2mat(argin(3));

                end

                % check for 'spec' keyword (BL9-3 and 7-3):
                arg.create_specfile = 0;
                if any(strcmp(argin,'spec'))
                    arg.create_specfile = 1;
                end
                % check for 'exclude' keyword (BL9-3 and 7-3):
                arg.exclude = [];
                if any(strcmp(argin,'exclude'))
                    [arg.exclude, arg.error] = data_input_arguments.exclude(argin, options);
                end
                % check for 'scans' keyword (BL9-3 and 7-3):
                arg.scans = 1;
                if any(strcmp(argin,'scans'))
                    [arg.scans, arg.error] = data_input_arguments.scans(argin, options);
                end
                % check for 'save' keyword:
                arg.save = 0;
                if any(strcmp(argin,'save'))
                    [arg.save, arg.error] = data_input_arguments.save(argin, options);
                end
                % check for 'calib' keyword
                arg.calib = '';
                if any(strcmp(argin,'calib'))
                    [arg.calib, arg.error] = data_input_arguments.calib(argin, options);
                end
                % check for 'xes_fit' keyword
                if any(strcmp(argin,'xes_fit'))
                    [arg.xes_fit, arg.error] = data_input_arguments.xes_fit();
                end
                % check for 'pre-edge' keyword
                arg.pre_edge = 0;
                if any(strcmp(argin,'pre-edge'))
                    [arg.pre_edge, arg.error] = data_input_arguments.xes_fit();
                end
                % check for 'norm' keyword
                if any(strcmp(argin,'norm'))
                    [arg.norm, arg.error] = data_input_arguments.norm();
                end
                % check for 'ref' keyword
                if strcmp(arg.beamline, '15-2')
                    arg.ref = ref.ref_15_2;
                    arg.ref_standard = ref.ref_15_2;
                elseif strcmp(arg.beamline, '7-3')
                    arg.ref = ref.ref_7_3;
                    arg.ref_standard = ref.ref_15_2;
                elseif strcmp(arg.beamline, '9-3')
                    arg.ref = ref.ref_9_3;
                    arg.ref_standard = ref.ref_15_2;
                end
                if any(strcmp(argin,'ref'))
                    [arg.ref, arg.error] = data_input_arguments.ref(argin, options);
                end
                % check for 't0' keyword
                arg.t0 = 0;
                if any(strcmp(argin,'t0'))
                    [arg.t0, arg.error] = data_input_arguments.t0(argin);
                end
                % check for '2D' keyword
                arg.twoDmap = 0;
                if any(strcmp(argin,'2D'))
                    [arg.twoDmap, arg.error] = data_input_arguments.twoDmap();
                end
            end

        end
    end
end