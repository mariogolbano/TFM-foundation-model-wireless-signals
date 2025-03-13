function VisualizeSignalsGUI(datasetFolder, selectedModulation, selectedSignals)
    addpath('../DatasetGeneration_GUI_MATLAB/funcs/plots');
    
    % Crear la interfaz
    fig = uifigure('Name', 'Signal Visualization', 'Position', [100, 100, 900, 600]);

    % Cargar las señales
    signalFile = fullfile(datasetFolder, [selectedModulation, '.h5']);
    [signals, ~] = loadDatasetSignals_selection(signalFile, selectedSignals);
    
    % Cargar parámetros de modulación desde el archivo .mat
    modParams = load(fullfile(datasetFolder, [selectedModulation, '.mat']));

    % Obtener la tasa de muestreo (Fs) desde el archivo .mat
    Fs = modParams.fs;  

    % Obtener el tipo de modulación
    modulationType = modParams.type;

    % Inicializar índice de la señal actual
    currentSignalIndex = 1;

    % Etiqueta para mostrar el índice de la señal
    signalLabel = uilabel(fig, 'Text', sprintf('Signal 1 of %d', length(selectedSignals)), ...
        'FontSize', 14, 'FontWeight', 'bold', 'Position', [355, 550, 200, 30]);

    % Panel para gráficos
    visualizationPanel = uipanel(fig, 'Title', 'Signal Visualization', 'Position', [50, 100, 800, 400]);

    % Botones de navegación
    btnPrev = uibutton(fig, 'Text', 'Previous Signal', 'Position', [100, 50, 150, 40], ...
        'ButtonPushedFcn', @(btn, event) previousSignal(), 'Enable', 'off');

    btnNext = uibutton(fig, 'Text', 'Next Signal', 'Position', [650, 50, 150, 40], ...
        'ButtonPushedFcn', @(btn, event) nextSignal(), 'Enable', 'on');

    btnFinish = uibutton(fig, 'Text', 'Finish', 'Position', [400, 50, 100, 40], ...
        'ButtonPushedFcn', @(btn, event) close(fig));

    % Función para actualizar los gráficos según el tipo de modulación
    function updatePlots()
        % Obtener la señal actual
        currentSignal = signals(:, currentSignalIndex);

        % Limpiar el panel
        delete(visualizationPanel.Children);

        % Llamar a la función específica según la modulación
        switch modulationType
            case 'OFDM'
                plotOFDMVisualization(visualizationPanel, currentSignal, Fs, modParams);
            case 'DSSS'
                plotDSSSVisualization(visualizationPanel, currentSignal, Fs);
            otherwise
                plotGeneralVisualization(visualizationPanel, currentSignal, Fs);
        end

        % Actualizar etiqueta de la señal
        signalLabel.Text = sprintf('Signal %d of %d', currentSignalIndex, length(selectedSignals));

        % Habilitar o deshabilitar botones según el índice
        btnPrev.Enable = 'on';
        btnNext.Enable = 'on';
        if currentSignalIndex == 1
            btnPrev.Enable = 'off';
        elseif currentSignalIndex == length(selectedSignals)
            btnNext.Enable = 'off';
        end
    end

    % Función para avanzar a la siguiente señal
    function nextSignal()
        if currentSignalIndex < length(selectedSignals)
            currentSignalIndex = currentSignalIndex + 1;
            updatePlots();
        end
    end

    % Función para retroceder a la señal anterior
    function previousSignal()
        if currentSignalIndex > 1
            currentSignalIndex = currentSignalIndex - 1;
            updatePlots();
        end
    end

    % Mostrar la primera señal
    updatePlots();
end
