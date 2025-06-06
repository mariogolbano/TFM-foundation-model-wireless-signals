function DemodulateDatasets()
    % Pantalla de entrada principal para seleccionar el flujo de visualización
    addpath(genpath('../funcs'));

    fig = uifigure('Name', 'Select Visualization Type', 'Position', [250, 150, 550, 350]);

    % Título
    uilabel(fig, ...
        'Text', 'How do you want to visualize the signals?', ...
        'FontSize', 18, 'FontWeight', 'bold', ...
        'Position', [95, 270, 400, 40]);

    % Botón para visualización simple
    uibutton(fig, ...
        'Text', ['Demodulated Signal vs Original Bits' newline '(Simple)'], ...
        'FontSize', 16, ...
        'Position', [110, 165, 300, 70], ...
        'ButtonPushedFcn', @(btn, event) openSimpleVisualization());

    % Botón para visualización con inferencia
    uibutton(fig, ...
        'Text', ['Inference Signal vs Interference' newline 'vs Original Bits' newline '(Inference)'], ...
        'FontSize', 16, ...
        'Position', [110, 60, 300, 80], ...
        'ButtonPushedFcn', @(btn, event) openInferenceVisualization());

    % Función para ir a visualización simple
    function openSimpleVisualization()
        addpath("simple_vis\");
        close(fig);
        DatasetSelection(); % Redirige al flujo simple
    end

    % Función para ir a visualización por inferencia
    function openInferenceVisualization()
        addpath("inference_vis\");
        close(fig);
        FolderSelection(); % Redirige al flujo de inferencia
    end
end
