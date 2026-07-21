import json
import pathlib
import sys

from jsonschema import Draft7Validator, FormatChecker


ROOT = pathlib.Path(__file__).resolve().parent

VALIDATIONS = [
    (
        "schemas/document-processing-requested.schema.json",
        "examples/document-processing-requested.json",
    ),
    (
        "schemas/document-processed-response.schema.json",
        "examples/document-processed-success.json",
    ),
    (
        "schemas/document-processed-response.schema.json",
        "examples/document-processed-failure.json",
    ),
]


def load_json(relative_path: str) -> dict:
    path = ROOT / relative_path

    with path.open(
        mode="r",
        encoding="utf-8-sig",
    ) as file:
        return json.load(file)


def format_location(error) -> str:
    if not error.absolute_path:
        return "$"

    return "$." + ".".join(
        str(item)
        for item in error.absolute_path
    )


def main() -> int:
    valid = True

    for schema_path, example_path in VALIDATIONS:
        schema = load_json(schema_path)
        example = load_json(example_path)

        Draft7Validator.check_schema(schema)

        validator = Draft7Validator(
            schema,
            format_checker=FormatChecker(),
        )

        errors = sorted(
            validator.iter_errors(example),
            key=lambda error: list(error.absolute_path),
        )

        if not errors:
            print(f"VALID: {example_path}")
            continue

        valid = False
        print(f"INVALID: {example_path}")

        for error in errors:
            print(
                f"  {format_location(error)}: "
                f"{error.message}"
            )

    if valid:
        print(
            "OK: todos os exemplos respeitam "
            "os respectivos contratos."
        )
        return 0

    return 1


if __name__ == "__main__":
    sys.exit(main())

