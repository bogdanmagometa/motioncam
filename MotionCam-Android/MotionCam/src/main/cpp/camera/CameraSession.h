#ifndef MOTIONCAM_ANDROID_CAMERASESSION_H
#define MOTIONCAM_ANDROID_CAMERASESSION_H

#include "CameraDescription.h"
#include "CameraSessionState.h"

#include <motioncam/RawImageMetadata.h>
#include <motioncam/Settings.h>

#include <vector>
#include <string>
#include <map>
#include <mutex>

#include <android/native_window.h>
#include <camera/NdkCameraCaptureSession.h>
#include <camera/NdkCameraManager.h>
#include <media/NdkImageReader.h>
#include <queue/blockingconcurrentqueue.h>

namespace motioncam {
    class RawImageConsumer;
    class CameraSessionListener;

    struct RawImageBuffer;
    struct CameraCaptureSessionContext;
    struct CaptureCallbackContext;
    struct EventLoopData;
    class CameraStateManager;
    enum class EventAction : int;

    typedef std::shared_ptr<EventLoopData> EventLoopDataPtr;

    class CameraSession {
    public:
        CameraSession(
                std::shared_ptr<CameraSessionListener> listener,
                std::shared_ptr<CameraDescription> cameraDescription,
                std::shared_ptr<RawImageConsumer> rawImageConsumer);

        ~CameraSession();

        void openCamera(
            const OutputConfiguration& rawOutputConfig,
            std::shared_ptr<ACameraManager> cameraManager,
            std::shared_ptr<ANativeWindow> previewOutputWindow,
            bool setupForRawPreview);

        void closeCamera();

        void pauseCapture();
        void resumeCapture();

        void setAutoExposure();
        void setManualExposure(int32_t iso, int64_t exposureTime);
        void setExposureCompensation(float value);
        void captureHdr(
                int numImages,
                int baseIso,
                int64_t baseExposure,
                int hdrIso,
                int64_t hdrExposure,
                const PostProcessSettings& postprocessSettings,
                const std::string& outputPath);

        void updateOrientation(ScreenOrientation orientation);

        void setFocusPoint(float focusX, float focusY, float exposureX, float exposureY);
        void setAutoFocus();

        void pushEvent(const EventAction event, const json11::Json& data);
        void pushEvent(const EventAction event);

    public:
        // Callbacks
        void onCameraError(int error);
        void onCameraDisconnected();

        void onCameraSessionStateActive();
        void onCameraSessionStateReady();
        void onCameraSessionStateClosed();

        void onCameraCaptureStarted(const CaptureCallbackContext& context, const ACaptureRequest* request, int64_t timestamp);
        void onCameraCaptureProgressed(const CaptureCallbackContext& context, const ACameraMetadata* result);
        void onCameraCaptureBufferLost(const CaptureCallbackContext& context, int64_t frameNumber);
        void onCameraCaptureCompleted(const CaptureCallbackContext& context, const ACameraMetadata* result);
        void onCameraCaptureFailed(const CaptureCallbackContext& context, ACameraCaptureFailure* failure);
        void onCameraCaptureSequenceCompleted(const CaptureCallbackContext& context, const int sequenceId);
        void onCameraCaptureSequenceAborted(const CaptureCallbackContext& context, int sequenceId);

        void onRawImageAvailable(AImageReader* imageReader);

    private:
        void doEventLoop();
        void doProcessEvent(const EventLoopDataPtr& eventLoopData);

        void doOpenCamera(bool setupForRawPreview);
        void doCloseCamera();
        void doPauseCapture();
        void doResumeCapture();

        void doOnCameraError(int error);
        void doOnCameraDisconnected();
        void doOnCameraSessionStateChanged(const CameraCaptureSessionState state);

        void doOnCameraExposureStatusChanged(int32_t iso, int64_t exposureTime);
        void doCameraAutoExposureStateChanged(CameraExposureState state);
        void doCameraAutoFocusStateChanged(CameraFocusState state);

        void doOnInternalError(const std::string& e);

        void doSetAutoExposure();
        void doSetManualExposure(int32_t iso, int64_t exposureTime);
        void doSetFocusPoint(double focusX, double focusY, double exposureX, double exposureY);
        void doSetAutoFocus();
        void doSetExposureCompensation(float value);
        void doAttemptSaveHdrData();
        void doCaptureHdr(int numImages, int baseIso, int64_t baseExposure, int hdrIso, int64_t hdrExposure);

        void setupCallbacks();
        std::shared_ptr<CaptureCallbackContext> createCaptureCallbacks(const CaptureEvent event);

        ACaptureRequest* createCaptureRequest(const ACameraDevice_request_template requestTemplate);

        void setupRawCaptureOutput(CameraCaptureSessionContext& state);
        void setupJpegCaptureOutput(CameraCaptureSessionContext& state);
        void setupPreviewCaptureOutput(CameraCaptureSessionContext& state, bool enableCameraPreview);

    private:
        CameraCaptureSessionState mState;
        int32_t mLastIso;
        int64_t mLastExposureTime;
        CameraFocusState mLastFocusState;
        CameraExposureState mLastExposureState;
        std::atomic<ScreenOrientation> mScreenOrientation;
        std::atomic<bool> mHdrCaptureInProgress;
        std::atomic<bool> mHdrCaptureSequenceCompleted;
        std::chrono::steady_clock::time_point mHdrSequenceCompletedTimePoint;
        PostProcessSettings mHdrCaptureSettings;
        std::string mHdrCaptureOutputPath;
        int mRequestedHdrCaptures;
        int64_t mRequestHdrCaptureTimestamp;
        int mSaveHdrCaptures;
        bool mPartialHdrCapture;

        moodycamel::BlockingConcurrentQueue<EventLoopDataPtr> mEventLoopQueue;
        std::unique_ptr<std::thread> mEventLoopThread;

        std::shared_ptr<CameraDescription> mCameraDescription;
        std::shared_ptr<RawImageConsumer> mImageConsumer;
        std::shared_ptr<CameraCaptureSessionContext> mSessionContext;
        std::shared_ptr<CameraSessionListener> mSessionListener;
        std::unique_ptr<CameraStateManager> mCameraStateManager;
    };
}

#endif //MOTIONCAM_ANDROID_CAMERASESSION_H
