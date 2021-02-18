from flask import Flask, render_template, redirect


app = Flask(__name__)


@app.route('/')
def homepage():
    """Redirect homepage to html"""
    return redirect('index.html')

@app.route('/index.html')
def index():
    """The home page for the application"""
    return render_template("index.html")


if __name__ == "__main__":
    app.run("", 80, debug=False)
