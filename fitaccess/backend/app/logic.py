"""Regla de decisión del notebook: distancia mínima <= umbral."""

def aceptar(distancia: float | None, umbral: float) -> bool:
    return distancia is not None and 0 <= distancia <= umbral
