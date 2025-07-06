import { errorMessage } from '@/errors';
import { Injectable, Logger } from '@nestjs/common';
import * as sharp from 'sharp';

export interface ImageOptimizationOptions {
  width?: number;
  height?: number;
  quality?: number;
  format?: 'webp' | 'jpeg' | 'png';
}

interface CachedMetadata {
  width: number;
  height: number;
  format: string;
  timestamp: number;
}

@Injectable()
export class ImageOptimizerService {
  private readonly logger = new Logger(ImageOptimizerService.name);
  private readonly metadataCache = new Map<string, CachedMetadata>();
  private readonly CACHE_TTL = 5 * 60 * 1000; // 5 minutes

  constructor() {}

  /**
   * Détecte si le fichier est HEIC basé sur le nom de fichier
   */
  private isHeicByFilename(filename: string): boolean {
    const heicExtensions = ['.heic', '.heif', '.HEIC', '.HEIF'];
    return heicExtensions.some((ext) => filename.toLowerCase().endsWith(ext));
  }

  /**
   * Génère une clé de cache basée sur le hash du buffer
   */
  private getCacheKey(buffer: Buffer): string {
    // Hash simple pour éviter de stocker de gros buffers
    let hash = 0;
    for (let i = 0; i < Math.min(buffer.length, 1024); i++) {
      hash = ((hash << 5) - hash + buffer[i]) & 0xffffffff;
    }
    return hash.toString(16);
  }

  /**
   * Nettoie le cache expiré
   */
  private cleanExpiredCache(): void {
    const now = Date.now();
    for (const [key, metadata] of this.metadataCache.entries()) {
      if (now - metadata.timestamp > this.CACHE_TTL) {
        this.metadataCache.delete(key);
      }
    }
  }

  /**
   * Optimise une image avec Sharp (support HEIC natif)
   */
  async optimizeImage(
    buffer: Buffer,
    options: ImageOptimizationOptions = {},
    filename?: string,
  ): Promise<Buffer> {
    const {
      width = 800,
      height = 800,
      quality = 80,
      format = 'webp',
    } = options;

    this.logger.log(
      `Optimisation de l'image: ${filename || 'unknown'} (${
        buffer.length
      } bytes)`,
    );

    // Si c'est un HEIC, on le garde tel quel sans conversion
    if (filename && this.isHeicByFilename(filename)) {
      this.logger.log(
        `Fichier HEIC détecté - conservation du format original: ${filename}`,
      );
      return buffer; // Retourner le buffer original sans modification
    }

    try {
      this.logger.log(
        `Application de Sharp avec options: ${width}x${height}, qualité: ${quality}, format: ${format}`,
      );

      // Optimisations Sharp pour de meilleures performances
      const sharpInstance = sharp(buffer, {
        failOnError: false,
        limitInputPixels: 268402689,
        pages: -1,
        // Optimisations supplémentaires
        sequentialRead: true, // Lecture séquentielle pour de meilleures performances
        unlimited: false, // Limiter la mémoire utilisée
      });

      let pipeline = sharpInstance.rotate().resize({
        width,
        height,
        fit: 'inside',
        withoutEnlargement: true,
        kernel: sharp.kernel.lanczos3,
        // Optimisations de redimensionnement
        fastShrinkOnLoad: true, // Redimensionnement rapide pour les grandes images
      });

      switch (format) {
        case 'webp':
          pipeline = pipeline.webp({
            quality,
            effort: 2, // Réduit de 4 à 2 pour plus de vitesse (compromis qualité/vitesse)
            nearLossless: false,
            smartSubsample: true,
            // Optimisations WebP
            lossless: false,
            mixed: false,
          });
          break;
        case 'jpeg':
          pipeline = pipeline.jpeg({
            quality,
            progressive: true,
            mozjpeg: true,
            // Optimisations JPEG
            trellisQuantisation: false, // Désactivé pour la vitesse
            overshootDeringing: false, // Désactivé pour la vitesse
            optimizeScans: false, // Désactivé pour la vitesse
          });
          break;
        case 'png':
          pipeline = pipeline.png({
            quality,
            progressive: true,
            compressionLevel: 4, // Réduit de 6 à 4 pour plus de vitesse
            // Optimisations PNG
            adaptiveFiltering: false, // Désactivé pour la vitesse
            palette: false,
          });
          break;
      }

      const result = await pipeline.toBuffer();

      this.logger.log(
        `Optimisation terminée: ${filename || 'unknown'} (${
          result.length
        } bytes -> ${buffer.length} bytes)`,
      );
      return result;
    } catch (error) {
      this.logger.error(`Erreur lors de l'optimisation: ${error.message}`);
      throw new Error(errorMessage.api('media').INVALID_FORMAT);
    }
  }

