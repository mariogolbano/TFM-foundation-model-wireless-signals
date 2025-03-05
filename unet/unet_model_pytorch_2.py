import torch
import torch.nn as nn
import torch.nn.functional as F

class UNet1D(nn.Module):
    def __init__(self, input_channels, output_channels, k_sz=3, long_k_sz=101, k_neurons=32):
        super(UNet1D, self).__init__()
        self.encoders = nn.ModuleList()
        self.pools = nn.ModuleList()
        self.decoders = nn.ModuleList()
        self.upsamples = nn.ModuleList()
        
        # Encoder
        k_list = [8, 8, 8, 8, 8]
        for i, k in enumerate(k_list):
            if i == 0:
                self.encoders.append(nn.Sequential(
                    nn.Conv1d(input_channels, k_neurons * k, long_k_sz, padding=long_k_sz // 2),
                    nn.ReLU(),
                    nn.Conv1d(k_neurons * k, k_neurons * k, k_sz, padding=k_sz // 2),
                    nn.ReLU()
                ))
            else:
                self.encoders.append(nn.Sequential(
                    nn.Conv1d(k_neurons * k_list[i-1], k_neurons * k, k_sz, padding=k_sz // 2),
                    nn.ReLU(),
                    nn.Conv1d(k_neurons * k, k_neurons * k, k_sz, padding=k_sz // 2),
                    nn.ReLU()
                ))
            self.pools.append(nn.Sequential(
                nn.MaxPool1d(2),
                nn.Dropout(0.25 if i == 0 else 0.5)
            ))

        # Middle
        self.middle = nn.Sequential(
            nn.Conv1d(k_neurons * 8, k_neurons * 8, k_sz, padding=k_sz // 2),
            nn.ReLU(),
            nn.Conv1d(k_neurons * 8, k_neurons * 8, k_sz, padding=k_sz // 2),
            nn.ReLU()
        )
        
        # Decoder
        k_decoder_list = [8, 8, 4, 2, 1]
        last_k = 8  # Número de filtros inicial del middle (última capa del encoder)
        for i, k in enumerate(k_decoder_list):
            self.upsamples.append(nn.ConvTranspose1d(
                in_channels=k_neurons * last_k,  # Canales de entrada = filtros de la capa previa
                out_channels=k_neurons * k,  # Canales de salida = número actual de filtros
                kernel_size=k_sz,
                stride=2,
                padding=k_sz // 2,
                output_padding=1
            ))
            self.decoders.append(nn.Sequential(
                nn.Conv1d(k_neurons * (k + 8), k_neurons * k, k_sz, padding=k_sz // 2),  # Concatenación: entrada = filtros de upsample (32 * 8 filtros siempre) + skip connection
                nn.ReLU(),
                nn.Conv1d(k_neurons * k, k_neurons * k, k_sz, padding=k_sz // 2),
                nn.ReLU()
            ))
            last_k = k  # Actualiza j para reflejar los filtros de salida actuales

        
        # Output
        self.output_layer = nn.Conv1d(k_neurons, output_channels, kernel_size=1)

    def forward(self, x):
        skips = []
        
        # Encoder
        for i, (encoder, pool) in enumerate(zip(self.encoders, self.pools)):
            #print(f"Encoder {i+1} input shape: {x.shape}")
            x = encoder(x)
            #print(f"Encoder {i+1} output shape after Conv1d: {x.shape}")
            skips.append(x)
            x = pool(x)
            #print(f"Encoder {i+1} output shape after Pool: {x.shape}")
        
        # Middle
        #print(f"Middle input shape: {x.shape}")
        x = self.middle(x)
        #print(f"Middle output shape: {x.shape}")
        
        # Decoder
        for i, (upsample, decoder) in enumerate(zip(self.upsamples, self.decoders)):
            #print(f"Decoder {i+1} input shape: {x.shape}")
            x = upsample(x)
            #print(f"Decoder {i+1} output shape after ConvTranspose1d: {x.shape}")
            x = torch.cat([x, skips[-(i+1)]], dim=1)
            #print(f"Decoder {i+1} shape after concatenation: {x.shape}")
            x = decoder(x)
            #print(f"Decoder {i+1} output shape after Conv1d: {x.shape}")
        
        # Output
        #print(f"Final output layer input shape: {x.shape}")
        x = self.output_layer(x)
        #print(f"Final output shape: {x.shape}")
        
        return x