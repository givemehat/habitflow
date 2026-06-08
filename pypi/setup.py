from setuptools import setup, find_packages

setup(
    name="habitflow",
    version="1.0.0",
    packages=find_packages(),
    include_package_data=True,
    package_data={
        "habitflow": ["habitflow-cli.swift"]
    }
)
