import configparser

parser = configparser.ConfigParser()
parser["CONSTANTS"] = {
    "HOST": "postgres01-1",
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
    "views": "./view",
}


with open("settings.cfg", "w") as file:
    parser.write(file)