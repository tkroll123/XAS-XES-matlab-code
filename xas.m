function xas(varargin)
    %%% methods to do the energy calibration:
    % - fip         use the first inflection point of a foil
    % - glitch      use the glitch in I0, either fit a (double) peak to it or match to reference
    % - constant    constand energy shift
    % - none        do nothing

    % these are not yet fully integrated:
    % - foil        match the whole foil spectrum to reference
    % - foil_peak   use the pre-edge peak of a foil

    %%% create a data structure for these values:
    calib_mono.calibrate_mono_method = 'fip';
    
    %%% define if the calibration shall be plotted
    calib_mono.plot = 'plot no';       % select 'plot' or something else

    % constant shift:
    calib_mono.rigid_shift =            -0.86;

    %%% !!!!
    %%% Values specific for each edge. Might need to edit
    %%% data_read.XAS_edge

    %%% first inflection point:

    % method to smooth the data to get better first derivative:
    calib_mono.fip_smooth_data =                    true;   % options: true and false, switches it on and off
    calib_mono.fip_smooth_method =                  'gaussian';  % options: gaussian, movmean, Savitzky-Golay
    calib_mono.fip_smooth_window =                  7;          % for gaussian and movmean
    calib_mono.fip_smooth_SG_order =                6;
    calib_mono.fip_smooth_SG_frame_length =         15;

    %%% energies for the foil first inflection points:
    calib_mono.fip_values.Cr =                      5989.2;
    calib_mono.fip_values.Mn =                      6539.0;
    calib_mono.fip_values.Fe =                      7111.2;
    calib_mono.fip_values.Co =                      7708.9;
    calib_mono.fip_values.Ni =                      8332.8;
    calib_mono.fip_values.Cu =                      8980.3;%8978.9;  % Leah: 8980.3 eV
    calib_mono.fip_values.Zn =                      9658.6;

    %%% glitch:
    %%% energies for the I0 glitches:
    calib_mono.glitch_values.Cr =                   5991.9;
    calib_mono.glitch_values.Mn =                   6539.0;
    calib_mono.glitch_values.Fe =                   7100.8;  %7106.47; %7100.80;
    calib_mono.glitch_values.Co =                   7762.4; %7708.9;
    calib_mono.glitch_values.Ni =                   [];
    calib_mono.glitch_values.Cu =                   8985.0;  % 15-2 value
     %calib_mono.glitch_values.Cu =                   8987.7;  % 6-2 value
    calib_mono.glitch_values.Zn =                   [];

    %%% using the whole foil spectrum. Maybe included later.
    %calib_mono.calibrate_mono_foil_reference  =     ["xas_calib_Fe_foil.mat", "asdf"];
    %calib_mono.calibrate_mono_foil_peak_reference = 8980.95;
    

    %%% include normalization of the spectrum:
    norm.normalize =                                true;   % ( options: true, false)

    %%% values for background fit
    % subtract a constant background:
    norm.bkg_constant =                             true;   % ( options: true, false)

    % energy up to where the data shall be fit for background:
    norm.bkg_treshold_energy.Cr =                   5987.7;
    norm.bkg_treshold_energy.Mn =                   6536.0;
    norm.bkg_treshold_energy.Fe =                   7050;
    norm.bkg_treshold_energy.Co =                   7701;
    norm.bkg_treshold_energy.Ni =                   0;
    norm.bkg_treshold_energy.Cu =                   8974.2;
    norm.bkg_treshold_energy.Zn =                   8974.2;
    norm.bkg_treshold_energy.Se =                   12649.0;
    norm.bkg_treshold_energy.GdL3 =                 7228.0;

    % energy range used for the background below norm.bkg_treshold_energy
    norm.bkg_delta_energy =                         -100;

    %%% values where to start to do the edge-jump fit
    norm.edge_jump_start.Cr =                       6182.0;
    norm.edge_jump_start.Mn =                       6744.0;
    norm.edge_jump_start.Fe =                       7300.0;
    norm.edge_jump_start.Co =                       7920.0;
    norm.edge_jump_start.Ni =                       0;
    norm.edge_jump_start.Cu =                       9180.0;
    norm.edge_jump_start.Se =                       12713.0;
    norm.edge_jump_start.GdL3 =                     7350.0;

    % energy range used for the edge jump above norm.edge_jump_start
    norm.edge_jump_delta_energy =                   0;

    %%% correct for Kb signal in Ka HERFD
    norm.correct_for_glitch = false;
    

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Standard channels for reference foil data:

    ref.ref_15_2 = 'I2';
    ref.ref_7_3  = 'I2';
    ref.ref_9_3  = 'Spare1';



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% read the input arguments:
    % add a keyword to the input arguments 
    varargin = [varargin, 'XAS Rowland'];
    % directory, filename, counter, runs have to be given in that order
    % calib, save and xes_fit are optional and can be in any order
    arg = data_input_arguments.read(varargin, ref);
    if arg.error == 1
        return
    end
    

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% option to print various motor values and/or select/exclude files
    %%% based on these values:

    % print the sample position:
    arg.print_sample_position = false;

    % exclude those runs that appear at the given sample position:
    %   to unselect motor set value lower than -9999 or delete/comment out
    %   that line.
    %   for two or more values, write them as an array.
    %arg.exclude_Sx = [];
    %arg.exclude_Sy = [];
    %arg.exclude_Sz = [33.0, 33.3];


    
    
    
    

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % List the XAS beam lines using webXAS:  (also in data_input_arguments.m)
    arg.XAS_BLs = {'7-3', '9-3'};


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Define the home directory:
    if strcmp(arg.beamline,'15-2')
        homeDir = ['/Users/tkroll/Dropbox/uni_dropbox/SSRL/data/' arg.dir '/'];
    elseif any(strcmp(arg.beamline,arg.XAS_BLs))
        homeDir = ['/Users/tkroll/Dropbox/uni_dropbox/SSRL/data/BL' arg.beamline '/' arg.dir '/data/'];
    
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Directory where the data gets saved:

    saveDir = [homeDir 'average'];

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    %%% Once done, no code below should be needed to be touched. Not done
    %%% yet.
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %[mono_ref, spectrum_norm, spectrum_ph, i0_save, i1_save, i2_save] = ...
        data_xas.xas(homeDir, saveDir, arg, calib_mono, norm);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end