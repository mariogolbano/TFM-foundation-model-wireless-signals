function VideoSelectionGUI
    % Crear la interfaz principal
    fig = uifigure('Name', 'Select Videos to Modulate', 'Position', [100 100 1100 650]);

    % Seleccionar carpeta de videos
    videoFolder = uigetdir(pwd, 'Select Video Folder');
    videoFiles = dir(fullfile(videoFolder, '*.mp4')); % Puedes agregar más formatos

    numVideos = length(videoFiles);
    videoPaths = strings(numVideos, 1);
    framesAvailable = zeros(numVideos, 1); % Almacenar frames disponibles por video

    for i = 1:numVideos
        videoPaths(i) = fullfile(videoFolder, videoFiles(i).name);
        v = VideoReader(videoPaths(i));
        framesAvailable(i) = floor(v.Duration * v.FrameRate); % Calcular frames disponibles
    end

    % **Tabla de Videos con Scroll Automático**
    videoTable = uitable(fig, ...
        'Position', [50 180 500 350], ...
        'ColumnName', {'Select', 'Video Name', 'Click on View to preview'}, ...
        'ColumnEditable', [true, false, false], ...
        'RowName', [], ...
        'ColumnWidth', {80, 255, 165}, ...
        'CellSelectionCallback', @(src, event) viewVideo(src, event), ...
        'CellEditCallback', @(src, event) updateSelectedCount());

    % Datos de la tabla
    videoData = cell(numVideos, 3);
    for i = 1:numVideos
        videoData{i, 1} = true;  % Checkbox por defecto activado
        videoData{i, 2} = videoFiles(i).name; % Nombre del video
        videoData{i, 3} = 'View'; % Botón de vista previa
    end
    videoTable.Data = videoData;

    % **Botones para Seleccionar/Deseleccionar Todos**
    btnSelectAll = uibutton(fig, 'Text', 'Select All', ...
        'Position', [130 540 155 40], ...
        'ButtonPushedFcn', @(btn, event) selectAllVideos(true));

    btnDeselectAll = uibutton(fig, 'Text', 'Unselect All', ...
        'Position', [330 540 155 40], ...
        'ButtonPushedFcn', @(btn, event) selectAllVideos(false));

    % **Contador de videos seleccionados**
    selectedCountLabel = uilabel(fig, ...
        'Text', sprintf('Videos selected: %d', numVideos), ...
        'FontSize', 12, ...
        'Position', [50 150 300 30]);

    % **Área de Previsualización de Video**
    previewAxes = uiaxes(fig, 'Position', [620 180 410 350]);
    title(previewAxes, 'Video Preview');
    axis(previewAxes, 'off');

    % **Sección para Configurar Subvideos**
    uilabel(fig, 'Text', 'Number of subvideos per video:', 'Position', [50 120 200 25]);
    numSubvideosField = uieditfield(fig, 'numeric', 'Position', [260 120 100 25], 'Value', 5, 'Limits', [1 Inf]);

    uilabel(fig, 'Text', 'Number of frames per subvideo:', 'Position', [50 90 200 25]);
    numFramesField = uieditfield(fig, 'numeric', 'Position', [260 90 100 25], 'Value', 6, 'Limits', [1 Inf]);

    % **Advertencias**
    warningLabel = uilabel(fig, ...
        'Text', 'More than 6 frames may generate large waveforms.', ...
        'FontColor', [1, 0, 0], ...
        'Position', [380 90 400 25]);

    % **Etiqueta de frames disponibles (mínimo de los videos seleccionados)**
    minFramesAvailable = min(framesAvailable); % Inicialmente es el mínimo de todos los videos
    totalFramesLabel = uilabel(fig, ...
        'Text', sprintf('Max total frames available: %d', minFramesAvailable), ...
        'FontWeight', 'bold', ...
        'Position', [50 60 400 25]);

    % **Botón de Continuar**
    btnNext = uibutton(fig, 'Text', 'Continue', 'Position', [450 30 200 50], ...
        'ButtonPushedFcn', @(btn, event) processSelectedVideos());

    % **Función para ver un video cuando se haga clic en "View"**
    function viewVideo(src, event)
        if isempty(event.Indices)
            return;
        end
        row = event.Indices(1);
        col = event.Indices(2);
        
        if col == 3
            videoPath = videoPaths(row);
            playVideoInUI(videoPath);
        end
    end

    % **Función para reproducir un video en el `uiaxes`**
    function playVideoInUI(videoPath)
        videoObj = VideoReader(videoPath);
        while hasFrame(videoObj)
            frame = readFrame(videoObj);
            imshow(frame, 'Parent', previewAxes);
            pause(1/videoObj.FrameRate);
        end
    end

    % **Función para seleccionar/deseleccionar todos los videos**
    function selectAllVideos(selectAll)
        for j = 1:numVideos
            videoTable.Data{j, 1} = selectAll;
        end
        updateSelectedCount();
    end

    % **Función para actualizar el contador de videos seleccionados y los frames disponibles**
    function updateSelectedCount()
        selectedIndices = find([videoTable.Data{:, 1}]); % Índices de videos seleccionados
        selectedCount = length(selectedIndices);
        selectedCountLabel.Text = sprintf('Videos selected: %d', selectedCount);

        % Actualizar la cantidad mínima de frames disponibles entre los seleccionados
        if isempty(selectedIndices)
            minFramesAvailable = 0;
        else
            minFramesAvailable = min(framesAvailable(selectedIndices));
        end
        totalFramesLabel.Text = sprintf('Max total frames available: %d', minFramesAvailable);
    end

    % **Función para procesar los videos seleccionados**
    function processSelectedVideos()
        selectedIndices = find([videoTable.Data{:, 1}]);
        selectedVideos = videoPaths(selectedIndices);
        numSubvideos = numSubvideosField.Value;
        numFramesPerSubvideo = numFramesField.Value;
        
        % Verificar si la cantidad total de frames solicitada es válida
        totalFramesNeeded = numSubvideos * numFramesPerSubvideo;
        if totalFramesNeeded > minFramesAvailable
            uialert(fig, sprintf('Error: Requested frames (%d) exceed available frames (%d).', totalFramesNeeded, minFramesAvailable), 'Error');
            return;
        end

        if isempty(selectedVideos)
            uialert(fig, 'No video was selected.', 'Error');
        else
            close(fig);
            PreprocessedVideosGUI(selectedVideos, numSubvideos, numFramesPerSubvideo); % Pasa a la siguiente pantalla con los nuevos parámetros
        end
    end
end
