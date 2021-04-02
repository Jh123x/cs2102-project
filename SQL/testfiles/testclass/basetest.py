def parse_args(arg: str):
    if '::' in arg:
        return arg
    return f"'{arg}'"


class BaseTest(object):
    DB = None
    CURSOR = None

    def setUp(self) -> None:
        """Setup before each test case"""
        assert self.DB is not None, "Please initialise DB to BaseTest.DB"
        self.CURSOR = self.DB.cursor()
        return super().setUp()

    def tearDown(self) -> None:
        """Tear down after each test case"""
        self.DB.rollback()
        return super().tearDown()

    def generate_query(self, function: str, args: tuple) -> None:
        """Generate query based on arguments"""
        return f"""SELECT {function}({", ".join(map(parse_args, args))})"""

    def execute_query(self, query: str) -> list:
        """Execute query and return the result at the cursor"""
        self.CURSOR.execute(query)
        return [desc[0] for desc in self.CURSOR.description]

    def fetch_all(self):
        """Get the result from the previous query"""
        return self.CURSOR.fetchall()

    def value_test(self, query:str, expected, message):
        """Test value"""
        self.execute_query(query)
        actual = self.fetch_all()
        assert expected == actual, message % actual
