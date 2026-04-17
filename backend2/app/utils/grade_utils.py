"""
Grade-to-point conversion utility.
Supports common Indian university 10-point scale and letter grades.
"""

# ── Grade point mapping (10-point scale) ─────────────────
GRADE_MAP: dict[str, float] = {
    "O":   10.0,
    "A+":  9.0,
    "A":   8.0,
    "B+":  7.0,
    "B":   6.0,
    "C+":  5.0,
    "C":   4.0,
    "D":   3.0,
    "F":   0.0,
    # Alternate labels
    "S":   10.0,
    "P":   4.0,
    "FAIL": 0.0,
}


def grade_to_point(grade: str) -> float:
    """
    Convert a letter grade to its grade-point value.
    Accepts grades case-insensitively.
    Raises ValueError for unrecognised grades.
    """
    normalised = grade.strip().upper()
    if normalised in GRADE_MAP:
        return GRADE_MAP[normalised]

    # Try parsing as a direct numeric value (e.g. "8.5")
    try:
        val = float(normalised)
        if 0.0 <= val <= 10.0:
            return val
    except ValueError:
        pass

    raise ValueError(f"Unrecognised grade: '{grade}'. Valid grades: {list(GRADE_MAP.keys())}")
