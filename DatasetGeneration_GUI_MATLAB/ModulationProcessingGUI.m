function ModulationProcessingGUI(videoBitsMatrix, modulationParams)
    addpath(genpath('../funcs'));

    % Crear la interfaz principal
    fig = uifigure('Name', 'Modulation Processing', 'Position', [100 100 900 600]);

    % **Título informativo**
    titleLabel = uilabel(fig, ...
        'Text', 'Processing Modulations and Saving Datasets...', ...
        'FontSize', 14, 'FontWeight', 'bold', ...
        'Position', [250 550 500 30]);

    % **Lista de Modulaciones Configuradas**
    configuredModList = uilistbox(fig, ...
        'Items', fieldnames(modulationParams), ...
        'Position', [50 150 250 350], ...
        'Multiselect', 'off');

    % **Nombre de la Carpeta de Almacenamiento**
    datasetsFolder = '../datasets';
    if ~exist(datasetsFolder, 'dir')
        mkdir(datasetsFolder);
    end
    
    todayDate = datestr(now, 'yyyy-mm-dd');
    datasetIndex = 1;
    
    while exist(fullfile(datasetsFolder, sprintf('dataset_%s_%d', todayDate, datasetIndex)), 'dir')
        datasetIndex = datasetIndex + 1;
    end
    
    defaultFolderName = sprintf('dataset_%s_%d', todayDate, datasetIndex);
    datasetFolderPath = fullfile(datasetsFolder, defaultFolderName);
    
    uilabel(fig, 'Text', 'Dataset Folder:', 'Position', [320 420 150 30]);
    datasetFolderField = uieditfield(fig, 'text', 'Position', [320 390 300 30], 'Value', defaultFolderName);

    % **Botón para Iniciar la Modulación**
    btnStart = uibutton(fig, 'Text', 'Start Modulation', ...
        'Position', [350 300 200 50], ...
        'ButtonPushedFcn', @(btn, event) startModulation());

    % **Función para Iniciar la Modulación**
    function startModulation()
        chosenFolder = datasetFolderField.Value;
        datasetPath = fullfile(datasetsFolder, chosenFolder);

        % Verificar si la carpeta ya existe
        if exist(datasetPath, 'dir')
            uialert(fig, 'The selected dataset folder already exists. Please choose another name.', 'Error');
            return;
        end

        mkdir(datasetPath); % Crear la carpeta si no existe

        % Total de iteraciones para progreso global
        totalSteps = length(fieldnames(modulationParams)) * numel(videoBitsMatrix);
        currentStep = 0;

        % **Barra de Progreso Global**
        globalProgress = waitbar(0, 'Overall Progress', 'Position',[400, 350, 300,50]);

        % Procesar cada modulación
        modulations = fieldnames(modulationParams);
        for i = 1:length(modulations)
            modKey = modulations{i};
            modParams = modulationParams.(modKey);
            
            snrValue = modulationParams.(modKey).snr;

            % **Barra de Progreso Individual por Modulación**
            modProgress = waitbar(0, sprintf('Processing %s...', modKey), 'Position', [400,250,300,50]);

            % Inicializar archivo HDF5
            filename = fullfile(datasetPath, [modKey, '.h5']);
            filenameBits = fullfile(datasetPath, ['bits_', modKey, '.h5']);
            
            waveforms = [];
            bits_signals = [];

            for j = 1:numel(videoBitsMatrix)
                videoBits = videoBitsMatrix(j).bits;
                
                % Aplicar modulación
                baseModulation = extractBefore(modKey, '_');
                funcModulation = strcat(baseModulation, '_mod');
                
                signal = feval(funcModulation, double(videoBits), modParams); % Llamar función de modulación

                % Add noise (AWGN)
                noisyWaveform_real = awgn(signal.sig.real, snrValue);
                noisyWaveform_imag = awgn(signal.sig.imag, snrValue);

                % Reshape waveform para almacenar en HDF5
                waveform_reshaped = cat(2, noisyWaveform_real, noisyWaveform_imag);
                waveforms = cat(3, waveforms, waveform_reshaped);
                bits_signals = [bits_signals, videoBits];

                % Guardar Metadata (solo la primera vez)
                if j == 1
                    mat_filepath = fullfile(datasetPath, [modKey, '.mat']);
                    json_filepath = fullfile(datasetPath, [modKey, '.json']);

                    if ~isfile(mat_filepath)
                        signal = rmfield(signal, 'sig');
                        signal.snr = snrValue;
                        save(mat_filepath, '-struct', 'signal');

                        % Guardar en un archivo JSON
                        jsonData = jsonencode(signal);
                        fid = fopen(json_filepath, 'w');
                        fwrite(fid, jsonData, 'char');
                        fclose(fid);

                    end
                end

                % Actualizar barra de progreso individual
                waitbar(j / numel(videoBitsMatrix), modProgress, ...
                    sprintf('Processing %s - Video %d/%d', modKey, j, numel(videoBitsMatrix)));
                pause(0.1); % Simulación del proceso de modulación

                % Actualizar barra de progreso global
                currentStep = currentStep + 1;
                waitbar(currentStep / totalSteps, globalProgress, ...
                    sprintf('Overall Progress: %d/%d', currentStep, totalSteps));
                videoBits_prev = videoBits;

            end

            % Guardar en HDF5
            saveSignalToHDF5(filename, waveforms);
            saveBitsToHDF5(filenameBits, bits_signals);
                        
            % Cerrar barra de progreso individual
            close(modProgress);
            
            fprintf('Completed: %s\n', modKey);
        end

        % Cerrar la barra de progreso global
        close(globalProgress);

        uialert(fig, 'All modulations completed successfully!', 'Success');
    end
    
    % **Guardar Señales en HDF5**
    function saveSignalToHDF5(filename, waveforms)
        waveforms = single(waveforms);
        % Abrir o crear el archivo HDF5 para las señales
        file_id = H5F.create(filename, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
        
        % Obtener dimensiones de la señal
        dims = size(waveforms);
        frameSize = [50, 50]; % Definir manualmente el tamaño del frame
        
        % Crear el espacio de datos
        dataspace_id = H5S.create_simple(ndims(waveforms), fliplr(dims), []);
        
        % Crear el dataset con tipo de dato double
        dataset_id = H5D.create(file_id, 'dataset', 'H5T_NATIVE_FLOAT', dataspace_id, 'H5P_DEFAULT');
        
        % Escribir los datos en el dataset
        H5D.write(dataset_id, 'H5T_NATIVE_FLOAT', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', waveforms);
        
        % Añadir un atributo para el tamaño del frame
        attr_id = H5A.create(dataset_id, 'FrameSize', 'H5T_NATIVE_DOUBLE', ...
                             H5S.create_simple(1, numel(frameSize), []), 'H5P_DEFAULT');
        H5A.write(attr_id, 'H5T_NATIVE_DOUBLE', frameSize);
        
        % Cerrar recursos
        H5A.close(attr_id);
        H5D.close(dataset_id);
        H5S.close(dataspace_id);
        H5F.close(file_id);
        
        disp(['HDF5 file created: ', filename]);
    end
    
    % **Guardar Bits en HDF5**
    function saveBitsToHDF5(filename, bits_signals)
        % Abrir o crear el archivo HDF5 para los bits
        file_id = H5F.create(filename, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
        
        % Obtener dimensiones de los bits
        dims = size(bits_signals);
        frameSize = [50, 50]; % Definir manualmente el tamaño del frame
        
        % Crear el espacio de datos
        dataspace_id = H5S.create_simple(2, fliplr(dims), []);
        
        % Crear el dataset con tipo de dato int8
        dataset_id = H5D.create(file_id, 'dataset', 'H5T_NATIVE_INT8', dataspace_id, 'H5P_DEFAULT');
        
        % Escribir los bits en el dataset
        H5D.write(dataset_id, 'H5T_NATIVE_INT8', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', bits_signals);
        
        % Añadir un atributo para el tamaño del frame
        attr_id = H5A.create(dataset_id, 'FrameSize', 'H5T_NATIVE_DOUBLE', ...
                             H5S.create_simple(1, numel(frameSize), []), 'H5P_DEFAULT');
        H5A.write(attr_id, 'H5T_NATIVE_DOUBLE', frameSize);
        
        % Cerrar recursos
        H5A.close(attr_id);
        H5D.close(dataset_id);
        H5S.close(dataspace_id);
        H5F.close(file_id);
        
        disp(['HDF5 file created: ', filename]);
    end
end
