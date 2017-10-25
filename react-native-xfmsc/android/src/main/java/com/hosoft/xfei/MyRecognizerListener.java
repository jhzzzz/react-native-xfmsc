package com.hosoft.xfei;

import android.os.Bundle;
import android.util.Log;

import com.facebook.react.bridge.Callback;
import com.iflytek.cloud.RecognizerListener;
import com.iflytek.cloud.RecognizerResult;
import com.iflytek.cloud.SpeechError;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONTokener;

/**
 * Created by xukankan on 17/3/15.
 * 创建监听器
 */

public class MyRecognizerListener {
    private static final String TAG = "xunfei";
    private static final String START = "start";
    private static final String END = "end";
    private static final String CHANGE = "change";
    private static final String ERROR = "error";

    private static StringBuffer ret = new StringBuffer();

    static public RecognizerListener createRecognizerListener(final Callback successCallback,final Callback errorCallback) {
        // 听写监听器
        RecognizerListener mRecoListener = new RecognizerListener() {
            // 听写结果回调接口 (返回Json 格式结果，用户可参见附录 13.1)；
            //一般情况下会通过onResults接口多次返回结果，完整的识别内容是多次结果的累加；
            // 关于解析Json的代码可参见 Demo中JsonParser 类；
            //isLast等于true 时会话结束。
            public void onResult(RecognizerResult results, boolean isLast) {
                try {
                    JSONTokener jsonParser = new JSONTokener(results.getResultString());
                    JSONObject joResult = new JSONObject(jsonParser);
                    JSONArray words = joResult.getJSONArray("ws");
                    for (int i = 0; i < words.length(); i++) {
                        JSONArray items = words.getJSONObject(i).getJSONArray("cw");
                        JSONObject obj = items.getJSONObject(0);
                        ret.append(obj.getString("w"));
                    }
                } catch (JSONException e) {
                    e.printStackTrace();
                    errorCallback.invoke("录音发生错误");
                }
                if (isLast) {
                    Log.v(TAG, ret.toString());
                    successCallback.invoke(ret.toString());
                }
            }

            // 会话发生错误回调接口
            public void onError(SpeechError error) {
                // 获取错误码描述
                Log.e(TAG, ERROR + error.getPlainDescription(true));
            }

            // 开始录音
            public void onBeginOfSpeech() {
                Log.v(TAG, START);
            }

            //volume 音量值0~30， data音频数据
            public void onVolumeChanged(int volume, byte[] data) {
                Log.v(TAG, CHANGE);
            }

            // 结束录音
            public void onEndOfSpeech() {
                Log.v(TAG, END);
            }

            // 扩展用接口
            public void onEvent(int eventType, int arg1, int arg2, Bundle obj) {
            }
        };
        return mRecoListener;
    }


}
