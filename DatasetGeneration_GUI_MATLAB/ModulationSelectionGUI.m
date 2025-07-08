function ModulationSelectionGUI(videoBitsMatrix)
    addpath(genpath('../funcs'));

    % Crear la interfaz principal
    fig = uifigure('Name', 'Select Modulations', 'Position', [100 100 900 500]);

    % **Título informativo**
    titleLabel = uilabel(fig, ...
        'Text', 'Select how you want to modulate the videos selected:', ...
        'FontSize', 14, 'FontWeight', 'bold', ...
        'Position', [50 450 500 30]);

    % **Lista de Modulaciones Disponibles**
    modulations = {'PSK', 'QAM', 'OFDM', 'DSSS', 'WifiVHT', 'WifiNonHT', 'WifiHESU', 'Bluetooth'};
    
    modulationList = uilistbox(fig, ...
        'Items', modulations, ...
        'Position', [50 150 200 250], ...
        'Multiselect', 'on'); % 

    % **Botón para Configurar Parámetros de Modulación**
    btnConfigure = uibutton(fig, 'Text', 'Configure Modulation', ...
        'Position', [280 300 130 50], ...
        'ButtonPushedFcn', @(btn, event) openModulationConfig());

    % **Botón para Importar Configuración desde JSON**
    btnImport = uibutton(fig, 'Text', 'Import configuration from JSON', ...
        'Position', [625 430 200 50], ...
        'ButtonPushedFcn', @(btn, event) importModulationConfig());

    % **Lista de Modulaciones Configuradas**
    configuredModulationList = uilistbox(fig, ...
        'Items', {}, ...
        'Position', [520 150 200 250], ...
        'Multiselect', 'off'); % 

    % **Botón para consultar Configuración de Modulaciones Seleccionadas**
    btnEdit = uibutton(fig, 'Text', 'Consult Parameters', ...
        'Position', [740 300 130 50], ...
        'ButtonPushedFcn', @(btn, event) consultModulationConfig());

    % **Botón para Eliminar Modulaciones Configuradas**
    btnRemove = uibutton(fig, 'Text', 'Remove Selected', ...
        'Position', [740 220 130 50], ...
        'ButtonPushedFcn', @(btn, event) removeModulation());

    % **Botón para Continuar**
    btnNext = uibutton(fig, 'Text', 'Continue', ...
        'Position', [350 50 200 50], ...
        'ButtonPushedFcn', @(btn, event) processModulations());

    % **Estructura para Almacenar Parámetros**
    modulationParams = struct();
    
    % **Contador para Múltiples Configuraciones**
    modCount = containers.Map(modulations, num2cell(zeros(size(modulations))));

    % **Función para Abrir Configuración de Modulación**
    function openModulationConfig()
        selectedModulations = modulationList.Value;
        
        if isempty(selectedModulations)
            uialert(fig, 'Please select a modulation to configure.', 'Error');
            return;
        end

        for i = 1:length(selectedModulations)
            modulationType = selectedModulations{i};
            configureModulationParams(modulationType);
        end
    end

    % **Función para Configurar Parámetros de Modulación**
    function configureModulationParams(modulationType)
        % Crear nueva ventana de configuración
        
        % Definir parámetros según modulación
        switch modulationType
            case 'OFDM'
                modFig = uifigure('Name', sprintf('%s Parameters', modulationType), 'Position', [200 200 400 335]);
                uilabel(modFig, 'Text', sprintf('Configure parameters for %s:', modulationType), ...
                'FontSize', 12, 'FontWeight', 'bold', 'Position', [50 345 300 30]);

                uilabel(modFig, 'Text', 'Noise - SNR (dB):', 'Position', [80 310 200 20]);
                ofdm_noise = uieditfield(modFig, 'numeric', 'Position', [245 310 70 20], 'Value', 50);

                uilabel(modFig, 'Text', 'FFT length:', 'Position', [80 275 200 30]);
                ofdm_fftlength = uieditfield(modFig, 'numeric', 'Position', [245 275 70 20], 'Value', 64);
                
                uilabel(modFig, 'Text', 'Cyclic Prefix Lenght:', 'Position', [80 240 200 30]);
                ofdm_cylicprefix = uieditfield(modFig, 'numeric', 'Position', [245 240 70 20], 'Value', 16);

                uilabel(modFig, 'Text', 'OFDM symbols:', 'Position', [80 205 200 30]);
                ofdm_numsymbs = uieditfield(modFig, 'numeric', 'Position', [245 205 70 20], 'Value', 100);

                uilabel(modFig, 'Text', 'Subcarrier Spacing:', 'Position', [80 170 200 20]);
                ofdm_scs = uieditfield(modFig, 'numeric', 'Position', [245 170 70 20], 'Value', 1000000);
                
                uilabel(modFig, 'Text', 'Insert DC null:', 'Position', [80 135 200 20]);
                ofdm_dc_null = uicheckbox(modFig, ...
                    'Position', [245 135 100 20], ...
                    'Text', '', ...  % No mostrar texto en la checkbox
                    'Value', false);  % Valor por defecto (marcada)

                uilabel(modFig, 'Text', 'Modulation type:', 'Position', [80 100 200 20]);
                ofdm_mod = uidropdown(modFig, ...
                    'Position', [230 100 100 20], ...
                    'Items', {'BPSK', 'QPSK', '16QAM', '64QAM', '256QAM', '1024QAM'}, ...  
                    'Value', 'BPSK');  % 🔹 Valor por defecto

            case 'DSSS'
                modFig = uifigure('Name', sprintf('%s Parameters', modulationType), 'Position', [200 200 400 200]);
                uilabel(modFig, 'Text', sprintf('Configure parameters for %s:', modulationType), ...
                'FontSize', 12, 'FontWeight', 'bold', 'Position', [50 170 300 30]);

                uilabel(modFig, 'Text', 'Noise - SNR (dB):', 'Position', [80 135 200 20]);
                dsss_noise = uieditfield(modFig, 'numeric', 'Position', [245 135 70 20], 'Value', 50);

                uilabel(modFig, 'Text', 'Data Rate:', 'Position', [80 100 200 20]);
                dsss_datarate = uidropdown(modFig, ...
                    'Position', [230 100 100 20], ...
                    'Items', {'1Mbps', '2Mbps', '5.5Mbps', '11Mbps'}, ...  
                    'Value', '1Mbps');  % 🔹 Valor por defecto

            case 'WifiHESU'
                modFig = uifigure('Name', sprintf('%s Parameters', modulationType), 'Position', [200 200 400 270]);
                uilabel(modFig, 'Text', sprintf('Configure parameters for %s:', modulationType), ...
                'FontSize', 12, 'FontWeight', 'bold', 'Position', [50 240 300 30]);

                uilabel(modFig, 'Text', 'Noise - SNR (dB):', 'Position', [80 205 200 20]);
                hesu_noise = uieditfield(modFig, 'numeric', 'Position', [245 205 70 20], 'Value', 50);
                
                uilabel(modFig, 'Text', 'Channel Bandwidth:', 'Position', [80 170 200 20]);
                hesu_cbw = uidropdown(modFig, ...
                    'Position', [230 170 150 20], ...
                    'Items', {'20 MHz', '40 MHz', '80 MHz', '160 MHz'}, ...  
                    'Value', '20 MHz');  % 🔹 Valor por defecto

                uilabel(modFig, 'Text', 'MCS (Mod:Code rate):', 'Position', [80 135 200 20]);
                hesu_mcs = uidropdown(modFig, ...
                    'Position', [230 135 150 20], ...
                    'Items', {'0 (BPSK:1/2)', '1 (QPSK:1/2)', '2 (QPSK:3/4)', '3 (16QAM:1/2)', '4 (16QAM:3/4)', '5 (64QAM:2/3)', '6 (64QAM:3/4)', '7 (64QAM:5/6)', '8 (256QAM:3/4)', '9 (256QAM:5/6)', '10 (1024QAM:3/4)', '11 (1024QAM:5/6'}, ...  
                    'Value', '0 (BPSK:1/2)');  % 🔹 Valor por defecto

                uilabel(modFig, 'Text', 'Coding type:', 'Position', [80 100 200 20]);
                hesu_coding = uidropdown(modFig, ...
                    'Position', [230 100 150 20], ...
                    'Items', {'LDPC', 'BCC'}, ...  
                    'Value', 'LDPC');  % 🔹 Valor por defecto

            case 'WifiNonHT'
                modFig = uifigure('Name', sprintf('%s Parameters', modulationType), 'Position', [200 200 400 200]);
                uilabel(modFig, 'Text', sprintf('Configure parameters for %s:', modulationType), ...
                'FontSize', 12, 'FontWeight', 'bold', 'Position', [50 170 300 30]);

                uilabel(modFig, 'Text', 'Noise - SNR (dB):', 'Position', [80 135 200 20]);
                nonht_noise = uieditfield(modFig, 'numeric', 'Position', [245 135 70 20], 'Value', 50);

                uilabel(modFig, 'Text', 'Data Rate:', 'Position', [80 100 200 20]);
                nonht_datarate = uidropdown(modFig, ...
                    'Position', [230 100 100 20], ...
                    'Items', {'1Mbps', '2Mbps', '5.5Mbps', '11Mbps'}, ...  
                    'Value', '1Mbps');  % 🔹 Valor por defecto

            case 'WifiVHT'
                modFig = uifigure('Name', sprintf('%s Parameters', modulationType), 'Position', [200 200 400 270]);
                uilabel(modFig, 'Text', sprintf('Configure parameters for %s:', modulationType), ...
                'FontSize', 12, 'FontWeight', 'bold', 'Position', [50 240 300 30]);

                uilabel(modFig, 'Text', 'Noise - SNR (dB):', 'Position', [80 205 200 20]);
                vht_noise = uieditfield(modFig, 'numeric', 'Position', [245 205 70 20], 'Value', 50);

                uilabel(modFig, 'Text', 'Channel Bandwidth:', 'Position', [80 170 200 20]);
                vht_cbw = uidropdown(modFig, ...
                    'Position', [230 170 150 20], ...
                    'Items', {'20 MHz', '40 MHz', '80 MHz', '160 MHz'}, ...  
                    'Value', '20 MHz');  % 🔹 Valor por defecto

                uilabel(modFig, 'Text', 'MCS (Mod:Code rate):', 'Position', [80 135 200 20]);
                vht_mcs = uidropdown(modFig, ...
                    'Position', [230 135 150 20], ...
                    'Items', {'0 (BPSK:1/2)', '1 (QPSK:1/2)', '2 (QPSK:3/4)', '3 (16QAM:1/2)', '4 (16QAM:3/4)', '5 (64QAM:2/3)', '6 (64QAM:3/4)', '7 (64QAM:5/6)', '8 (256QAM:3/4)', '9 (256QAM:5/6)'}, ...  
                    'Value', '0 (BPSK:1/2)');  % 🔹 Valor por defecto

                uilabel(modFig, 'Text', 'Coding type:', 'Position', [80 100 200 20]);
                vht_coding = uidropdown(modFig, ...
                    'Position', [230 100 150 20], ...
                    'Items', {'LDPC', 'BCC'}, ...  
                    'Value', 'LDPC');  % 🔹 Valor por defecto


            case 'PSK'
                modFig = uifigure('Name', sprintf('%s Parameters', modulationType), 'Position', [200 200 400 250]);
                uilabel(modFig, 'Text', sprintf('Configure parameters for %s:', modulationType), ...
                'FontSize', 12, 'FontWeight', 'bold', 'Position', [50 220 300 30]);

                uilabel(modFig, 'Text', 'Noise - SNR (dB):', 'Position', [80 185 200 20]);
                psk_noise = uieditfield(modFig, 'numeric', 'Position', [245 185 70 20], 'Value', 50);

                uilabel(modFig, 'Text', 'Modulation Order:', 'Position', [80 150 200 20]);
                psk_mod = uidropdown(modFig, ...
                    'Position', [230 150 100 20], ...
                    'Items', {'2 (BPSK)', '4 (QPSK)', '8 (8PSK)'}, ...  
                    'Value', '2 (BPSK)');  

                uilabel(modFig, 'Text', 'Output Symbol Rate:', 'Position', [80 115 200 20]);
                psk_sym_rate = uieditfield(modFig, 'numeric', 'Position', [245 115 70 20], 'Value', 1000);

            case 'QAM'
                modFig = uifigure('Name', sprintf('%s Parameters', modulationType), 'Position', [200 200 400 250]);
                uilabel(modFig, 'Text', sprintf('Configure parameters for %s:', modulationType), ...
                'FontSize', 12, 'FontWeight', 'bold', 'Position', [50 220 300 30]);

                uilabel(modFig, 'Text', 'Noise - SNR (dB):', 'Position', [80 185 200 20]);
                qam_noise = uieditfield(modFig, 'numeric', 'Position', [245 185 70 20], 'Value', 50);

                uilabel(modFig, 'Text', 'Modulation Order:', 'Position', [80 150 200 20]);
                qam_mod = uidropdown(modFig, ...
                    'Position', [230 150 100 20], ...
                    'Items', {'2', '4', '8', '16', '32', '64', '128', '256', '512', '1024', '2048', '4096'}, ...  
                    'Value', '2');  

                uilabel(modFig, 'Text', 'Output Symbol Rate:', 'Position', [80 115 200 20]);
                qam_sym_rate = uieditfield(modFig, 'numeric', 'Position', [245 115 70 20], 'Value', 1000);

            case 'Bluetooth'
                modFig = uifigure('Name', sprintf('%s Parameters', modulationType), 'Position', [200 200 400 180]);
                uilabel(modFig, 'Text', sprintf('No specific parameters to configure for %s', modulationType), ...
                'FontSize', 12, 'FontWeight', 'bold', 'Position', [50 150 300 30]);

                uilabel(modFig, 'Text', 'Noise - SNR (dB):', 'Position', [80 115 200 20]);
                bt_noise = uieditfield(modFig, 'numeric', 'Position', [245 115 70 20], 'Value', 50);

        end

        % Botón para Guardar Configuración
        btnSave = uibutton(modFig, 'Text', 'Save Parameters', ...
            'Position', [150 30 110 40], ...
            'ButtonPushedFcn', @(btn, event) saveModulationParams(modulationType));

        % **Función para Guardar los Parámetros**
        function saveModulationParams(modulationType)
            switch modulationType
                case 'OFDM'
                    params.FFTLength = ofdm_fftlength.Value;
                    params.cyclicPrefixLength = ofdm_cylicprefix.Value;
                    params.numSymbols = ofdm_numsymbs.Value;
                    params.subcarrierSpacing = ofdm_scs.Value;
                    params.DCnull = ofdm_dc_null.Value;
                    params.modulation = ofdm_mod.Value;
                    params.snr = (ofdm_noise.Value);

                case 'DSSS'
                    params.dataRate = dsss_datarate.Value;
                    params.snr = (dsss_noise.Value);


                case 'WifiHESU'
                    params.cbw = ['CBW' extractBefore(hesu_cbw.Value, ' ')];
                    params.mcs = str2num(extractBefore(hesu_mcs.Value, ' '));
                    params.channelCoding = hesu_coding.Value;
                    params.snr = (hesu_noise.Value);

                case 'WifiNonHT'
                    params.dataRate = nonht_datarate.Value;
                    params.snr = (nonht_noise.Value);
                
                case 'WifiVHT'
                    params.cbw = ['CBW' extractBefore(vht_cbw.Value, ' ')];
                    params.mcs = str2num(extractBefore(vht_mcs.Value, ' '));
                    params.channelCoding = vht_coding.Value;
                    params.snr = (vht_noise.Value);

                case 'Bluetooth'
                    params.snr = (bt_noise.Value);
                
                case 'PSK'
                    params.modOrder = psk_mod.Value;
                    params.symRate = psk_sym_rate.Value;
                    params.snr = (psk_noise.Value);
                
                case 'QAM'
                    params.modOrder = qam_mod.Value;
                    params.symRate = qam_sym_rate.Value;
                    params.snr = (qam_noise.Value);

            end
            
            % **Verificar si los parámetros ya existen**
            existingConfigs = fieldnames(modulationParams);
            for i = 1:length(existingConfigs)
                if isequal(modulationParams.(existingConfigs{i}), params)
                    uialert(modFig, 'This configuration already exists.', 'Warning');
                    return;
                end
            end

            % **Añadir un Índice al Nombre**
            modCount(modulationType) = modCount(modulationType) + 1;
            modKey = sprintf('%s_%d', modulationType, modCount(modulationType));

            % **Guardar la Configuración**
            modulationParams.(modKey) = params;
            updateConfiguredList(modKey);
            uialert(modFig, sprintf('%s parameters saved!', modKey), 'Success');
            close(modFig);
        end
    end

    % **Actualizar Lista de Modulaciones Configuradas**
    function updateConfiguredList(modKey)
        configuredItems = configuredModulationList.Items;
        
        % Asegurar que configuredItems sea un cell array
        if ischar(configuredItems)
            configuredItems = {configuredItems};  % Convertir en cell array
        elseif isempty(configuredItems)
            configuredItems = {}; % Inicializar como cell vacío
        end
    
        % Asegurar que modKey también sea cell array
        if ischar(modKey)
            modKey = {modKey};  % Convertir en cell array
        end
    
        % Agregar modulación si no está en la lista
        if ~any(strcmp(configuredItems, modKey))
            configuredModulationList.Items = [configuredItems(:); modKey(:)]; % Asegurar concatenación correcta
        end
    end

    % **Eliminar Modulaciones Seleccionadas**
    function removeModulation()
        selectedToRemove = configuredModulationList.Value;
        if isempty(selectedToRemove)
            uialert(fig, 'No modulations selected to remove.', 'Error');
            return;
        end

        configuredModulationList.Items = setdiff(configuredModulationList.Items, selectedToRemove);
        modulationParams = rmfield(modulationParams, selectedToRemove); % Eliminar de la estructura
    end

    % **Función para Consultar Parámetros de una Modulación Configurada**
    function consultModulationConfig()
        selectedToConsult = configuredModulationList.Value;
        if isempty(selectedToConsult)
            uialert(fig, 'Please select a configured modulation to consult.', 'Error');
            return;
        end
    
        showModulationParams(selectedToConsult);
    end

    % **Función para Mostrar Parámetros (Solo Lectura)**
    function showModulationParams(modKey)
        params = modulationParams.(modKey);
        paramFields = fieldnames(params);

        modFig = uifigure('Name', sprintf('%s Parameters (Read-Only)', modKey), ...
                          'Position', [200 200 400 ((length(paramFields)+1)*40 + 20)]);

        yPos = (length(paramFields) * 40 + 20);

        for i = 1:length(paramFields)
            uilabel(modFig, 'Text', paramFields{i}, 'Position', [50 yPos 150 30]);
            uieditfield(modFig, 'text', 'Value', num2str(params.(paramFields{i})), ...
                'Position', [210 yPos 130 30], 'Editable', 'off');
            yPos = yPos - 40;
        end

        uibutton(modFig, 'Text', 'Close', 'Position', [150 10 100 30], ...
            'ButtonPushedFcn', @(btn, event) close(modFig));
    end

    % **Función para Importar Configuración desde JSON**
    function importModulationConfig()
        [jsonFiles, jsonPath] = uigetfile('*.json', 'Select JSON Config Files', 'MultiSelect', 'on');

        if isequal(jsonFiles, 0)
            return; % Si el usuario cancela, no hacer nada
        end

        if ischar(jsonFiles)
            jsonFiles = {jsonFiles}; % Asegurar formato de celda para múltiples archivos
        end

        for i = 1:length(jsonFiles)
            jsonFilePath = fullfile(jsonPath, jsonFiles{i});
            try
                % Leer JSON y decodificarlo
                jsonData = fileread(jsonFilePath);
                importedParams = jsondecode(jsonData);

                % Extraer el nombre base de la modulación del campo "mod"
                if isfield(importedParams, 'mod')
                    modBaseName = extractBefore(importedParams.mod, '_');
                else
                    uialert(fig, sprintf('Error: Missing "mod" field in %s', jsonFiles{i}), 'Error');
                    continue;
                end

                % Filtrar solo los campos relevantes de la configuración
                switch modBaseName
                    case 'OFDM'
                        configurableFields = {'FFTLength', 'cyclicPrefixLength', 'numSymbols', 'subcarrierSpacing', 'DCnull', 'modulation', 'snr'};
                    case 'DSSS'
                        configurableFields = {'dataRate', 'snr'};
                    case 'WifiHESU'
                        configurableFields = {'cbw', 'mcs','channelCoding', 'snr'};
                    case 'WifiNonHT'
                        configurableFields = {'cbw', 'snr'};
                    case 'WifiVHT'
                        configurableFields = {'cbw', 'mcs','channelCoding', 'snr'};
                    case 'Bluetooth'
                        configurableFields = {'snr'};
                    case 'PSK'
                        configurableFields = {'modOrder', 'symbolRate', 'snr'};
                    case 'QAM'
                        configurableFields = {'modOrder', 'symbolRate', 'snr'};


                end
                importedFiltered = rmfield(importedParams, setdiff(fieldnames(importedParams), configurableFields));

                % Verificar si ya existe una configuración con los mismos parámetros relevantes
                existingConfigs = fieldnames(modulationParams);
                for j = 1:length(existingConfigs)
                    existingFiltered = rmfield(modulationParams.(existingConfigs{j}), ...
                                               setdiff(fieldnames(modulationParams.(existingConfigs{j})), configurableFields));
                    if isequal(existingFiltered, importedFiltered)
                        uialert(fig, sprintf('Configuration from %s already exists.', jsonFiles{i}), 'Warning');
                        return;
                    end
                end

                % Asignar un índice único
                modCount(modBaseName) = modCount(modBaseName) + 1;
                modKey = sprintf('%s_%d', modBaseName, modCount(modBaseName));

                % Guardar la configuración importada en `modulationParams`
                modulationParams.(modKey) = importedFiltered;
                updateConfiguredList(modKey);
            catch
                uialert(fig, sprintf('Error importing %s. Ensure it is a valid JSON configuration.', jsonFiles{i}), 'Error');
            end
        end
    end

    % **Función para Continuar con la Modulación**
    function processModulations()
        if isempty(fieldnames(modulationParams))
            uialert(fig, 'No modulations configured. Please configure at least one.', 'Error');
            return;
        end

        close(fig);
        ModulationProcessingGUI(videoBitsMatrix, modulationParams);
    end
end
