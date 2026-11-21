from typing import List, Optional
from pydantic import AliasChoices, BaseModel, ConfigDict, Field, model_validator


class KeyTermPair(BaseModel):
    """Pair of English technical term and its Odia script meaning."""

    english_term: str
    odia_meaning: str = ""

    model_config = ConfigDict(populate_by_name=True)


class GroundedReference(BaseModel):
    """Direct, verifiable citation metadata grounded in Odisha state textbooks."""

    textbook_name: str
    chapter_no: int
    section_heading: Optional[str] = None
    page_no: Optional[int] = None
    paragraph_no: Optional[int] = None

    model_config = ConfigDict(populate_by_name=True)


class RagTextbookVector(BaseModel):
    """Schema for textbook chunks and semantic vector embeddings in rag_textbook_vectors."""

    chunk_id: str = Field(validation_alias=AliasChoices("chunk_id", "_id"))
    subject: str
    chapter_name: str
    chunk_text: str
    embedding: List[float]
    embedding_model: str = Field(
        default="intfloat/multilingual-e5-base",
        description="Embedding model name",
    )
    embedding_dim: int = Field(
        default=768,
        description="Vector dimension (e.g. 768 or 384)",
    )
    grounded_reference: GroundedReference
    important_english_terms: List[KeyTermPair] = Field(default_factory=list)

    @model_validator(mode="after")
    def validate_embedding_dimensions(self) -> "RagTextbookVector":
        if len(self.embedding) != self.embedding_dim:
            raise ValueError(
                f"Embedding length {len(self.embedding)} does not match embedding_dim {self.embedding_dim}"
            )
        return self

    model_config = ConfigDict(populate_by_name=True)
