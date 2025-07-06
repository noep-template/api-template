import { Injectable } from '@nestjs/common';
import { ImageOptimizationOptions } from './image-optimizer.service';

export interface OptimizationProfile {
  name: string;
  width: number;
  height: number;
  quality: number;
  format: 'webp' | 'jpeg' | 'png';
  effort: number;
  compressionLevel?: number;
}

@Injectable()
export class OptimizationConfigService {
  private readonly profiles: Map<string, OptimizationProfile> = new Map([
    [
      'thumbnail',
      {
        name: 'thumbnail',
        width: 200,
        height: 200,
        quality: 70,
        format: 'webp',
        effort: 1,
      },
    ],
    [
      'small',
      {
        name: 'small',
        width: 400,
        height: 400,
        quality: 75,
        format: 'webp',
        effort: 2,
      },
    ],
    [
      'medium',
      {
        name: 'medium',
        width: 800,
        height: 800,
        quality: 80,
        format: 'webp',
        effort: 2,
      },
    ],
    [
      'large',
      {
        name: 'large',
        width: 1200,
        height: 1200,
        quality: 85,
        format: 'webp',
        effort: 3,
      },
    ],
    [
      'original',
      {
        name: 'original',
        width: 1920,
        height: 1920,
        quality: 90,
        format: 'webp',
        effort: 4,
      },
    ],
  ]);

  /**
   * Détermine le profil d'optimisation optimal selon la taille du fichier
   */
  getOptimalProfile(fileSizeBytes: number): OptimizationProfile {
    const fileSizeMB = fileSizeBytes / (1024 * 1024);

    if (fileSizeMB < 0.5) {
      return this.profiles.get('small');
    } else if (fileSizeMB < 2) {
      return this.profiles.get('medium');
    } else if (fileSizeMB < 10) {
      return this.profiles.get('large');
    } else {
      return this.profiles.get('original');
    }
  }

  /**
   * Convertit un profil en options Sharp
   */
  profileToOptions(profile: OptimizationProfile): ImageOptimizationOptions {
    return {
      width: profile.width,
      height: profile.height,
      quality: profile.quality,
      format: profile.format,
    };
  }

  /**
   * Obtient un profil par nom
   */
  getProfile(name: string): OptimizationProfile | undefined {
    return this.profiles.get(name);
  }

  /**
   * Ajoute ou met à jour un profil personnalisé
   */
  setProfile(profile: OptimizationProfile): void {
    this.profiles.set(profile.name, profile);
  }

  /**
   * Obtient tous les profils disponibles
   */
  getAllProfiles(): OptimizationProfile[] {
    return Array.from(this.profiles.values());
  }

  /**
   * Détermine si une image doit être optimisée selon sa taille
   */
  shouldOptimize(
    fileSizeBytes: number,
    originalWidth?: number,
    originalHeight?: number,
  ): boolean {
    const fileSizeMB = fileSizeBytes / (1024 * 1024);

    // Toujours optimiser les gros fichiers
    if (fileSizeMB > 5) return true;

    // Optimiser si l'image est très grande
    if (originalWidth && originalHeight) {
      const totalPixels = originalWidth * originalHeight;
      if (totalPixels > 4000000) return true; // Plus de 4MP
    }

    // Optimiser les fichiers moyens
    if (fileSizeMB > 1) return true;

    return false;
  }

  /**
   * Calcule le ratio de compression estimé
   */
  estimateCompressionRatio(
    originalSize: number,
    profile: OptimizationProfile,
  ): number {
    const qualityFactor = profile.quality / 100;
    const sizeFactor = (profile.width * profile.height) / (1920 * 1080); // Référence Full HD

    return Math.min(0.9, qualityFactor * sizeFactor);
  }
}
