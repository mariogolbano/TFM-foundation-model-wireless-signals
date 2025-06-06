function FolderSelection()
    
    % Crear la ventana principal
    fig = uifigure('Name', 'Select Datasets Folders', 'Position', [300, 300, 400, 250]);
    
    % Título
    uilabel(fig, ...
        'Text', ['Select the folders:' newline '- Interfence Signal Dataset' newline '- Inferred Signal (clean) Dataset'], ...
        'FontSize', 16, 'FontWeight', 'bold', ...
        'Position', [30, 150, 300, 90]);

    % Botón para visualización simple
    uibutton(fig, ...
        'Text', 'Select Folders', ...
        'Position', [155, 50, 100, 50], ...
        'ButtonPushedFcn', @(btn, event) FolderSelection2());

    function FolderSelection2()
        close(fig);
        % Crear la ventana principal
        fig = uifigure('Name', 'Select Datasets Folders', 'Position', [200, 150, 600, 500]);
    
        % Seleccionar la carpeta para la señal interferente
        interferenceFolder = uigetdir(fullfile(pwd, '..', 'datasets'), 'Select Interference Signal Dataset');
        if interferenceFolder == 0
            uialert(fig, 'No folder selected for interference signal dataset.', 'Error');
            return;
        end
    
        % Seleccionar la carpeta para la señal inferida
        inferredFolder = uigetdir(fullfile(pwd, '..', 'datasets'), 'Select Inferred Signal Dataset');
        if inferredFolder == 0
            uialert(fig, 'No folder selected for inferred signal dataset.', 'Error');
            return;
        end
    
        % Obtener archivos JSON en ambas carpetas
        interferenceJSONFiles = dir(fullfile(interferenceFolder, '*.json'));
        inferredJSONFiles = dir(fullfile(inferredFolder, '*.json'));
    
        if length(interferenceJSONFiles) ~= length(inferredJSONFiles)
            uialert(fig, 'Folders do not match. Please select the correct folders.', 'Error');
            interferenceFolder = ''; % Resetear las carpetas seleccionadas
            inferredFolder = ''; 
            return;
        end
    
        % Extraer los nombres de los archivos JSON
        inferredJSONNames = {interferenceJSONFiles.name};
        interferenceJSONNames = {inferredJSONFiles.name};
    
        % Asegurarse de que los archivos JSON coincidan en nombre
        if ~isequal(sort(interferenceJSONNames), sort(inferredJSONNames))
            uialert(fig, 'Folders do not match. Please select the correct folders.', 'Error');
            interferenceFolder = ''; % Resetear las carpetas seleccionadas
            inferredFolder = ''; 
            return;
        end
    
        % Comparar los archivos H5 para cada JSON
        for i = 1:length(interferenceJSONFiles)
            % Obtener el nombre del archivo JSON
            jsonFileName = interferenceJSONFiles(i).name;
            baseName = extractBefore(jsonFileName, '.json'); % Nombre base del JSON (ej. OFDM_1)
    
            % Generar el nombre del archivo H5 correspondiente
            interferenceH5File = fullfile(interferenceFolder, ['bits_' baseName '.h5']);
            inferredH5File = fullfile(inferredFolder, ['bits_' baseName '.h5']);
    
            % Verificar que ambos archivos H5 existan
            if ~isfile(interferenceH5File) || ~isfile(inferredH5File)
                uialert(fig, 'Folders do not match. Please select the correct folders.', 'Error');
                interferenceFolder = ''; % Resetear las carpetas seleccionadas
                inferredFolder = ''; 
                return;
            end
    
            % Leer los archivos H5 y comparar su contenido
            interferenceData = h5read(interferenceH5File, '/dataset');
            inferredData = h5read(inferredH5File, '/dataset');
    
            % Comparar los datos (suponiendo que ambos archivos H5 tienen la misma estructura)
            if ~isequal(interferenceData, inferredData)
                uialert(fig, 'Folders do not match. Please select the correct folders.', 'Error');
                return;
            end
        end
    
        % Si todo es correcto, continuar
        uialert(fig, 'Datasets are valid. Proceeding to next step.', 'Success');
    
        % Pasar a la siguiente pantalla
        close(fig);
        DatasetSelection(interferenceFolder, inferredFolder); % Pasar a la siguiente pantalla para comparar señales
    end
end
