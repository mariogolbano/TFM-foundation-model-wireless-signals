function DemodulationGUI(interferenceFolder, inferredFolder, selectedModulation, selectedSignals)

    % Crear la ventana principal
    fig = uifigure('Name', 'Demodulation and Visualization', 'Position', [100, 100, 800, 600]);

    % Ruta de los archivos HDF5 para las tres señales
    bitsFile = fullfile(interferenceFolder, ['bits_' selectedModulation, '.h5']);  % Bits originales
    interferenceFile = fullfile(interferenceFolder, [selectedModulation, '.h5']);  % Señales interferidas
    inferenceFile = fullfile(inferredFolder, [selectedModulation, '.h5']);  % Señales inferidas

    % Cargar las señales y los atributos del dataset
    [originalBits, ~] = loadDatasetSignals_selection(bitsFile, selectedSignals);
    [interference, datasetAttributes] = loadDatasetSignals_selection(interferenceFile, selectedSignals);
    [inference, ~] = loadDatasetSignals_selection(inferenceFile, selectedSignals);

    % Obtener el tamaño de los frames
    frameSize = datasetAttributes.FrameSize;

    % Variables de control
    currentSignalIndex = 1;
    demodulatedBits_interference = []; % Se almacenarán los bits demodulados aquí
    demodulatedBits_inference = []; % Se almacenarán los bits demodulados aquí

    % Etiqueta con la señal actual
    signalLabel = uilabel(fig, 'Text', sprintf('Signal 1 of %d', length(selectedSignals)), ...
        'FontSize', 14, 'FontWeight', 'bold', 'Position', [355, 550, 200, 30]);

    % Etiquetas para BER
    berInterferenceLabel = uilabel(fig, 'Text', 'BER: --', 'FontSize', 12, ...
        'Position', [330, 400, 200, 30]);
    berInferenceLabel = uilabel(fig, 'Text', 'BER: --', 'FontSize', 12, ...
        'Position', [530, 400, 200, 30]);

    % Botón de Play
    btnPlay = uibutton(fig, 'Text', 'Play', 'Position', [350, 500, 100, 40], ...
        'ButtonPushedFcn', @(btn, event) playVideos());

    % Botón Next Video
    btnNext = uibutton(fig, 'Text', 'Next Video', 'Position', [600, 525, 100, 40], ...
        'ButtonPushedFcn', @(btn, event) nextVideo(), 'Enable', 'off');

    % Botón Finalizar (Volver a `DemodulationOrVisualizationGUI`)
    btnFinish = uibutton(fig, 'Text', 'Finish', 'Position', [600, 475, 100, 40], ...
        'ButtonPushedFcn', @(btn, event) returnToPreviousGUI(), 'Enable', 'off');

    % Panel de visualización de videos
    videoPanel = uipanel(fig, 'Title', 'Video Comparison', 'Position', [50, 50, 700, 350]);

    % Axes para mostrar los videos
    originalVideoAxes = uiaxes(videoPanel, 'Position', [50, 25, 200, 300]);
    interferenceVideoAxes = uiaxes(videoPanel, 'Position', [250, 25, 200, 300]);
    inferenceVideoAxes = uiaxes(videoPanel, 'Position', [450, 25, 200, 300]);

    % 🔹 **Eliminar los ejes de los gráficos**
    disableAxes(originalVideoAxes);
    disableAxes(interferenceVideoAxes);
    disableAxes(inferenceVideoAxes);

    % Etiquetas debajo de los videos
    uilabel(videoPanel, 'Text', 'Original Video', 'FontSize', 15, 'Position', [95, 25, 100, 30]);
    uilabel(videoPanel, 'Text', 'Interference Video', 'FontSize', 15, 'Position', [295, 25, 150, 20]);
    uilabel(videoPanel, 'Text', 'Inference Video', 'FontSize', 15, 'Position', [495, 25, 150, 20]);

    % Iniciar la demodulación de la primera señal
    processCurrentSignal();

    % Función para procesar la señal actual
    function processCurrentSignal()
        % Obtener la señal actual
        modParams = load(fullfile(interferenceFolder, [selectedModulation, '.mat']));  
        demodulatedBits_interference = demodulateSignal(interference(:, currentSignalIndex), modParams);
        demodulatedBits_inference = demodulateSignal(inference(:, currentSignalIndex), modParams);

        % Asegurar que los bits tengan la misma longitud
        minLength = min(length(originalBits(:, currentSignalIndex)), min(length(demodulatedBits_interference), length(demodulatedBits_inference)));
        demodulatedBits_interference = demodulatedBits_interference(1:minLength);
        demodulatedBits_inference = demodulatedBits_inference(1:minLength);

        originalBits(:, currentSignalIndex) = originalBits(1:minLength, currentSignalIndex);

        % Calcular el BER para Interference
        berInterference = sum(originalBits(:, currentSignalIndex) ~= demodulatedBits_interference) / minLength;

        % Calcular el BER para Inference
        berInference = sum(originalBits(:, currentSignalIndex) ~= demodulatedBits_inference) / minLength;

        % Actualizar BER
        berInterferenceLabel.Text = sprintf('BER (Interference): %.4f', berInterference);
        berInferenceLabel.Text = sprintf('BER (Inference): %.4f', berInference);

        % Mostrar el número de la señal actual
        signalLabel.Text = sprintf('Signal %d of %d', currentSignalIndex, length(selectedSignals));

        % Habilitar Next Video si hay más señales
        if currentSignalIndex < length(selectedSignals)
            btnNext.Enable = 'on';
        else
            btnNext.Enable = 'off';
            btnFinish.Enable = 'on';
        end
    end

    % Función para reproducir los videos
    function playVideos()
        % Obtener los frames correspondientes de los bits originales, interference y inference
        originalFrames = bitsToVideoFrames(originalBits(:, currentSignalIndex), frameSize);
        interferenceFrames = bitsToVideoFrames(demodulatedBits_interference, frameSize);
        inferenceFrames = bitsToVideoFrames(demodulatedBits_inference, frameSize);

        for i = 1:numel(originalFrames)
            imshow(originalFrames{i}, 'Parent', originalVideoAxes);
            imshow(interferenceFrames{i}, 'Parent', interferenceVideoAxes);
            imshow(inferenceFrames{i}, 'Parent', inferenceVideoAxes);
            pause(0.1);
        end
    end

    % Función para avanzar al siguiente video
    function nextVideo()
        if currentSignalIndex < length(selectedSignals)
            currentSignalIndex = currentSignalIndex + 1;
            processCurrentSignal();
        end
    end

    % Función para volver a `DemodulationOrVisualizationGUI`
    function returnToPreviousGUI()
        close(fig); % Cerrar la ventana actual
        SelectSignalsGUI(interferenceFolder, inferredFolder, selectedModulation);

    end

    % Función para deshabilitar los ejes de los gráficos
    function disableAxes(ax)
        ax.XColor = 'none'; % Ocultar ejes X
        ax.YColor = 'none'; % Ocultar ejes Y
        ax.Toolbar.Visible = 'off'; % Ocultar barra de herramientas
    end

end
