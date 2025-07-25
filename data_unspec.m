classdef data_unspec
    % define the keyword options:
    properties (Constant)
    end

    % local fundtions here:
    methods (Static)

        % ---- xes prosessing for Rowland geometry ------------------------
        function unspec(specfile, mlxDir)
        
            unspec_Version = 'chopSPECfile';
            if strcmp(unspec_Version, 'ESRF')
                % get current directory
                homeDir = pwd;
                dir = pwd;
            
                % change to mlx directory to unspec the 
                %mlxDir = '/Users/tkroll/Documents/uni/SSRL/projects/mixing/matlab_scripts/test';
                cd(mlxDir);
                dir = pwd;
                
                % check if specfile_dir exists and create specfile_dir
                specfile_dir = [specfile '_dir'];
                if ~exist(specfile_dir, 'dir')
                   mkdir(specfile_dir);
                end
                
                % copy specfile into specfile_dir
                copyfile(specfile, specfile_dir)
                
                % change into specfile_dir
                cd(specfile_dir);
                dir = pwd;
                
                % run unspec
                % format: unspec.mac specfile specfile_ dat -3
                unspec_command = '/Users/tkroll/Dropbox/uni_dropbox/SSRL/scripts/unspec-xes_calib/unspec_ESRF/unspec.mac';
                command = [unspec_command ' ' specfile ' ' specfile '_ dat -3' ];
            
                [status,cmdout] = system(command);
        
            %    % change back to homeDir
            %    cd(homeDir);
            %    dir = pwd;
        
            else    % use my python written chopSPECfile
                unspec_command = '/Users/tkroll/Dropbox/uni_dropbox/SSRL/scripts/unspec-xes_calib/chopSPECfile.py';
                command = [unspec_command ' ' specfile];
                [status,cmdout] = system(command);
            end
            
        end

        % ---- xes prosessing for Rowland geometry ------------------------
        function unspec_matlab(specfile, mlxDir)

            % unspec the data from matlab:
            

        end
    end
end
