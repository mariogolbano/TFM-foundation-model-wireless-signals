function SelectSignalsGUI(datasetFolder, selectedModulation)
    % Crear la ventana principal
    fig = uifigure('Name', 'Select Signals for Demodulation', 'Position', [100, 100, 600, 500]);

    % Ruta del dataset seleccionado
    datasetFile = fullfile(datasetFolder, [selectedModulation, '.h5']);

    % Cargar información del dataset
    numAvailableSamples = getNumberOfSamples(datasetFile);

    % Etiqueta con el número de señales disponibles
    uilabel(fig, 'Text', sprintf('Total signals available: %d', numAvailableSamples), ...
        'FontSize', 14, 'FontWeight', 'bold', 'Position', [50, 420, 300, 30]);

    % Campo para indicar cuántas señales cargar (con flechas)
    uilabel(fig, 'Text', 'Number of signals to demodulate:', 'Position', [50, 370, 200, 25]);
    numSignalsField = uispinner(fig, ...
        'Position', [260, 370, 100, 25], ...
        'Value', 1, 'Limits', [1 min(5, numAvailableSamples)], ...
        'ValueChangedFcn', @(src, event) updateSelectionFields());

    % Advertencia si se eligen más de 5 señales
    warningLabel = uilabel(fig, 'Text', '', 'FontColor', [1, 0, 0], 'Position', [50, 340, 400, 25]);

    % Casilla para seleccionar señales aleatorias
    randomCheckBox = uicheckbox(fig, ...
        'Text', 'Random selection', ...
        'Position', [50, 310, 200, 25], ...
        'ValueChangedFcn', @(src, event) toggleSelectionFields());

    % Contenedor de los campos de selección de señales
    selectionPanel = uipanel(fig, 'Title', 'Select Specific Signals', 'Position', [50, 140, 500, 150]);

    % Crear campos de selección de señales (inicialmente ocultos)
    maxSelectable = 5;
    selectionFields = gobjects(maxSelectable, 1);
    for i = 1:maxSelectable
        selectionFields(i) = uieditfield(selectionPanel, 'numeric', ...
            'Position', [20 + (i-1)*90, 50, 70, 25], ...
            'Visible', false, 'Limits', [1 numAvailableSamples], ...
            'Value', i, ... % Se inicia con valores consecutivos
            'ValueChangedFcn', @(src, event) validateUniqueSelection());
    end

    % Botón para continuar
    btnContinue = uibutton(fig, 'Text', 'Continue', 'Position', [310, 50, 150, 50], ...
        'ButtonPushedFcn', @(btn, event) continueToDemodulation());
        % Botón para volver atrás (regresa a `SelectSignalsGUI`)
    
    btnBack = uibutton(fig, 'Text', 'Back', 'Position', [130, 50, 150, 50], ...
        'ButtonPushedFcn', @(btn, event) returnToDemodulateDatasetsFolder());

    % Función para actualizar los campos de selección de señales
    function updateSelectionFields()
        numSignals = round(numSignalsField.Value);
        
        % Mostrar advertencia si supera 5 señales
        if numSignals > 5
            warningLabel.Text = '⚠️ Maximum of 5 signals allowed. Selecting 5.';
            numSignalsField.Value = 5; % Limitar a 5 señales
            numSignals = 5;
        else
            warningLabel.Text = ''; % Limpiar advertencia
        end

        % Mostrar solo los campos necesarios y asignar valores por defecto
        for i = 1:maxSelectable
            if i <= numSignals
                selectionFields(i).Visible = ~randomCheckBox.Value;
                selectionFields(i).Value = i; % Asignar valores por defecto
            else
                selectionFields(i).Visible = false;
            end
        end
    end

    % Función para alternar los campos de selección manual según la casilla aleatoria
    function toggleSelectionFields()
        isRandom = randomCheckBox.Value;
        for i = 1:maxSelectable
            selectionFields(i).Visible = ~isRandom && (i <= numSignalsField.Value);
        end
    end

    % Función para validar que los valores sean únicos
    function validateUniqueSelection()
        numSignals = round(numSignalsField.Value);
        selectedValues = zeros(1, numSignals);

        for i = 1:numSignals
            selectedValues(i) = selectionFields(i).Value;
        end

        % Verificar si hay duplicados
        if length(unique(selectedValues)) < numSignals
            uialert(fig, 'Duplicate values detected. Please select unique signals.', 'Error');
        end
    end

    % Función para obtener el número de señales disponibles en el dataset
    function numSamples = getNumberOfSamples(filename)
        info = h5info(filename, '/dataset');
        numSamples = info.Dataspace.Size(end);
    end

    % Función para continuar a la siguiente pantalla
    function continueToDemodulation()
        numSignals = round(numSignalsField.Value);
        isRandom = randomCheckBox.Value; % Guardamos la selección
    
        if isRandom
            selectedSignals = randperm(numAvailableSamples, numSignals); % Selección aleatoria
        else
            selectedSignals = zeros(1, numSignals);
            for i = 1:numSignals
                selectedSignals(i) = round(selectionFields(i).Value);
            end
            if any(isnan(selectedSignals)) || any(selectedSignals > numAvailableSamples) || any(selectedSignals < 1)
                uialert(fig, 'Invalid signal selection. Ensure values are within the available range.', 'Error');
                return;
            end
        end
    
        % Cerrar la ventana actual y abrir la selección de demodulación o visualización
        close(fig);
        DemodulationGUI(datasetFolder, selectedModulation, selectedSignals);
    end

    % Función para volver a `SelectSignalsGUI`
    function returnToDemodulateDatasetsFolder()
        close(fig);  % Cerrar esta GUI
        DatasetSelection(datasetFolder);
    end

end
