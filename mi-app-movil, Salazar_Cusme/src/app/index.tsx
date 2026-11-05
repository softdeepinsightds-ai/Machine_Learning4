import * as Device from 'expo-device';
import { Platform } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { AnimatedIcon } from '@/components/animated-icon';
import { HintRow } from '@/components/hint-row';
import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';
import { WebBadge } from '@/components/web-badge';
import { BottomTabInset, MaxContentWidth, Spacing } from '@/constants/theme';

import { useState } from 'react';
import { StyleSheet, Text, View, Button } from 'react-native';

export default function App() {
  const [contador, setContador] = useState(0);
  return (
    // <View> reemplaza al <div>
    <View style={styles.contenedor}>
      {/* <Text> reemplaza al <h1> y <p> */}
      <Text style={styles.titulo}>Mi Contador Móvil en React Native</Text>
      <Text style={styles.texto}>El valor actual es: {contador}</Text>

      <Button
        title="Sumar +1"
        onPress={() => setContador(contador + 1)}
      />
    </View>
  );
}
// En React Native no hay CSS, se usa un objeto JavaScript (StyleSheet)
const styles = StyleSheet.create({
  contenedor: {
    flex: 1,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
  },
  titulo: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
    color: '#61DAFB',
    textAlign: 'center'
  },
  texto: {
    fontSize: 18,
    marginBottom: 20,
  }
});
