import React from 'react';
import { Colors } from 'react-native/Libraries/NewAppScreen';

import {
  Button,
  SafeAreaView,
  StatusBar,
  StyleSheet,
  Text,
  TextInput,
  useColorScheme,
  View
} from 'react-native';

const SettingView= ({ navigation }) => {

    const isDarkMode = useColorScheme() === 'dark';
    const backgroundStyle = { backgroundColor: isDarkMode ? Colors.darker : Colors.lighter };
  
    return (
        <SafeAreaView style={[backgroundStyle, { flex: 1 }]}>
            <StatusBar barStyle={isDarkMode ? 'light-content' : 'dark-content'} />  
            <View>
                <TextInput />
            </View>
        </SafeAreaView>
    )
};

export default SettingView;