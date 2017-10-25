/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */

import {NativeModules, NativeEventEmitter,ScrollView} from 'react-native';
import React, {Component} from 'react';
import XfeiModule from 'react-native-xfmsc';

import {
    Platform,
    StyleSheet,
    TouchableOpacity,
    Text,
    TextInput,
    View
} from 'react-native';

const instructions = Platform.select({
    ios: 'Press Cmd+R to reload,\n' +
    'Cmd+D or shake for dev menu',
    android: 'Double tap R on your keyboard to reload,\n' +
    'Shake or press menu button for dev menu',
});

export default class App extends Component<{}> {
    constructor() {
        super();

        this.state = {
            evalResult:[]
        }
    }

    onClickStart() {
        console.log('onClickStart');

        XfeiModule.startRecord("你好，吃过了吗", 'read_syllable')
    };

    onClickStop() {
        console.log('onClickStop');
        XfeiModule.stopRecord();
    };

    onISECallback =(body) => {
        var json = JSON.stringify(body);
        console.log(json);

        let state = this.state;

        state.evalResult.push(json);
        this.setState({
            evalResult:state.evalResult
        })

    };

    componentWillMount() {
        const moduleEvent = new NativeEventEmitter(XfeiModule);
        this.listener = moduleEvent.addListener('onISECallback', this.onISECallback);  //对应了原生端的名字
    };

    componentWillUnmount() {
        this.listener && this.listener.remove();  //记得remove哦
        this.listener = null;
    };

    render() {
        return (
            <View style={styles.container}>
                <Text style={styles.welcome}>
                    科大讯飞语音评测（中文）React Native 组件示例
                    This is an example of iFLYTEK Speech Evaluation(Chinese)
                </Text>
                <TouchableOpacity
                    style={styles.btn}
                    onPress={this.onClickStart.bind(this)}>
                    <Text style={styles.btn_text}>Start Record</Text>
                </TouchableOpacity>
                <TouchableOpacity
                    style={styles.btn}
                    onPress={this.onClickStop.bind(this)}>
                    <Text style={styles.btn_text}>Stop Record</Text>
                </TouchableOpacity>

                <ScrollView style={styles.resultView}>
                    {
                        this.state.evalResult.map((o,i)=>{
                            return (
                                <Text key={i}>{o}</Text>
                            );
                        })
                    }
                </ScrollView>
                <Text style={styles.instructions}>
                    {instructions}
                </Text>
            </View>
        );
    }
}

const styles = StyleSheet.create({
    btn: {
        width: '50%',
        height: 50,
        alignItems: 'center',
        justifyContent: 'center',
        alignSelf: 'center',
        backgroundColor:'#0000ff',
        borderRadius:5,
        marginBottom:5
    },
    btn_text: {
        color: '#ffffff',
    },
    container: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        backgroundColor: '#F5FCFF',
    },
    welcome: {
        fontSize: 20,
        textAlign: 'center',
        margin: 10,
        marginBottom: 30,
    },
    instructions: {
        textAlign: 'center',
        color: '#333333',
        marginBottom: 10,
        marginTop: 20,
    },
    resultView:{
        height:200,
        width: '98%',
        borderWidth:1,
        marginLeft: 5,
        paddingLeft:5,
        borderColor: '#ccc',
        borderRadius: 4,
        marginTop: 20,
    },
});
