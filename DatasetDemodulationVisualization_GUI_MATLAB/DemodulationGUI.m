function DemodulationGUI(datasetFolder, selectedModulation, selectedSignals)
    addpath('../funcs/demods/')
    % Crear la ventana principal
    fig = uifigure('Name', 'Demodulation and Visualization', 'Position', [100, 100, 800, 600]);

    % Ruta de los archivos HDF5
    signalFile = fullfile(datasetFolder, [selectedModulation, '.h5']);  % Señales moduladas
    bitsFile = fullfile(datasetFolder, ['bits_', selectedModulation, '.h5']);  % Bits originales

    % Cargar las señales y los atributos del dataset
    [signals, datasetAttributes] = loadDatasetSignals_selection(signalFile, selectedSignals);
    [originalBits, ~] = loadDatasetSignals_selection(bitsFile, selectedSignals);
    
    % Obtener el tamaño de los frames
    frameSize = datasetAttributes.FrameSize;

    % Variables de control
    currentSignalIndex = 1;
    demodulatedBits = []; % Se almacenarán los bits demodulados aquí

    % Etiqueta con la señal actual
    signalLabel = uilabel(fig, 'Text', sprintf('Signal 1 of %d', length(selectedSignals)), ...
        'FontSize', 14, 'FontWeight', 'bold', 'Position', [355, 550, 200, 30]);

    % Etiqueta para BER
    berLabel = uilabel(fig, 'Text', 'BER: --', 'FontSize', 12, ...
        'Position', [360, 450, 200, 30]);

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
    originalVideoAxes = uiaxes(videoPanel, 'Position', [55, 30, 300, 300]);
    demodulatedVideoAxes = uiaxes(videoPanel, 'Position', [360, 30, 300, 300]);

    % 🔹 **Eliminar los ejes de los gráficos**
    disableAxes(originalVideoAxes);
    disableAxes(demodulatedVideoAxes);

    % Etiquetas debajo de los videos
    uilabel(videoPanel, 'Text', 'Original Video', 'FontSize', 15, 'Position', [145, 25, 100, 30]);
    uilabel(videoPanel, 'Text', 'Demodulated Video', 'FontSize', 15, 'Position', [435, 25, 150, 20]);

    % Iniciar la demodulación de la primera señal
    processCurrentSignal();

    % Función para procesar la señal actual
    function processCurrentSignal()
        % Obtener la señal actual
        modParams = load(fullfile(datasetFolder, [selectedModulation, '.mat']));  
        demodulatedBits = demodulateSignal(signals(:, currentSignalIndex), modParams);

        % Asegurar que los bits tengan la misma longitud
        minLength = min(length(originalBits(:, currentSignalIndex)), length(demodulatedBits));
        demodulatedBits = demodulatedBits(1:minLength);
        originalBits(:, currentSignalIndex) = originalBits(1:minLength, currentSignalIndex);

        % Calcular el BER
        ber = sum(originalBits(:, currentSignalIndex) ~= demodulatedBits) / minLength;

        % Actualizar BER
        berLabel.Text = sprintf('BER: %.4f', ber);

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
        % Obtener los frames correspondientes de los bits originales y demodulados
        originalFrames = bitsToVideoFrames(originalBits(:, currentSignalIndex), frameSize);
        demodulatedFrames = bitsToVideoFrames(demodulatedBits, frameSize);

        for i = 1:numel(originalFrames)
            imshow(originalFrames{i}, 'Parent', originalVideoAxes);
            imshow(demodulatedFrames{i}, 'Parent', demodulatedVideoAxes);
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
        DemodulationOrVisualizationGUI(datasetFolder, selectedModulation, selectedSignals); % Volver a la selección
    end

    % Función para deshabilitar los ejes de los gráficos
    function disableAxes(ax)
        ax.XColor = 'none'; % Ocultar ejes X
        ax.YColor = 'none'; % Ocultar ejes Y
        ax.Toolbar.Visible = 'off'; % Ocultar barra de herramientas
    end

end
