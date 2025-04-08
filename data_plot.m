classdef data_plot

    properties
    end

    methods (Static)
        function pump_probe_xanes(d)
            coff = d.coff_norm;
            boff = d.boff_norm;
            con = d.con_norm;
            bon = d.bon_norm;

            fig = figure();
            fig.Position = [100 100 1000 700];
            % difference spectra
            subplot(3,3,1)
            plot(d.energy, d.bdiff)
            ylabel('apd B')
            title('difference')
            subplot(3,3,4)
            plot(d.energy, d.cdiff);
            ylabel('apd C')
            title('difference')
            subplot(3,3,7)
            plot(d.energy, d.bdiff + d.cdiff);
            ylabel('apd B+C')
            title('difference')
            xlabel('Energy  (eV)')

            % laser off
            subplot(3,3,2)
            plot(d.energy, boff)
            title('laser off')
            subplot(3,3,5)
            plot(d.energy, coff);
            title('laser off')
            subplot(3,3,8)
            plot(d.energy, boff + coff);
            title('laser off')
            xlabel('Energy  (eV)')

            % laser on
            subplot(3,3,3)
            plot(d.energy, bon)
            title('laser on')
            subplot(3,3,6)
            plot(d.energy, con);
            title('laser on')
            subplot(3,3,9)
            plot(d.energy, bon + con);
            title('laser on')
            xlabel('Energy  (eV)')

            % Give common xlabel, ylabel and title to your figure
            han=axes(fig,'visible','off');
            han.Title.Visible='on';
            han.XLabel.Visible='on';
            %han.YLabel.Visible='on';
            %ylabel(han,'yourYLabel');
            %xlabel(han,'Energy');
            title(han, d.specfile, ['runs ' data_save.create_run_string(d.runs)], 'Interpreter','none', 'Position', [0.5, 1.04, 0]);

        end

        function pump_probe_delay(d)

            fig = figure();
            fig.Position = [100 100 600 700];
            % difference spectra
            subplot(3,1,1)
            plot(d.delay, d.bdiff)
            ylabel('apd B')
            title('difference')
            subplot(3,1,2)
            plot(d.delay, d.cdiff);
            ylabel('apd C')
            title('difference')
            subplot(3,1,3)
            plot(d.delay, d.bdiff + d.cdiff);
            ylabel('apd B+C')
            title('difference')
            xlabel('Delay stage  (ps)')


            % Give common xlabel, ylabel and title to your figure
            han=axes(fig,'visible','off');
            han.Title.Visible='on';
            han.XLabel.Visible='on';
            %han.YLabel.Visible='on';
            %ylabel(han,'yourYLabel');
            %xlabel(han,'Energy');
            title(han, d.specfile, ['runs ' data_save.create_run_string(d.runs)], 'Interpreter','none', 'Position', [0.5, 1.04, 0]);

        end

        function pump_probe_2D(d, delay_points, mono_ref, m_bdiff, m_cdiff)
            figure()
            pcolor(delay_points, mono_ref, m_bdiff);
            shading('flat')
            title(d.specfile, ['apd B, runs ' data_save.create_run_string(d.runs)], 'Interpreter','none');
            ylabel('Energy  (eV)')
            xlabel('Time delay  (ps')

            figure()
            pcolor(delay_points, mono_ref, m_cdiff);
            shading('flat')
            title(d.specfile, ['apd C, runs ' data_save.create_run_string(d.runs)], 'Interpreter','none');
            ylabel('Energy  (eV)')
            xlabel('Time delay  (ps')

            figure()
            pcolor(delay_points, mono_ref, m_bdiff + m_cdiff);
            shading('flat')
            title(d.specfile, ['apd B+C, runs ' data_save.create_run_string(d.runs)], 'Interpreter','none');
            ylabel('Energy  (eV)')
            xlabel('Time delay  (ps')
        end



    end
end