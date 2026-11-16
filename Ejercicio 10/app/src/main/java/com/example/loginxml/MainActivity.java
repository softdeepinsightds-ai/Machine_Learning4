package com.example.loginxml;

import android.app.Activity;
import android.os.Bundle;
import android.util.Patterns;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;

/**
 * Muestra el formulario de inicio de sesión y valida sus datos localmente.
 *
 * Esta pantalla es una demostración: no autentica usuarios ni se conecta a un servidor.
 */
public class MainActivity extends Activity {

    private EditText emailInput;
    private EditText passwordInput;

    /**
     * Infla la pantalla y conecta el botón con la validación del formulario.
     *
     * @param savedInstanceState estado anterior de la actividad, si Android la recrea
     */
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        emailInput = findViewById(R.id.edtUsuario);
        passwordInput = findViewById(R.id.edtPassword);
        android.widget.Button loginButton = findViewById(R.id.btnIngresar);
        loginButton.setOnClickListener(view -> validateAndSubmit());
    }

    /**
     * Comprueba que el correo tenga un formato válido y que la contraseña no esté vacía.
     *
     * Los errores de correo y contraseña se muestran junto al campo correspondiente.
     * Un dato vacío o un correo con formato incorrecto nunca se trata como válido.
     * El mensaje de demostración solo aparece cuando ambos datos pasan la validación local.
     */
    private void validateAndSubmit() {
        String email = emailInput.getText().toString().trim();
        String password = passwordInput.getText().toString();
        boolean hasError = false;

        if (email.isEmpty()) {
            emailInput.setError(getString(R.string.error_email_required));
            emailInput.requestFocus();
            hasError = true;
        } else if (!Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
            emailInput.setError(getString(R.string.error_email_invalid));
            emailInput.requestFocus();
            hasError = true;
        } else {
            emailInput.setError(null);
        }

        if (password.trim().isEmpty()) {
            passwordInput.setError(getString(R.string.error_password_required));
            if (!hasError) {
                passwordInput.requestFocus();
            }
            hasError = true;
        } else {
            passwordInput.setError(null);
        }

        if (hasError) {
            return;
        }

        Toast.makeText(this, R.string.login_demo_success, Toast.LENGTH_SHORT).show();
    }
}
