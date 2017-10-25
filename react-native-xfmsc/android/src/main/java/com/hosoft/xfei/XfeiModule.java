package com.hosoft.xfei;

import android.content.Context;
import android.os.Bundle;
import android.os.Environment;
import android.support.annotation.Nullable;
import android.util.Log;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.iflytek.cloud.EvaluatorListener;
import com.iflytek.cloud.EvaluatorResult;
import com.iflytek.cloud.SpeechConstant;
import com.iflytek.cloud.SpeechError;
import com.iflytek.cloud.SpeechEvaluator;

/**
 * Created by Jack Zhang on 17/10/19.
 */

public class XfeiModule extends ReactContextBaseJavaModule {
    private static String TAG = XfeiModule.class.getSimpleName();
    private static String name = "XfeiModule";

    // 评测语种
    private String language;
    // 评测题型
    private String category;
    // 结果等级
    private String result_level;

    private String mLastResult;
    private SpeechEvaluator mIse = null;

    // 评测监听接口
    private EvaluatorListener mEvaluatorListener = new EvaluatorListener() {

        @Override
        public void onResult(EvaluatorResult result, boolean isLast) {
            Log.d(TAG, "evaluator result :" + isLast);

            if (isLast) {
                StringBuilder builder = new StringBuilder();
                builder.append(result.getResultString());
                callback("result", "eval finished success", builder.toString());

                Log.d(TAG, "评测结束");
            } else {
                Log.d(TAG, "收到评测中间结果");
            }
        }

        @Override
        public void onError(SpeechError error) {
            if(error != null) {
                callback("error", "", error.getErrorCode() + "|" + error.getErrorDescription());
            } else {
                Log.d(TAG, "evaluator over");
            }
        }

        @Override
        public void onBeginOfSpeech() {
            // 此回调表示：sdk内部录音机已经准备好了，用户可以开始语音输入
            Log.d(TAG, "evaluator begin");
            callback("pleaseSpeak", "", "");
        }

        @Override
        public void onEndOfSpeech() {
            // 此回调表示：检测到了语音的尾端点，已经进入识别过程，不再接受语音输入
            Log.d(TAG, "evaluator stoped");
            callback("stopSpeak", "", "");
        }

        @Override
        public void onVolumeChanged(int volume, byte[] data) {
            //Log.d(TAG, "返回音频数据："+data.length);
            callback("volumn", "录音音量", volume+"");
        }

        public void onEvent(int eventType, int arg1, int arg2, Bundle obj) {
            // 以下代码用于获取与云端的会话id，当业务出错时将会话id提供给技术支持人员，可用于查询会话日志，定位出错原因
            //	if (SpeechEvent.EVENT_SESSION_ID == eventType) {
            //		String sid = obj.getString(SpeechEvent.KEY_EVENT_SESSION_ID);
            //		Log.d(TAG, "session id =" + sid);
            //	}
        }
    };

    public XfeiModule(ReactApplicationContext reactContext) {
        super(reactContext);
        //SpeechUtility.createUtility(this, SpeechConstant.APPID + "=58c77ca8");
        this.initSpeechEvaluator(reactContext);
    }

    @Override
    public String getName() {
        return "XfeiModule";
    }

    @ReactMethod
    public void setParameter(String key, String value) {
        if (mIse != null) {
            mIse.setParameter(key, value);
        }
    }

    @ReactMethod
    public void startRecord(String evalPaper, String category) {
        Log.d(TAG, "startRecord IN");

        if (mIse != null) {
            if (mIse.isEvaluating()) {
                return;
            }

            callback("file", "", getRecordFilePath());
            mIse.setParameter(SpeechConstant.ISE_CATEGORY, category);
            mIse.startEvaluating(evalPaper, null, mEvaluatorListener);
        }

        Log.d(TAG, "startRecord OUT");
    }

    @ReactMethod
    public void stopRecord() {
        Log.d(TAG, "stopRecord IN");

        if (mIse != null && mIse.isEvaluating()) {
            mIse.stopEvaluating();
        }

        Log.d(TAG, "stopRecord OUT");
    }

    @ReactMethod
    public void cancel() {
        Log.d(TAG, "cancel IN");

        if (mIse != null && mIse.isEvaluating()) {
            mIse.cancel();
        }

        Log.d(TAG, "cancel OUT");
    }

    /**
     * below private functions
     */
    private void initSpeechEvaluator(Context context) {
        if (mIse == null) {
            mIse = SpeechEvaluator.createEvaluator(context, null);
        }

        // 设置评测语言
        mIse.setParameter(SpeechConstant.LANGUAGE, "zh_cn");
        // 评测试卷文本格式
        mIse.setParameter(SpeechConstant.TEXT_ENCODING, "utf-8");
        // 设置语音前端点:静音超时时间，即用户多长时间不说话则当做超时处理
        mIse.setParameter(SpeechConstant.VAD_BOS, "5000");
        // 设置语音后端点:后端点静音检测时间，即用户停止说话多长时间内即认为不再输入， 自动停止录音
        mIse.setParameter(SpeechConstant.VAD_EOS, "3000");
        mIse.setParameter(SpeechConstant.KEY_SPEECH_TIMEOUT, "300000");
        mIse.setParameter(SpeechConstant.RESULT_LEVEL, "complete");

        // 设置音频保存路径，保存音频格式支持pcm、wav，设置路径为sd卡请注意WRITE_EXTERNAL_STORAGE权限
        // 注：AUDIO_FORMAT参数语记需要更新版本才能生效
        mIse.setParameter(SpeechConstant.AUDIO_FORMAT,"wav");
        mIse.setParameter(SpeechConstant.ISE_AUDIO_PATH, getRecordFilePath());
    }

    private String getRecordFilePath() {
        //return Environment.getExternalStorageDirectory().getAbsolutePath() + "/msc/ise.wav";
        return this.getReactApplicationContext().getFilesDir().getAbsolutePath() + "/msc/ise.wav";
    }

    private void sendEvent(ReactContext reactContext, String eventName, @Nullable WritableMap params) {
        reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                    .emit(eventName, params);
    }

    private void callback(String type, String msg, String data) {
        WritableMap params = Arguments.createMap();
        params.putString("type", type);
        params.putString("msg", msg);
        params.putString("data", data);

        sendEvent(this.getReactApplicationContext(), "onISECallback", params);
    }
}
