function DemodulationOrVisualizationGUI(datasetFolder, selectedModulation, selectedSignals)
    % Crear la ventana principal
    fig = uifigure('Name', 'Demodulation or Visualization', 'Position', [100, 100, 600, 400]);

    % Etiqueta con la modulación seleccionada
    uilabel(fig, 'Text', sprintf('Selected Modulation: %s', selectedModulation), ...
        'FontSize', 14, 'FontWeight', 'bold', 'Position', [180, 320, 300, 30]);

    % Botón para demodular y visualizar
    btnDemodulate = uibutton(fig, 'Text', 'Demodulate and Visualize', 'Position', [150, 220, 300, 50], ...
        'ButtonPushedFcn', @(btn, event) startDemodulation());

    % Botón para solo visualizar señales
    btnVisualize = uibutton(fig, 'Text', 'Visualize Signals', 'Position', [150, 150, 300, 50], ...
        'ButtonPushedFcn', @(btn, event) startVisualization());

    % Botón para volver atrás (regresa a `SelectSignalsGUI`)
    btnBack = uibutton(fig, 'Text', 'Back', 'Position', [150, 80, 140, 50], ...
        'ButtonPushedFcn', @(btn, event) returnToSignalSelection());

    % Botón para cerrar toda la aplicación
    btnFinish = uibutton(fig, 'Text', 'Finish', 'Position', [310, 80, 140, 50], ...
        'ButtonPushedFcn', @(btn, event) closeAllWindows());

    % Función para iniciar la demodulación y visualización
    function startDemodulation()
        close(fig);  % Cerrar esta GUI
        DemodulationGUI(datasetFolder, selectedModulation, selectedSignals);
    end

    % Función para solo visualizar las señales sin demodular
    function startVisualization()
        close(fig);  % Cerrar esta GUI
        VisualizeSignalsGUI(datasetFolder, selectedModulation, selectedSignals);
    end

    % Función para volver a `SelectSignalsGUI`
    function returnToSignalSelection()
        close(fig);  % Cerrar esta GUI
        SelectSignalsGUI(datasetFolder, selectedModulation);
    end

    % Función para cerrar toda la aplicación
    function closeAllWindows()
        delete(findall(0, 'Type', 'figure')); % Cerrar todas las figuras abiertas
    end
end
