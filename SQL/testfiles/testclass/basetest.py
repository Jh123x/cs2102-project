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

    def generate_query(self, function: str, args: tuple) -> None:
        """Generate query based on arguments"""
        return f"""SELECT {function}({", ".join(map(parse_args, args))})"""

    def generate_procedure(self, procedure: str, args:tuple) -> None:
        return f"""EXEC {procedure}({", ".join(map(parse_args, args))})"""

    def execute_query(self, query: str) -> list:
        """Execute query and return the result at the cursor"""
        self.CURSOR.execute(query)
        return [desc[0] for desc in self.CURSOR.description]

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