  /**
   * Génère une vignette pour les aperçus
   */
  async generateThumbnail(
    buffer: Buffer,
    size: number = 200,
    filename?: string,
  ): Promise<Buffer> {
    // Si c'est un HEIC, on le garde tel quel
    if (filename && this.isHeicByFilename(filename)) {
      return buffer; // Retourner le buffer original
    }

    try {
      return await sharp(buffer, {
        failOnError: false,
        limitInputPixels: 268402689,
        sequentialRead: true,
        unlimited: false,
      })
        .rotate()
        .resize({
          width: size,
          height: size,
          fit: 'cover',
          position: 'center',
          fastShrinkOnLoad: true,
        })
        .webp({
          quality: 70,
          effort: 1, // Effort minimal pour les vignettes
        })
        .toBuffer();
    } catch (error) {
      throw new Error(errorMessage.api('media').INVALID_FORMAT);
    }
  }

  /**
   * Vérifie si le buffer contient une image valide (avec cache)
   */
  async validateImage(buffer: Buffer, filename?: string): Promise<boolean> {
    try {
      // Si c'est un HEIC, on considère qu'il est valide
      if (filename && this.isHeicByFilename(filename)) {
        return true;
      }

      // Nettoyer le cache expiré
      this.cleanExpiredCache();

      const cacheKey = this.getCacheKey(buffer);
      const cached = this.metadataCache.get(cacheKey);

      if (cached && Date.now() - cached.timestamp < this.CACHE_TTL) {
        return !!cached.width && !!cached.height;
      }

      const metadata = await sharp(buffer).metadata();
      const isValid = !!metadata.width && !!metadata.height;

      // Mettre en cache
      if (isValid) {
        this.metadataCache.set(cacheKey, {
          width: metadata.width,
          height: metadata.height,
          format: metadata.format,
          timestamp: Date.now(),
        });
      }

      return isValid;
    } catch (error) {
      return false;
    }
  }

  /**
   * Obtient les métadonnées de l'image (avec cache)
   */
  async getImageMetadata(buffer: Buffer, filename?: string) {
    try {
      // Si c'est un HEIC, on ne peut pas lire les métadonnées avec Sharp
      if (filename && this.isHeicByFilename(filename)) {
        return {
          format: 'heic',
          width: null,
          height: null,
          channels: null,
          depth: null,
          density: null,
          hasProfile: false,
          hasAlpha: false,
          orientation: null,
          isOpaque: true,
        };
      }

      // Nettoyer le cache expiré
      this.cleanExpiredCache();

      const cacheKey = this.getCacheKey(buffer);
      const cached = this.metadataCache.get(cacheKey);

      if (cached && Date.now() - cached.timestamp < this.CACHE_TTL) {
        return {
          format: cached.format,
          width: cached.width,
          height: cached.height,
          channels: null,
          depth: null,
          density: null,
          hasProfile: false,
          hasAlpha: false,
          orientation: null,
          isOpaque: true,
        };
      }

      const metadata = await sharp(buffer).metadata();

      // Mettre en cache
      this.metadataCache.set(cacheKey, {
        width: metadata.width,
        height: metadata.height,
        format: metadata.format,
        timestamp: Date.now(),
      });

      return metadata;
    } catch (error) {
      throw new Error(errorMessage.api('media').INVALID_FORMAT);
    }
  }

  /**
   * Optimise plusieurs images en parallèle
   */
  async optimizeImages(
    images: Array<{
      buffer: Buffer;
      options?: ImageOptimizationOptions;
      filename?: string;
    }>,
  ): Promise<Buffer[]> {
    return Promise.all(
      images.map(({ buffer, options, filename }) =>
        this.optimizeImage(buffer, options, filename),
      ),
    );
  }
}
