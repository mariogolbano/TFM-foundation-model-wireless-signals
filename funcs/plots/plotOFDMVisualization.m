function plotOFDMVisualization(panel, signal, Fs, modParams)
    % Llamar a la visualización general
    plotGeneralVisualization(panel, signal, Fs);

    % Agregar mapa de subportadoras OFDM
    ax3 = uiaxes(panel, 'Position', [250, 400, 400, 200]);
    showResourceMapping(comm.OFDMModulator('FFTLength', modParams.FFTLength));
    title(ax3, 'OFDM Subcarrier Mapping');
end
