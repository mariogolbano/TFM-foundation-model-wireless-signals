function [processedVideosArray, code_video_bits] = processVideo(video_name, nVideos, nFrames, desired_size, visualize)
    v = VideoReader(video_name);
    
    % Estructura de salida (un array de estructuras)
    processedVideosArray = struct('VideoName', [], 'Frames', [], 'FrameRate', []);

    % Total de frames disponibles en el video
    totalFrames = floor(v.Duration * v.FrameRate);
    
    % Verificar que no intentemos extraer más frames de los que existen
    maxExtractableFrames = nVideos * nFrames;
    if maxExtractableFrames > totalFrames
        warning('⚠️ Not enough frames in %s. Adjusting to available frames.', video_name);
        nVideos = floor(totalFrames / nFrames); % Ajustar el número de subvideos
    end
    
    % Matriz para almacenar todos los bits generados
    code_video_bits = [];

    for vidIdx = 1:nVideos
        % Calcular el inicio del subvideo
        fstart = (vidIdx - 1) * nFrames + 1;
        fend = min(fstart + nFrames - 1, totalFrames);
        
        % Reiniciar el lector de video en el primer frame del subvideo
        v.CurrentTime = (fstart - 1) / v.FrameRate;
        
        % Inicializar estructura para el subvideo
        subVideoStruct = struct();
        subVideoStruct.VideoName = sprintf('%s_%d', erase(video_name, '.mp4'), vidIdx); % Nombre vid1_1, vid1_2...
        subVideoStruct.Frames = {};
        subVideoStruct.FrameRate = v.FrameRate;
        
        % Matriz de bits para este subvideo
        video_bits = zeros(nFrames, desired_size^2 * 8, 'int8');

        frameIdx = 1;
        while hasFrame(v) && frameIdx <= nFrames
            frame = readFrame(v);

            % Convertir a escala de grises
            grayFrame = rgb2gray(frame);

            % Redimensionar el frame para que la dimensión más pequeña sea desired_size
            [h, w] = size(grayFrame);
            scale = desired_size / min(h, w);
            resizedFrame = imresize(grayFrame, scale);

            % Recortar (cropping) centrado
            [new_h, new_w] = size(resizedFrame);
            start_h = floor((new_h - desired_size) / 2) + 1;
            start_w = floor((new_w - desired_size) / 2) + 1;
            croppedFrame = resizedFrame(start_h:start_h+desired_size-1, start_w:start_w+desired_size-1);

            % Guardar frame en la estructura del subvideo
            subVideoStruct.Frames{end + 1} = croppedFrame;

            % Convertir frame a bits
            frame_bin = double(dec2bin(croppedFrame, 8)') - 48; % Convertir '0'/'1' a 0/1
            video_bits(frameIdx, :) = int8(frame_bin(:))';

            frameIdx = frameIdx + 1;
        end

        % Agregar subvideo a la lista de videos procesados
        processedVideosArray(vidIdx) = subVideoStruct;
        
        % Agregar bits generados al array general
        code_video_bits = [code_video_bits, reshape(video_bits', [], 1)];
        
        % Visualizar si está activado
        if visualize
            figure;
            for i = 1:numel(subVideoStruct.Frames)
                imshow(subVideoStruct.Frames{i});
                title(sprintf('%s - Frame %d', subVideoStruct.VideoName, i));
                pause(1/v.FrameRate);
            end
        end
    end
end
