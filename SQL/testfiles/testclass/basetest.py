import psycopg2.errors


def parse_args(arg: str):
    if '::' in arg or '[' in arg:
        return arg
    return f"'{arg}'"


class BaseTest(object):
    DB = None
    CURSOR = None
    ERR_MSG = "Expected: %s\nActual: %s"

    def tearDown(self) -> None:
        """Tear down after each test case"""
        self.DB.rollback()

    def _parse_args(self, args: tuple):
        """Parse the arguments into a string"""
        return ", ".join(map(parse_args, args))

    def generate_query(self, function: str, args: tuple) -> None:
        """Generate query based on arguments"""
        return f"""SELECT {function}({self._parse_args(args)})"""

    def generate_procedure(self, procedure: str, args:tuple) -> None:
        return f"""CALL {procedure}({self._parse_args(args)})"""

    def execute_query(self, query: str) -> list:
        """Execute query and return the result at the cursor"""
        self.CURSOR.execute(query)
        try:
            res = self.fetch_all()
        except Exception:
            return None
        return res

    def fetch_all(self):
        """Get the result from the previous query"""
        return self.CURSOR.fetchall()

    def value_test(self, query:str, expected):
        """Test value"""
        self.execute_query(query)
        actual = self.fetch_all()
        for v, e in zip(actual, expected):
            assert v == e, self.ERR_MSG % (e, v)

    def check_fail_test(self, query: str, msg: str, expected_error: tuple) -> None:
        """Check test cases which are suppose to fail"""
        try:
            self.execute_query(query)
        except expected_error:
            pass
        else:
            raise AssertionError(msg)

    def _add_person(self, role: str, course_areas: list = 'ARRAY[]::TEXT[]') -> None:
        """Add a manager into the table"""
        args = ["John", "address", '987654321', 'test@test.com',
                '2020-05-03', role, "full-time", '10.5', str(course_areas)]
        manager_query = self.generate_query("add_employee", tuple(args))
        self.execute_query(manager_query)
