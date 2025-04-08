function xes(varargin)
%function xes(directory, filename, counter, runs)
    
    clear arg
    % get the input values
    % add a keyword to the input arguments 
    varargin = [varargin, 'XES Rowland'];
    % directory, filename, counter, runs have to be given in that order
    % calib, save and xes_fit are optional and can be in any order
    %[directory, filename, counter, runs, calib, save, pre_edge] = interpret_input_arguments(varargin);
    arg = data_input_arguments.read(varargin);
    if arg.error == 1
        return
    end



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % values for background subtraction
    % high energy side, number of points from max energy
    norm.bkg_data_points_high =                 25;
    % high energy side background region width in points:
    norm.bkg_data_points_high_width =           99;

    % low energy side, number of points from min energy
    norm.bkg_data_points_low =                 35;
    % low energy side background region width in points:
    norm.bkg_data_points_low_width =           20;



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Define the home directory:
    homeDir = ['/Users/tkroll/Dropbox/uni_dropbox/SSRL/data/' arg.dir '/'];

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Directory where the data gets saved:

    saveDir = [homeDir 'average'];

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    %%% Once done, no code below should be needed to be touched. Not done
    %%% yet.
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    data_xes.xes_rowland(homeDir, saveDir, arg, norm);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end