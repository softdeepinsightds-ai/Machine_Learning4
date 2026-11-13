"""Comprobacion estructural de cedulas ecuatorianas de persona natural.

NO verifica existencia, titularidad ni vigencia del documento.
"""
import re


def validar_cedula_ecuador(cedula: str) -> bool:
    if not isinstance(cedula, str) or not re.fullmatch(r"[0-9]{10}", cedula):
        return False

    provincia = int(cedula[:2])
    if not 1 <= provincia <= 24:
        return False
    if int(cedula[2]) > 5:
        return False

    digitos = [int(c) for c in cedula]
    coeficientes = (2, 1, 2, 1, 2, 1, 2, 1, 2)
    total = 0
    for digito, coef in zip(digitos[:9], coeficientes):
        producto = digito * coef
        total += producto - 9 if producto >= 10 else producto
    verificador = (10 - total % 10) % 10
    return verificador == digitos[9]
