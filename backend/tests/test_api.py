import importlib.util
from pathlib import Path
import unittest
from unittest.mock import Mock, patch

spec = importlib.util.spec_from_file_location('goodie_api', Path(__file__).parents[1] / 'app.py')
api = importlib.util.module_from_spec(spec)
spec.loader.exec_module(api)

class ApiTests(unittest.TestCase):
    def setUp(self):
        self.client = api.app.test_client()
        self.payload = dict(store='Test branch', store_type='Urban', product='Rice', category='Groceries',
            price=50, cost_price=30, discount=0, holiday='No', weekend='No', day_of_week='Tuesday',
            month=10, season='Post-Monsoon', temperature=28, rainfall_mm=0, promotion='None',
            competitor_price=52, inventory=105, previous_week_sales=90, previous_month_sales=360,
            year=2026, day=6)

    def test_missing_model_is_service_unavailable(self):
        with patch.object(api, 'pipeline', None):
            self.assertEqual(self.client.post('/predict', json=self.payload).status_code, 503)

    def test_rejects_invalid_numbers_and_dates(self):
        for key, value in [('inventory', -1), ('inventory', 1.5), ('price', float('inf')),
                           ('discount', 101), ('month', 13), ('day_of_week', 'Monday'),
                           ('weekend', 'Yes'), ('inventory', True)]:
            with self.subTest(key=key, value=value):
                self.assertEqual(self.client.post('/predict', json={**self.payload, key:value}).status_code, 400)

    def test_rejects_non_object_json(self):
        self.assertEqual(self.client.post('/predict', json=['bad']).status_code, 400)

    def test_policy_matches_safety_stock(self):
        with patch.object(api, 'pipeline', Mock(predict=Mock(return_value=[100]))):
            response = self.client.post('/predict', json=self.payload)
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertEqual(data['restock_quantity'], 7)
        self.assertEqual(data['business_advice'], 'Order 7 units.')
        self.assertNotIn('confidence', data)
        self.assertNotIn('demand_factors', data)

    def test_server_error_is_private(self):
        with patch.object(api, 'pipeline', Mock(predict=Mock(side_effect=RuntimeError('private path')))):
            response = self.client.post('/predict', json=self.payload)
        self.assertEqual(response.status_code, 500)
        self.assertNotIn('private path', response.get_data(as_text=True))

if __name__ == '__main__': unittest.main()
