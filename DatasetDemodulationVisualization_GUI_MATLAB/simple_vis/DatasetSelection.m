function DatasetSelection(datasetFolder)
    % Crear la ventana principal
    fig = uifigure('Name', 'Load Dataset', 'Position', [100, 100, 600, 500]);
    

    if nargin < 1

        % Seleccionar la carpeta del dataset
        datasetFolder = uigetdir(fullfile(pwd, '..', 'datasets'), 'Select Dataset Folder');
        if datasetFolder == 0
            uialert(fig, 'No folder selected.', 'Error');
            return;
        end
    end

    % Obtener lista de modulaciones disponibles
    datasetFiles = dir(fullfile(datasetFolder, '*.mat'));
    modulationList = erase({datasetFiles.name}, '.mat'); % Extraer solo los nombres
    
    % Agregar el valor por defecto '---'
    modulationList = ['---', modulationList];

    % Lista de modulaciones disponibles
    uilabel(fig, 'Text', 'Select a modulation:', 'Position', [50, 420, 200, 25]);
    modulationDropdown = uidropdown(fig, ...
        'Items', modulationList, ...
        'Position', [200, 420, 250, 25], ...
        'Value', '---', ... % 🔹 Por defecto, muestra '---'
        'ValueChangedFcn', @(src, event) loadModulationInfo());

    % Panel para la información de la modulación
    infoPanel = uipanel(fig, 'Title', 'Modulation Info', 'Position', [50, 150, 500, 250]);

    % Tabla dentro del panel, centrada
    infoTable = uitable(infoPanel, ...
        'Position', [0, 0, 500, 230], ...  % 🔹 Centramos la tabla
        'ColumnName', {'Parameter', 'Value'}, ...
        'RowName', []);  % 🔹 Quitamos la numeración de la izquierda

    % Botón para continuar
    btnContinue = uibutton(fig, 'Text', 'Continue', 'Position', [200, 50, 200, 50], ...
        'ButtonPushedFcn', @(btn, event) continueToSignalSelection());

    % Cargar información del archivo .mat seleccionado
    function loadModulationInfo()
        selectedModulation = modulationDropdown.Value;

        % Evitar que se cargue si aún está en '---'
        if strcmp(selectedModulation, '---')
            infoTable.Data = {}; % Limpiar la tabla si vuelve a '---'
            return;
        end

        matFile = fullfile(datasetFolder, [selectedModulation, '.mat']);

        if isfile(matFile)
            matData = load(matFile);
            fieldNames = fieldnames(matData);
            fieldValues = struct2cell(matData);

            % Convertir valores a cadenas para mostrarlos correctamente
            for i = 1:length(fieldValues)
                value = fieldValues{i};
                if isnumeric(value) || islogical(value)
                    fieldValues{i} = num2str(value);
                elseif iscell(value)
                    fieldValues{i} = strjoin(string(value), ', ');
                elseif isstruct(value)
                    fieldValues{i} = '[Structure]';
                end
            end

            % Formatear datos para la tabla
            infoTable.Data = [fieldNames, fieldValues];
        else
            uialert(fig, 'The selected modulation has no metadata file.', 'Error');
        end
    end

    % Pasar a la siguiente pantalla
    function continueToSignalSelection()
        selectedModulation = modulationDropdown.Value;

        % 🔹 Bloquear si no se ha seleccionado una modulación válida
        if strcmp(selectedModulation, '---')
            uialert(fig, 'Please select a valid modulation before continuing.', 'Error');
            return;
        end

        % Cerrar esta GUI y abrir la siguiente
        close(fig);
        SelectSignalsGUI(datasetFolder, selectedModulation);
    end
end
