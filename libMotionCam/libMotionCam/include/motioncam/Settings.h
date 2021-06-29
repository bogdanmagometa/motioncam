#ifndef Settings_h
#define Settings_h

#include <json11/json11.hpp>

namespace motioncam {
    float getSetting(const json11::Json& json, const std::string& key, const float defaultValue);
    int getSetting(const json11::Json& json, const std::string& key, const int defaultValue);
    bool getSetting(const json11::Json& json, const std::string& key, const bool defaultValue);
    std::string getSetting(const json11::Json& json, const std::string& key, const std::string& defaultValue);

    struct PostProcessSettings {
        // Denoising
        float spatialDenoiseAggressiveness;

        // Post processing
        float temperature;
        float tint;

        float gamma;
        float tonemapVariance;
        float shadows;
        float whitePoint;
        float contrast;
        float sharpen0;
        float sharpen1;
        float blacks;
        float exposure;
        
        float noiseSigma;
        float sceneLuminance;
        
        float saturation;
        float blues;
        float greens;
        
        int jpegQuality;
        bool flipped;
        bool dng;

        float gpsLatitude;
        float gpsLongitude;
        float gpsAltitude;
        std::string gpsTime;

        std::string captureMode;

        PostProcessSettings() :
            spatialDenoiseAggressiveness(1.0f),
            temperature(-1),
            tint(-1),
            gamma(2.2f),
            tonemapVariance(0.25f),
            shadows(1.0f),
            exposure(0.0f),
            noiseSigma(0.0f),
            sceneLuminance(0.0f),
            contrast(0.5f),
            sharpen0(4.0f),
            sharpen1(3.0f),
            blacks(0.0f),
            whitePoint(1.0f),
            saturation(1.0f),
            blues(8.0f),
            greens(8.0f),
            jpegQuality(95),
            flipped(false),
            dng(false),
            gpsLatitude(0),
            gpsLongitude(0),
            gpsAltitude(0)
        {
        }
        
        PostProcessSettings(const json11::Json& json) : PostProcessSettings() {
            spatialDenoiseAggressiveness    = getSetting(json, "spatialDenoiseAggressiveness",  spatialDenoiseAggressiveness);
            
            tonemapVariance                 = getSetting(json, "tonemapVariance",   tonemapVariance);

            gamma                           = getSetting(json, "gamma",             gamma);
            temperature                     = getSetting(json, "temperature",       temperature);
            tint                            = getSetting(json, "tint",              tint);
            shadows                         = getSetting(json, "shadows",           shadows);
            whitePoint                      = getSetting(json, "whitePoint",        whitePoint);
            contrast                        = getSetting(json, "contrast",          contrast);
            exposure                        = getSetting(json, "exposure",          exposure);
            blacks                          = getSetting(json, "blacks",            blacks);
            
            noiseSigma                      = getSetting(json, "noiseSigma",        noiseSigma);
            sceneLuminance                  = getSetting(json, "sceneLuminance",    sceneLuminance);

            sharpen0                        = getSetting(json, "sharpen0",          sharpen0);
            sharpen1                        = getSetting(json, "sharpen1",          sharpen1);

            saturation                      = getSetting(json, "saturation",        saturation);
            blues                           = getSetting(json, "blues",             blues);
            greens                          = getSetting(json, "greens",            greens);
            
            jpegQuality                     = getSetting(json, "jpegQuality",       jpegQuality);
            flipped                         = getSetting(json, "flipped",       	flipped);
            dng                             = getSetting(json, "dng",       	    dng);
            
            gpsLatitude                     = getSetting(json, "gpsLatitude",       gpsLatitude);
            gpsLongitude                    = getSetting(json, "gpsLongitude",      gpsLongitude);
            gpsAltitude                     = getSetting(json, "gpsAltitude",       gpsAltitude);
            gpsTime                         = getSetting(json, "gpsTime",           gpsTime);

            captureMode                     = getSetting(json, "captureMode",       captureMode);
        }
        
        json11::Json toJson() const {
            json11::Json::object json;
            
            json["spatialDenoiseAggressiveness"]    = spatialDenoiseAggressiveness;
            json["gamma"]                           = gamma;
            json["tonemapVariance"]                 = tonemapVariance;
            json["shadows"]                         = shadows;
            json["whitePoint"]                      = whitePoint;
            json["contrast"]                        = contrast;
            json["sharpen0"]                        = sharpen0;
            json["sharpen1"]                        = sharpen1;
            json["blacks"]                          = blacks;
            json["exposure"]                        = exposure;
            json["temperature"]                     = temperature;
            json["tint"]                            = tint;
            
            json["noiseSigma"]                      = noiseSigma;
            json["sceneLuminance"]                  = sceneLuminance;
            
            json["saturation"]                      = saturation;
            json["blues"]                           = blues;
            json["greens"]                          = greens;

            json["jpegQuality"]                     = jpegQuality;
            json["flipped"]                         = flipped;
            json["dng"]                             = dng;

            json["gpsLatitude"]                     = gpsLatitude;
            json["gpsLongitude"]                    = gpsLongitude;
            json["gpsAltitude"]                     = gpsAltitude;
            json["gpsTime"]                         = gpsTime;

            json["captureMode"]                     = captureMode;

            return json;
        }
    };
}

#endif /* Settings_h */
