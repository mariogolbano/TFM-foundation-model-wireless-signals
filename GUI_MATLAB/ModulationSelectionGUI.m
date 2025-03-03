function ModulationSelectionGUI(videoBitsMatrix)
    addpath('funcs')

    % Crear la interfaz principal
    fig = uifigure('Name', 'Select Modulations', 'Position', [100 100 900 500]);

    % **Título informativo**
    titleLabel = uilabel(fig, ...
        'Text', 'Select how you want to modulate the videos selected:', ...
        'FontSize', 14, 'FontWeight', 'bold', ...
        'Position', [200 450 500 30]);

    % **Lista de Modulaciones Disponibles**
    %*************** hay que añadir 5g si eso ****************************%
    modulations = {'OFDM', 'DSSS', 'WifiHESU', 'WifiNonHT', 'WifiVHT', 'Bluetooth'};
    
    modulationList = uilistbox(fig, ...
        'Items', modulations, ...
        'Position', [50 150 200 250], ...
        'Multiselect', 'on'); % 

    % **Botón para Configurar Parámetros de Modulación**
    btnConfigure = uibutton(fig, 'Text', 'Configure Modulation', ...
        'Position', [280 300 130 50], ...
        'ButtonPushedFcn', @(btn, event) openModulationConfig());

    % **Lista de Modulaciones Configuradas**
    configuredModulationList = uilistbox(fig, ...
        'Items', {}, ...
        'Position', [520 150 200 250], ...
        'Multiselect', 'off'); % ✅ Corregido

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
                modFig = uifigure('Name', sprintf('%s Parameters', modulationType), 'Position', [200 200 400 300]);
                uilabel(modFig, 'Text', sprintf('Configure parameters for %s:', modulationType), ...
                'FontSize', 12, 'FontWeight', 'bold', 'Position', [50 310 300 30]);

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
                    'Value', true);  % Valor por defecto (marcada)

                uilabel(modFig, 'Text', 'Modulation type:', 'Position', [80 100 200 20]);
                ofdm_mod = uidropdown(modFig, ...
                    'Position', [230 100 100 20], ...
                    'Items', {'BPSK', 'QPSK', '16QAM', '64QAM', '256QAM', '1024QAM'}, ...  
                    'Value', 'BPSK');  % 🔹 Valor por defecto

            case 'DSSS'
                modFig = uifigure('Name', sprintf('%s Parameters', modulationType), 'Position', [200 200 400 180]);
                uilabel(modFig, 'Text', sprintf('Configure parameters for %s:', modulationType), ...
                'FontSize', 12, 'FontWeight', 'bold', 'Position', [50 150 300 30]);

                uilabel(modFig, 'Text', 'Data Rate:', 'Position', [80 125 200 20]);
                dsss_datarate = uidropdown(modFig, ...
                    'Position', [230 125 100 20], ...
                    'Items', {'1Mbps', '2Mbps', '5.5Mbps', '11Mbps'}, ...  
                    'Value', '1Mbps');  % 🔹 Valor por defecto

            case 'WifiHESU'
                modFig = uifigure('Name', sprintf('%s Parameters', modulationType), 'Position', [200 200 400 240]);
                uilabel(modFig, 'Text', sprintf('Configure parameters for %s:', modulationType), ...
                'FontSize', 12, 'FontWeight', 'bold', 'Position', [50 210 300 30]);
                
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
                modFig = uifigure('Name', sprintf('%s Parameters', modulationType), 'Position', [200 200 400 180]);
                uilabel(modFig, 'Text', sprintf('Configure parameters for %s:', modulationType), ...
                'FontSize', 12, 'FontWeight', 'bold', 'Position', [50 150 300 30]);

                uilabel(modFig, 'Text', 'Data Rate:', 'Position', [80 125 200 20]);
                nonht_datarate = uidropdown(modFig, ...
                    'Position', [230 125 100 20], ...
                    'Items', {'1Mbps', '2Mbps', '5.5Mbps', '11Mbps'}, ...  
                    'Value', '1Mbps');  % 🔹 Valor por defecto

            case 'WifiVHT'
                modFig = uifigure('Name', sprintf('%s Parameters', modulationType), 'Position', [200 200 400 240]);
                uilabel(modFig, 'Text', sprintf('Configure parameters for %s:', modulationType), ...
                'FontSize', 12, 'FontWeight', 'bold', 'Position', [50 210 300 30]);
                
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

            case 'Bluetooth'
                modFig = uifigure('Name', sprintf('%s Parameters', modulationType), 'Position', [200 200 400 150]);
                uilabel(modFig, 'Text', sprintf('No parameters to configure for %s', modulationType), ...
                'FontSize', 12, 'FontWeight', 'bold', 'Position', [50 120 300 30]);

            case '5G'
                uilabel(modFig, 'Text', 'Chip Rate (MHz):', 'Position', [50 200 200 30]);
                chipRate = uieditfield(modFig, 'numeric', 'Position', [250 200 100 30], 'Value', 11);

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
                    params.CyclicPrefixLength = ofdm_cylicprefix.Value;
                    params.NumSymbols = ofdm_numsymbs.Value;
                    params.SubcarrierSpacing = ofdm_scs.Value;
                    params.InsertDCnull = ofdm_dc_null.Value;
                    params.Modulation = ofdm_mod.Value;

                case 'DSSS'
                    params.DataRate = dsss_datarate.Value;

                case 'WifiHESU'
                    params.CBW = ['CBW' extractBefore(hesu_cbw.Value, ' ')];
                    params.MCS = str2num(extractBefore(hesu_mcs.Value, ' '));
                    params.ChannelCoding = hesu_coding.Value;
               
                case 'WifiNonHT'
                    params.DataRate = nonht_datarate.Value;
                
                case 'WifiVHT'
                    params.CBW = ['CBW' extractBefore(vht_cbw.Value, ' ')];
                    params.MCS = str2num(extractBefore(vht_mcs.Value, ' '));
                    params.ChannelCoding = vht_coding.Value;

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
        modFig = uifigure('Name', sprintf('%s Parameters (Read-Only)', modKey), ...
                          'Position', [200 200 400 300]);

        params = modulationParams.(modKey);
        paramFields = fieldnames(params);
        yPos = 250;

        for i = 1:length(paramFields)
            uilabel(modFig, 'Text', paramFields{i}, 'Position', [50 yPos 150 30]);
            uieditfield(modFig, 'text', 'Value', num2str(params.(paramFields{i})), ...
                'Position', [210 yPos 130 30], 'Editable', 'off');
            yPos = yPos - 40;
        end

        uibutton(modFig, 'Text', 'Close', 'Position', [150 10 100 30], ...
            'ButtonPushedFcn', @(btn, event) close(modFig));
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
