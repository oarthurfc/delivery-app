package com.service.order.services;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.reactive.function.client.WebClient;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.util.List;
import reactor.core.publisher.Mono;

import java.util.Map;



@Service
@Slf4j
public class SupabaseStorageService {

    private final List<String> allowedContentTypes = List.of("image/jpeg", "image/png", "image/webp");

    private final WebClient webClient;

    @Value("${supabase.orderphotos-bucket-name}")
    private String userPhotosBucketName;

    @Value("${supabase.code}")
    private String supabaseCode;

    public SupabaseStorageService(@Qualifier("supabaseWebClient") WebClient webClient) {
        this.webClient = webClient;
        log.info("[SupabaseStorageService] Inicializado com bucket='{}', supabaseCode='{}'", userPhotosBucketName, supabaseCode);
    }

    public String uploadOrUpdateUserPhoto(MultipartFile file, String fileName) throws IOException {
        validateImage(file);

        final String fileUrl = "/storage/v1/object/" + userPhotosBucketName + "/" + fileName;
        log.info("Verificando se a imagem '{}' já existe no bucket '{}'", fileName, userPhotosBucketName);

        try {
            webClient.head()
                    .uri(fileUrl)
                    .retrieve()
                    .toBodilessEntity()
                    .block();

            log.info("Imagem '{}' encontrada no bucket '{}'. Realizando atualização...", fileName, userPhotosBucketName);
            return updateImage(file, fileName, userPhotosBucketName);

        } catch (Exception e) {
            log.info("Imagem '{}' não encontrada no bucket '{}'. Realizando upload... test: {}", fileName, userPhotosBucketName, supabaseCode);
            return uploadImage(file, fileName, userPhotosBucketName);
        }
    }

    private String updateImage(MultipartFile file, String fileName, String bucketName) throws IOException {
        final byte[] fileBytes = file.getBytes();
        String endpoint = "/storage/v1/object/" + bucketName + "/" + fileName;
        String contentType = file.getContentType();
        log.info("Atualizando imagem '{}' no bucket '{}', endpoint='{}', contentType='{}'", fileName, bucketName, endpoint, contentType);

        try {
            return webClient.put()
                    .uri(endpoint)
                    .header(HttpHeaders.CONTENT_TYPE, contentType)
                    .bodyValue(fileBytes)
                    .retrieve()
                    .bodyToMono(String.class)
                    .map(response -> "https://" + supabaseCode + ".supabase.co/storage/v1/object/public/" + bucketName + "/" + fileName)
                    .block();
        } catch (org.springframework.web.reactive.function.client.WebClientResponseException e) {
            log.error("[SupabaseStorageService] Erro ao atualizar imagem: status={}, body={}, endpoint={}, bucket={}, supabase_code: {}, fileName={}, contentType={}", e.getRawStatusCode(), e.getResponseBodyAsString(), endpoint, bucketName, supabaseCode, fileName, contentType);
            throw new RuntimeException("Erro ao atualizar imagem no Supabase", e);
        } catch (Exception e) {
            log.error("[SupabaseStorageService] Erro inesperado ao atualizar imagem: {} | endpoint={}, bucket={}, supabase_code: {} fileName={}, contentType={}", e.getMessage(), endpoint, bucketName, supabaseCode, fileName, contentType);
            throw new RuntimeException("Erro ao atualizar imagem no Supabase", e);
        }
    }

    private String uploadImage(MultipartFile file, String fileName, String bucketName) throws IOException {
        final byte[] fileBytes = file.getBytes();
        String endpoint = "/storage/v1/object/" + bucketName + "/" + fileName;
        String contentType = file.getContentType();
        log.info("Fazendo upload de imagem no Supabase Storage: {}, endpoint='{}', contentType='{}'", fileName, endpoint, contentType);

        try {
            return webClient.post()
                    .uri(endpoint)
                    .header(HttpHeaders.CONTENT_TYPE, contentType)
                    .bodyValue(fileBytes)
                    .retrieve()
                    .bodyToMono(String.class)
                    .map(response -> "https://" + supabaseCode + ".supabase.co/storage/v1/object/public/" + bucketName + "/"
                            + fileName)
                    .block();
        } catch (org.springframework.web.reactive.function.client.WebClientResponseException e) {
            log.error("[SupabaseStorageService] Erro ao fazer upload: status={}, body={}, endpoint={}, bucket={}, fileName={}, contentType={}", e.getRawStatusCode(), e.getResponseBodyAsString(), endpoint, bucketName, fileName, contentType);
            throw new RuntimeException("Erro ao enviar imagem para o Supabase", e);
        } catch (Exception e) {
            log.error("[SupabaseStorageService] Erro inesperado ao fazer upload: {} | endpoint={}, bucket={}, fileName={}, contentType={}", e.getMessage(), endpoint, bucketName, fileName, contentType);
            throw new RuntimeException("Erro ao enviar imagem para o Supabase", e);
        }
    }
    


    private void validateImage(MultipartFile file) throws IOException {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Arquivo de imagem está vazio ou é nulo.");
        }

        if (!allowedContentTypes.contains(file.getContentType())) {
            throw new IllegalArgumentException("Tipo de imagem inválido. Permitidos: JPEG, PNG ou WEBP.");
        }

        BufferedImage image;
        try {
            image = ImageIO.read(file.getInputStream());
            if (image == null) {
                throw new IllegalArgumentException("O arquivo enviado não é uma imagem válida.");
            }
        } catch (IOException e) {
            log.error("Erro ao ler o arquivo de imagem: {}", e.getMessage());
            throw new RuntimeException("Erro ao ler imagem enviada", e);
        }

        int width = image.getWidth();
        int height = image.getHeight();

        double ratio = (double) width / height;
        // if (ratio < 0.8 || ratio > 1.2) {
        //     throw new IllegalArgumentException("A imagem deve ser aproximadamente quadrada (razão entre largura e altura entre 0.8 e 1.2).");
        // }

        // if (width < 200 || height < 200) {
        //     throw new IllegalArgumentException("A imagem deve ter no mínimo 200x200 pixels.");
        // }

        // if (width > 2000 || height > 2000) {
        //     throw new IllegalArgumentException("A imagem excede o tamanho máximo permitido de 2000x2000 pixels.");
        // }
    }
}
