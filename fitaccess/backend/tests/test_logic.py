import unittest
from app.logic import aceptar


class DecisionTests(unittest.TestCase):
    def test_aceptado(self):
        self.assertTrue(aceptar(0.25, 0.26))
        self.assertTrue(aceptar(0.26, 0.26))

    def test_rechazado(self):
        self.assertFalse(aceptar(0.27, 0.26))
        self.assertFalse(aceptar(None, 0.26))


if __name__ == '__main__':
    unittest.main()
