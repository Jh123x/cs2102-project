import unittest
from . import BaseTest
from psycopg2.errors import UniqueViolation

class GAddCourseOfferingTest(BaseTest, unittest.TestCase):

    def test_pass(self):
        