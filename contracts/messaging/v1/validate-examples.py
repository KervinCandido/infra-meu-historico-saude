from __future__ import annotations

import json
from pathlib import Path

from jsonschema import Draft7Validator, FormatChecker


ROOT = Path(__file__).resolve().parent

CASES = (
    (
        "schemas/document-processing-requested.schema.json",
        "examples/document-processing-requested.json",
    ),
    (
        "schemas/document-processing-result.schema.json",
        "examples/document-processing-completed.json",
    ),
    (
        "schemas/document-processing-result.schema.json",
        "examples/document-processing-failed.json",
    ),
)


def load_json(relative_path: str) -> dict:
    path = ROOT / relative_path

    with path.open(encoding="utf-8") as file:
        return json.load(file)


def validate_case(
    schema_path: str,
    example_path: str,
) -> None:
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

    if errors:
        details = "\n".join(
            f"- {list(error.absolute_path)}: {error.message}"
            for error in errors
        )

        raise SystemExit(
            f"INVALID: {example_path}\n{details}"
        )

    print(f"VALID: {example_path}")


def main() -> None:
    for schema_path, example_path in CASES:
        validate_case(schema_path, example_path)

    print("OK: todos os exemplos respeitam os contratos.")


if __name__ == "__main__":
    main()