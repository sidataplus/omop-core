# import typer


# def main(name: str, lastname: str = "", formal: bool = False):
#     """
#     Say hi to NAME, optionally with a --lastname.

#     If --formal is used, say hi very formally.
#     """
#     if formal:
#         print(f"Good day Ms. {name} {lastname}.")
#     else:
#         print(f"Hello {name} {lastname}")


# if __name__ == "__main__":
#     typer.run(main)


import typer
import subprocess
import os


app = typer.Typer(add_completion=False, help="CrossPipe CLI for OMOP ETL")


@app.command()
def transfer():
    """
    Transfer data from source to target, Where cdm_a and cdm_b pre-defined

    Use command build to combine both cdm_a and cdm_b to temp

    ### Development: beta-crosspipeline-transfer:

    #   Working with JDBC_SOURCE and JDBC_TARGET as cdm_a and cdm_b
    """
    subprocess.call(['/opt/spark/bin/spark-submit', '--driver-memory', str(int(os.environ['SPARK_DRIVER_MEMORY'])*2)+'g', 'transfer.py'])


@app.command()
def build():
    """
    Completly transfer all temp instance of OMOP to analytics instance

    Error raised if pre-validate is failed, use --force to bypass this
    """
    print("build: Working on it")


@app.command()
def vocab():
    """
    This command require additional sub-command as below:
    
    info, load
    """
    print("vocab: Working on it")


@app.command()
def validate():
    """
    To validate the schema correctness and CDM constraint, also linkage consistency.
    """
    print("validate: Working on it")


@app.command()
def backup():
    """
    Clone ATLAS DB the configuration and user footprints information to temp db.
    """
    print("backup: Working on it")


@app.command()
def restore():
    """
    From temp db, restore those configuration and user footprints information back to ATLAS DB.
    """
    print("restore: Working on it")


if __name__ == "__main__":
    """
    Test Text, why read?
    """
    app()