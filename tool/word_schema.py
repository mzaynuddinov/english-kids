"""Pydantic / FastAPI contract for Англисиро Омӯз word cards.

The mobile app stays offline-first (`data/vocabulary.json`). This module is the
server-side shape if a JSON API is added later — field names match Word.tryParse
so Flutter WordCardWidget can consume the JSON as-is.
"""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator


CefrLevel = Literal["A1", "A2", "B1", "B2"]


class WordFormation(BaseModel):
    """Transparent word-building only — never invented etymology."""

    prefix: str = ""
    root: str = ""
    suffix: str = ""
    note: str = ""

    @property
    def is_empty(self) -> bool:
        return not (self.prefix or self.root or self.suffix or self.note)


class WordSchema(BaseModel):
    """JSON payload for one vocabulary card."""

    model_config = ConfigDict(populate_by_name=True, extra="ignore")

    english: str = Field(min_length=1, examples=["Hello"])
    pronunciation: str = Field(description="Cyrillic transliteration", examples=["ҳэллоу"])
    tajik: str = Field(min_length=1, examples=["салом"])
    week: int = Field(ge=1, le=10)
    topic: str = Field(alias="category", examples=["Greetings"])
    day: int = Field(default=1, ge=1, le=7)
    difficulty: int = Field(default=1, ge=1, le=3)
    example: str = ""
    example_tajik: str = Field(default="", alias="exampleTajik")
    part_of_speech: str = Field(default="", alias="partOfSpeech", examples=["interjection"])
    cefr: CefrLevel | str = "A1"
    synonyms: list[str] = Field(default_factory=list)
    antonyms: list[str] = Field(default_factory=list)
    grammar_note: str = Field(default="", alias="grammarNote")
    ipa: str = Field(default="", examples=["həˈləʊ"])
    phonetic: str = Field(default="", examples=["/həˈləʊ/"])
    stress: str = Field(default="", examples=["Hel-lo"])
    origin: str = Field(default="", examples=["Ин нидо аст — салом ё ҳиссиёт."])
    formation: WordFormation | None = None

    @field_validator("english", "tajik", "pronunciation", "topic")
    @classmethod
    def strip_text(cls, value: str) -> str:
        return value.strip()

    @property
    def word_id(self) -> str:
        return f"{self.english.lower()}|{self.week}|{self.tajik.lower()}"

    @property
    def pos_label(self) -> str:
        if self.english.lower() == "hello":
            return "Phrase / Interjection"
        raw = self.part_of_speech.strip()
        if not raw:
            return ""
        parts = [part.strip().capitalize() for part in raw.replace("/", ",").split(",") if part.strip()]
        return " / ".join(parts)


class WordCardPayload(WordSchema):
    """Wire format the Flutter WordCardWidget consumes."""

    learned: bool = False
    saved: bool = False
    voice_gender: Literal["male", "female"] = "female"


HELLO_SAMPLE = WordSchema(
    english="Hello",
    pronunciation="ҳэллоу",
    tajik="салом",
    week=1,
    topic="Greetings",
    day=1,
    difficulty=1,
    example="Hello! How are you?",
    example_tajik="Салом! Шумо чӣ хелед?",
    part_of_speech="interjection",
    cefr="A1",
    synonyms=["Hi", "Hey"],
    antonyms=["Goodbye"],
    grammar_note="Ин нидо аст — салом ё ҳиссиёт.",
    ipa="həˈləʊ",
    phonetic="/həˈləʊ/",
    stress="Hel-lo",
    origin="Ин нидо аст — салом ё ҳиссиёт.",
    formation=None,
)


def create_word_router():
    """Optional FastAPI router — import only when FastAPI is installed."""
    from fastapi import APIRouter, HTTPException

    router = APIRouter(prefix="/words", tags=["words"])
    catalog = {HELLO_SAMPLE.word_id: HELLO_SAMPLE}

    @router.get("/hello", response_model=WordCardPayload)
    def hello_card() -> WordCardPayload:
        return WordCardPayload(**HELLO_SAMPLE.model_dump(), learned=False, saved=False)

    @router.get("/{word_id}", response_model=WordSchema)
    def get_word(word_id: str) -> WordSchema:
        word = catalog.get(word_id)
        if word is None:
            raise HTTPException(status_code=404, detail="Word not found")
        return word

    @router.get("", response_model=list[WordSchema])
    def list_words() -> list[WordSchema]:
        return list(catalog.values())

    return router
