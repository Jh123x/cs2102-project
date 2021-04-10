import configparser

parser = configparser.ConfigParser()
parser["CONSTANTS"] = {
    "HOST": "postgres01-1.comp.nus.edu",
    "PORT": 5432,
    "DBNAME": "cs2102",
}
parser["CREDENTIALS"] = {
    "username": "",
    "password": "",
}

parser["DIRECTORIES"] = {
    "schemas": "./schema",
    "functions": "./functions",
    "triggers": "./triggers",
    "views": "./views",
}

def generate_config(file_path: str):
    with open(file_path, "w") as file:
        parser.write(file)