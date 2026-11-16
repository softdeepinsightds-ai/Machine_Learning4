import React from 'react';
import { StyleSheet, Text, View, Platform, TouchableOpacity, Alert } from 'react-native';

export default function Web() {

  const handlePress = () => {
    if (Platform.OS === 'web') {
      window.alert('¡Hola desde el Navegador Web!');
    } else {
      Alert.alert('¡Hola!', 'Mensaje desde un dispositivo Móvil');
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>React Native Universal</Text>
      <Text style={styles.subtitle}>
        Estás ejecutando esta app en: {Platform.OS.toUpperCase()}
      </Text>

      <View style={styles.card}>
        <Text style={styles.cardText}>
          Esta tarjeta utiliza sombras y bordes que se traducen automáticamente a CSS en la web y a elevación nativa en Android.
        </Text>
        <TouchableOpacity style={styles.button} onPress={handlePress}>
          <Text style={styles.buttonText}>TÓCAME</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F5FCFF',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#61dafb',
    marginBottom: 10,
  },
  subtitle: {
    fontSize: 18,
    color: '#333',
    marginBottom: 30,
  },
  card: {
    backgroundColor: 'white',
    padding: 20,
    borderRadius: 15,
    width: Platform.OS === 'web' ? '50%' : '90%', // Diseño responsivo simple
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 10,
    elevation: 5,
  },
  cardText: {
    fontSize: 16,
    textAlign: 'center',
    marginBottom: 20,
    color: '#555',
  },
  button: {
    backgroundColor: '#282c34',
    paddingVertical: 12,
    paddingHorizontal: 25,
    borderRadius: 25,
  },
  buttonText: {
    color: '#61dafb',
    fontWeight: 'bold',
    fontSize: 16,
  }
});
