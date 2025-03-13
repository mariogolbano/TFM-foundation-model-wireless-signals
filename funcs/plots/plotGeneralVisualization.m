% General (Para cualquier modulación)
function plotGeneralVisualization(panel, signal, Fs)
    ax1 = uiaxes(panel, 'Position', [50, 50, 350, 300]);
    plot(ax1, (0:length(signal)-1)/Fs, real(signal));
    title(ax1, 'Time-Domain Signal');
    xlabel(ax1, 'Time (s)');
    ylabel(ax1, 'Amplitude');
    grid(ax1, 'on');

    ax2 = uiaxes(panel, 'Position', [450, 50, 350, 300]);
    spectrumAnalyzerObj = spectrumAnalyzer('SampleRate', Fs);
    spectrumAnalyzerObj(signal);
    release(spectrumAnalyzerObj);
    ax2.Children = spectrumAnalyzerObj.Axes;
end
