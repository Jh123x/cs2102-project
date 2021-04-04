import unittest
import datetime
from . import BaseTest
from unittest.case import expectedFailure
from psycopg2.errors import UniqueViolation, RaiseException


class ZBuyCoursePackageTest(BaseTest, unittest.TestCase):

    def setUp(self) -> None:
        """Extended setup for the class"""
        # Create a customer
        args = ("Invoker", "987354312", "address here",
                "test@test.com", '1234123412341234', '123', '2020-04-20')
        query = self.generate_query('add_customer', args)
        self.customer_id = self.execute_query(query)[0][0]

        # Check if the customer is created in the table
        query = f'SELECT COUNT(*) FROM Customers WHERE customer_id = {self.customer_id}'
        res = self.execute_query(query)[0][0]
        assert res == 1, "There is more than 1 customer inserted into the table"

        # Create a course_package
        args = ('Best Package', '10', '2020-04-20', '2023-04-20', '200')
        query = self.generate_query('add_course_package', args)
        self.package_id = self.execute_query(query)[0][0]

        # Check if the package is the only one that is created
        query = f'SELECT COUNT(*) FROM CoursePackages WHERE package_id = {self.package_id}'
        res = self.execute_query(query)[0][0]
        assert res == 1, "There is more than 1 package that is inserted into the table"

        return super().setUp()

    def test_buy_success(self):
        """Successfully buy the package"""

        # Buy a package
        args = (str(self.customer_id), str(self.package_id))
        query = self.generate_query('buy_course_package', args)
        self.execute_query(query)

        # Check if it is in the Buys table
        query = f'SELECT * FROM Buys WHERE package_id = {self.package_id}'
        res = self.execute_query(query)
        assert len(res) == 1, "Incorrect number of bought packages reported"
        today = datetime.datetime.combine(
            datetime.datetime.now().date(), datetime.time(0))
        assert res == [(today, 10, self.package_id, self.customer_id,
                        '1234123412341234')], "The package added is incorrect"

    def test_buy_same_package_2_times_more_than_0_redemp_val_fail(self):
        """Buy the same pacakge 2 times"""
        # Buy a package
        self.test_buy_success()

        # Buy the same package again
        args = (str(self.customer_id), str(self.package_id))
        query = self.generate_query('buy_course_package', args)
        self.check_fail_test(
            query, "Buying the same package 2 where each time has > 0 redemption times should result in a fail", (RaiseException,))

    def test_buy_same_package_2_times_equal_0_redemp_val_fail(self):
        """Buy the same package 2 times but they have 0 value each"""
        # Const
        today = datetime.datetime.combine(
            datetime.datetime.now().date(), datetime.time(0))

        # Create another course_package
        args = ('Best Package 2', '0', '2020-04-20', '2023-04-20', '200')
        query = self.generate_query('add_course_package', args)
        package_id = self.execute_query(query)[0][0]

        # Buy the package 1 time
        args = (str(self.customer_id), str(package_id))
        query = self.generate_query('buy_course_package', args)
        self.execute_query(query)

        # Check if the package is in buys
        query = f'SELECT * FROM Buys WHERE package_id = {package_id}'
        res = self.execute_query(query)
        assert len(res) == 1, "Incorrect number of bought packages reported"
        expected = [
            (today, 0, package_id, self.customer_id, '1234123412341234')]
        assert res == expected, f"The package added is incorrect {res}: {expected}"

        # Buy it again
        query = self.generate_query('buy_course_package', args)
        self.execute_query(query)

    def test_buy_different_package_while_1_active(self):
        """Test if the customer can buy a different package when there is currently one active"""
        # Create another course_package
        args = ('Best Package 2', '10', '2020-04-20', '2023-04-20', '200')
        query = self.generate_query('add_course_package', args)
        package_id2 = self.execute_query(query)[0][0]

        # Buys 1 package of a different date
        query = f"INSERT INTO Buys Values('2020-04-04', 10, {self.package_id}, {self.customer_id}, 1234123412341234)"
        self.execute_query(query)

        # Buy another package
        args = (str(self.customer_id), str(package_id2))
        query = self.generate_query('buy_course_package', args)
        self.check_fail_test(
            query, "Customer should not be able to buy another package when one of them is active", RaiseException)

    def test_buy_different_package_while_no_active(self):
        """Test if buying a package while there are no active packages will succeed"""
        # Constants
        today = datetime.datetime.combine(
            datetime.datetime.now().date(), datetime.time(0))

        # Create another course_package with 0 redemptions
        args = ('Best Package 2', '0', '2020-04-03', '2023-04-20', '200')
        query = self.generate_query('add_course_package', args)
        package_id2 = self.execute_query(query)[0][0]

        # Buys 1 package of a different date
        query = f"INSERT INTO Buys Values('2020-04-04', 0, {package_id2}, {self.customer_id}, 1234123412341234)"
        self.execute_query(query)

        # Buy another package
        args = (str(self.customer_id), str(self.package_id))
        query = self.generate_query('buy_course_package', args)
        self.execute_query(query)

        # Both packages have different ids
        assert package_id2 != self.package_id, "Package id should be different"

        # Check if the old package still exists
        query = f'SELECT * FROM Buys WHERE package_id = {package_id2}'
        res = self.execute_query(query)
        assert len(res) == 1, "Incorrect number of bought packages reported"
        purchase_date = datetime.datetime.combine(datetime.datetime.strptime(
            '2020-04-04', '%Y-%m-%d').date(), datetime.time(0))
        expected = [(purchase_date, 0, package_id2,
                     self.customer_id, '1234123412341234')]
        assert res == expected, f"The package added is incorrect {res}: {expected}"

        # Check if new package is in the buys table
        query = f'SELECT * FROM Buys WHERE package_id = {self.package_id}'
        res = self.execute_query(query)
        assert len(
            res) == 1, f"Incorrect number of bought packages reported {res}"
        expected = [(today, 10, self.package_id,
                     self.customer_id, '1234123412341234')]
        assert res == expected, f"The package added is incorrect {res} : {expected}"
