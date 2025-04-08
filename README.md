# XAS-XES-matlab-code
Matlab code to process the XAS and XES spectra recorded at SSRL

written by Thomas Kroll \
SLAC National Accelerator Laboratory \
Stanford Synchrotron Radiation Lightsource (SSRL)

### ===== Version 1.0 =====
2025-04-07

-- Input syntax:
   Beam line 15-2: \
     xas(beamline, directory, file, counter, [run numbers], options) \
      example: \
     xas('15-2', '2025-01_User', 'filename', 'vortDT', [1:5]) \
   Beam lines 7-3 and 9-3: \
     xas(beamline, directory, filename, counter, [run numbers], options) \
      example: \
     xas('7-3', '2025-01_User', 'filename', 'vortDT', [1:5])
 
   NOTE: beamline, directory, file, counter, [run numbers] are mandatory in exactly this order!!
 
   -- Options:
   - for beam lines 7-3 and 9-3 only:
      - 'scans', [scan numbers]: Includes the given scans for that run.
      - 'exclude', [channel numbers]: Channels that are excluded.
      - 'spec': Create a spec file from all the data files.
   - 'save', [0,1]:  The 0 or 1 argument is optional.
   - 'calib', [calib_file]:  Only for XES. If no calib_file is given, a filename of xes_calib is assumed.
   - 'pre-edge':  Only for XAS and pump-probe. Here, only the pre-edge back ground fitting is done, but not the post edge normalization.
   - 'xes_fit': Only XES. It fits the spectrum with two reference spectra. Not functioning at the moment.
   - '2D': Only for pum-probe. It indicates that 2D map (time vs energy (XAS or XES)) is done.
   - 'norm': Only for pum-probe. The full background and normalization process is done on the on and off signals.
   - 't0', value: Only for pum-probe. Value of the delay where t0 was found.
       
-- General description:
   - xas: If no other argument is given besides the folder, filename, detector and runs, the spectrum is processed without an incident energy calibration, but including a background correction and edge jump normalization. This can be changed to only background correction using the keyword 'pre-edge'
   - xes: If no other argument is given besides the folder, filename, detector and runs, the spectrum is processed without an emission energy calibration. I am working on an easy fit with reference spectra, but not done yet.
   - pump_probe: If no other argument is given besides the folder, filename and runs, the spectrum is processed without an indident energy calibration, no background or edge-jump processing, and no t0 shift. If these are desired, the keywords 'pre-edge', 'norm', or 't0' are required. 'norm' is not yet included and also 'pre-edge' needs be be included. Note that the background is determined from the average of laser on and off shots so that the same background is subtracted from both so that the difference after background subtraction remains meaningfull. The same is true for the edge-jump normalization.
   - '2D' is not done yet 
