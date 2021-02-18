import psycopg2


class Database(object):
    def __init__(self, user: str, password: str, hostname: str, port: str, database: str = "postgres_db"):
        """Database object to interact with the data
            Connection is thread-safe and can be shared with many threads as per psycopy2 docs
            More info at https://www.psycopg.org/docs/connection.html
        """

        # Check for some errors
        if not port.isdigit():
            raise ValueError(f"Port must be a digit: {port}")

        try: 
            self.connection = psycopg2.connect(user=user,
                                            password=password,
                                            host=hostname,
                                            port=str(port),
                                            database=database)
        except Exception as e:
            raise e

    def execute(self, sql_query:str, hasResults: bool = False):
        """Execute the sql query on the database
            For multiline queries, please separate them by semicolons

            Can be executed in multithreaded situations as per psycopg2 docs
            More info at https://www.psycopg.org/docs/connection.html
        """
        record = None

        # Execute the command with e
        with self.connection.cursor() as cursor:
            try: 
                # Execute the query
                for query in sql_query.split(';'):
                    cursor.execute(query)
        
            except Exception as e:

                # Rollback if there is an error
                cursor.rollback()

                raise e
                
            else:

                # Commit the information if it executed successfully
                cursor.commit()
                
                # Check if it has results to fetch
                if hasResults:
                    record = self.connection.fetchone()

        # Return the record if any
        return record

    def __del__(self):
        """Method to destroy the object"""
        # Close the connection to the server
        self.connection.close()