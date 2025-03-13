% Para DSSS
function plotDSSSVisualization(panel, signal, Fs)
    % Llamar a la visualización general
    plotGeneralVisualization(panel, signal, Fs);

    % DSSS no tiene constelación, solo espectro
    title(ax3, 'DSSS Spectrum');
end
