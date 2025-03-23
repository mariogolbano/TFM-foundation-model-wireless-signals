function PreprocessedVideosGUI(videoPaths, numSubvideos, numFramesPerSubvideo)
    addpath(genpath('../funcs'));
    
    % Crear la interfaz principal
    fig = uifigure('Name', 'Preprocessed Videos Preview', 'Position', [100 100 1100 600]);

    % **Título informativo**
    titleLabel = uilabel(fig, ...
        'Text', sprintf('Here you can preview the actual videos to modulate: B&W and reduced quality\n(Subvideos per video: %d, Frames per subvideo: %d)', numSubvideos, numFramesPerSubvideo), ...
        'FontSize', 14, 'FontWeight', 'bold', ...
        'Position', [150 550 800 40]);  % Centrado arriba

    numVideos = length(videoPaths);
    totalSubvideos = numVideos * numSubvideos; % 🔹 Calcular el número total de subvideos
    videoBitsMatrix = struct(); % 🔹 Estructura para almacenar los bits de cada subvideo

    % **Etiqueta para mostrar el número total de subvideos**
    totalSubvideosLabel = uilabel(fig, ...
        'Text', sprintf('Total subvideos generated: %d', totalSubvideos), ...
        'FontSize', 12, 'FontWeight', 'bold', ...
        'Position', [50 520 300 30]);

    % **Tabla de Videos con Scroll Automático**
    videoTable = uitable(fig, ...
        'Position', [50 120 500 400], ...
        'ColumnName', {'Subvideo Name', 'Click on View to preview'}, ...
        'ColumnEditable', [false, false], ...
        'RowName', [], ...
        'ColumnWidth', {355, 125}, ...
        'CellSelectionCallback', @(src, event) viewVideo(src, event));

    % **Procesar los videos en subvideos y almacenar los bits**
    videoData = cell(numVideos * numSubvideos, 2);
    dataIndex = 1;

    for i = 1:numVideos
        videoPath = videoPaths(i);
        [~, videoName, ~] = fileparts(videoPath); % Nombre sin extensión
        
        % Procesar el video y generar subvideos
        [processedVideosArray, videoBits] = processVideo(videoPath, numSubvideos, numFramesPerSubvideo, 50, false);
        
        for j = 1:numSubvideos
            subVideoName = processedVideosArray(j).VideoName; % vid1_1, vid1_2, etc.
            [~, subvname, ext] = fileparts(subVideoName);
            videoData{dataIndex, 1} = char(strcat(subvname, ext));
            videoData{dataIndex, 2} = 'View';
            
            % Guardar en la estructura
            videoBitsMatrix(dataIndex).name = subVideoName;
            videoBitsMatrix(dataIndex).bits = videoBits(:,j);
            videoBitsMatrix(dataIndex).processedVideo = processedVideosArray(j);
            
            dataIndex = dataIndex + 1;
        end
    end
    videoTable.Data = videoData; % ✅ Ahora `uitable.Data` contiene nombres de subvideos.

    % **Área de Previsualización de Video**
    previewAxes = uiaxes(fig, 'Position', [620 120 410 410]);
    title(previewAxes, 'Preprocessed Video Preview');
    axis(previewAxes, 'off'); % 🔹 Ocultar los ejes iniciales

    % **Botón de Continuar**
    btnNext = uibutton(fig, 'Text', 'Continue', 'Position', [450 30 200 50], ...
        'ButtonPushedFcn', @(btn, event) selectModulations());

    % **Función para ver un subvideo preprocesado**
    function viewVideo(src, event)
        if isempty(event.Indices)
            return; % Si no se seleccionó ninguna celda, no hacer nada
        end
        row = event.Indices(1); % Fila seleccionada
        col = event.Indices(2); % Columna seleccionada
        
        if col == 2  % Si se hizo clic en "View"
            playProcessedVideoInUI(videoBitsMatrix(row).processedVideo);
        end
    end

    % **Función para reproducir un subvideo en el `uiaxes`**
    function playProcessedVideoInUI(processedVideo)
        if isempty(processedVideo.Frames)
            uialert(fig, 'No frames available in the processed video.', 'Error');
            return;
        end

        for i = 1:numel(processedVideo.Frames)
            if isvalid(previewAxes) % 🔹 Verificar si el `uiaxes` sigue activo
                imshow(processedVideo.Frames{i}, 'Parent', previewAxes);
                pause(1/processedVideo.FrameRate);
            else
                break;
            end
        end
    end

    % **Función para pasar a la siguiente pantalla (selección de modulación)**
    function selectModulations()
        close(fig);
        ModulationSelectionGUI(videoBitsMatrix); % 🔹 Pasamos la matriz de bits a la siguiente GUI
    end
end
