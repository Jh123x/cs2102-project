import unittest
from . import BaseTest
from unittest import expectedFailure


class TopPackagesTest(BaseTest, unittest.TestCase):

    def test_top_packages_no_package_success(self):
        """Test top packages when there are no packages"""
        q = self.generate_query('top_packages', ('5',))
        res = self.execute_query(q)

        assert len(res) == 0, f"There should be no packages when there are no packages inserted {res}"

    def setup_empty_packages(self):
        """Test packages with no purchases should not be reflected"""
        # Package with no customers buying
        self.no_package = self._add_course_package('0 Package', 2, '2021-04-01', '2021-06-01', 10)
        self.no_package1 = self._add_course_package('0 Package1', 2, '2021-03-01', '2021-06-01', 20)
        self.no_package2 = self._add_course_package('0 Package2', 2, '2021-02-01', '2021-06-01', 30)

    def test_top_packages_with_no_sold(self):
        """Check the top packages with no packages sold"""
        # Create empty packages
        self.setup_empty_packages()

        # Check for the top 5 packages
        q = self.generate_query('top_packages', ('3',))
        res = self.execute_query(q)

        assert len(res) == 0, f"There should be no packages when there are no packages inserted {res}"

    def setup_filled_packages(self):
        """Test packages with customers purchasing them"""
        self.first_package = self._add_course_package('1st package', 0, '2021-04-01', '2021-06-02', 10)
        self.second_package = self._add_course_package('2nd package', 0, '2021-04-01', '2021-06-03', 10)
        self.third_package = self._add_course_package('3rd package', 0, '2021-04-01', '2021-06-04', 10)
        self.third_package2 = self._add_course_package('3rd package2', 0, '2021-04-01', '2021-06-05', 10)

        # Create the customer to buy the product
        self.cust_id = self._add_customer('John', 'addr', 12345789, 'test@test.com.sg', '1234567812345678', '987', '2025-06-05')

        # Buy the first package 5 times
        q = self.generate_query('buy_course_package', (str(self.cust_id), str(self.first_package)))
        for _ in range(5):
            self.execute_query(q)

        # Buy the 2nd package 4 times
        q = self.generate_query('buy_course_package', (str(self.cust_id), str(self.second_package)))
        for _ in range(4):
            self.execute_query(q)

        # Buy the 2 3rd packages 3 times
        q = self.generate_query('buy_course_package', (str(self.cust_id), str(self.third_package)))
        q2 = self.generate_query('buy_course_package', (str(self.cust_id), str(self.third_package2)))
        for _ in range(3):
            self.execute_query(q)
            self.execute_query(q2)

    def test_top_package_returns_top_package(self):
        """Test if the top package actually returns the package"""
        self.setup_empty_packages()
        self.setup_filled_packages()

        # Get the top package
        q = self.generate_query('top_packages', ('1',))
        res = self.execute_query(q)
        assert len(res) == 1, f'The top package is not found {res}'

        assert res == [
            (f'({self.first_package},0,10.00,2021-04-01,2021-06-02,5)',)
        ], f'The top package is not correct {res}'

    def test_top_2_package_returns_top_2_package(self):
        """Test if the top 2 package actually returns the packages"""
        self.setup_empty_packages()
        self.setup_filled_packages()
        # Get the top 2 packages
        q = self.generate_query('top_packages', ('2',))
        res = self.execute_query(q)
        assert len(res) == 2, f'The top 2 packages are not found {res}'
        assert res == [
            (f'({self.first_package},0,10.00,2021-04-01,2021-06-02,5)',),
            (f'({self.second_package},0,10.00,2021-04-01,2021-06-03,4)',)
        ], f'The top 2 packages are not found {res}'

    def test_top_3_package_returns_top_4_package(self):
        """Test if the top 3 package actually returns the packages"""
        self.setup_empty_packages()
        self.setup_filled_packages()

        # Get the top 3 packages
        q = self.generate_query('top_packages', ('3',))
        res = self.execute_query(q)
        assert len(res) == 4, f'The top 3 packages are not found {res}'
        assert res == [
            (f'({self.first_package},0,10.00,2021-04-01,2021-06-02,5)',),
            (f'({self.second_package},0,10.00,2021-04-01,2021-06-03,4)',),
            (f'({self.third_package},0,10.00,2021-04-01,2021-06-04,3)',),
            (f'({self.third_package2},0,10.00,2021-04-01,2021-06-05,3)',)
        ], f'The top 3 packages are not found {res}'