import typer
import subprocess
import os
import typing_extensions


app = typer.Typer(add_completion=False, help="CrossPipe CLI for OMOP ETL")


@app.command()
def transfer(
    source: typing_extensions.Annotated[str, typer.Argument(help="Accept value is ['OMOP', 'ATLAS', 'CROSSPIPE']")] = "OMOP", 
    target: typing_extensions.Annotated[str, typer.Argument(help="Accept value is ['OMOP', 'ATLAS', 'CROSSPIPE']")] = "ATLAS",
    force: typing_extensions.Annotated[
        bool, typer.Option(prompt=f"Are you sure to overwrite the target?")
    ] = False,
):
    """
    Transfer data from source to target

    ## WIP: Use command build to combine both cdm_a and cdm_b to temp
    """
    if force:
        print(f"Transfering data from {source} to {target}")
        subprocess.call(['/opt/spark/bin/spark-submit', '--driver-memory', str(int(os.environ['SPARK_DRIVER_MEMORY'])*2)+'g', 'transfer.py', source, target])
    else:
        print("Transfer Canceled")


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