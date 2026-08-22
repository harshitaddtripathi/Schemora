from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field


class SourceCitation(BaseModel):
    source_name: str
    url: str
    last_verified_at: str = "2026-08-07"


class AIExplanationRequest(BaseModel):
    scheme_id: str
    language: str = Field("en", json_schema_extra={"example": "en"})


class AIExplanationResponse(BaseModel):
    scheme_id: str
    explanation: str
    citations: List[SourceCitation] = []


class RetrievedScheme(BaseModel):
    """A scheme chunk retrieved from the knowledge base for a RAG response."""
    scheme_id: Optional[str] = None
    scheme_name: str = ""
    section: str = ""
    similarity_score: float = 0.0
    jurisdiction: str = ""
    state: Optional[str] = None
    category: str = ""
    official_info_url: str = ""
    official_app_url: str = ""


class AIChatRequest(BaseModel):
    question: str = Field(
        ..., min_length=2,
        json_schema_extra={"example": "What documents are needed for CSSS scholarship?"}
    )
    scheme_id: Optional[str] = Field(None, json_schema_extra={"example": "sch-central-csss-001"})
    language: str = Field("en", json_schema_extra={"example": "en"})

    # Extended RAG fields
    profile_id: Optional[str] = Field(None, description="User profile ID for personalized eligibility context")
    state_filter: Optional[str] = Field(None, description="Restrict results to this state (e.g. Maharashtra)")
    category_filter: Optional[str] = Field(None, description="Restrict results to this category (e.g. Scholarship)")
    conversation_history: Optional[List[Dict[str, str]]] = Field(
        None, description="Previous Q&A pairs for context"
    )


class AIChatResponse(BaseModel):
    answer: str
    is_grounded: bool
    citations: List[SourceCitation] = []

    # Extended RAG response fields
    retrieved_schemes: List[RetrievedScheme] = []
    confidence_score: float = Field(0.0, description="Average similarity score of top retrieved chunks")
    suggested_questions: List[str] = Field([], description="Follow-up questions the user might want to ask")
    is_personalized: bool = Field(False, description="True if user profile was used to personalize the response")
    knowledge_base_used: bool = Field(True, description="True if RAG knowledge base was used")


class KnowledgeBaseStatusResponse(BaseModel):
    """Status of the Schemora RAG knowledge base."""
    total_chunks: int
    semantic_chunks: int
    tfidf_chunks: int
    indexed_schemes: int
    total_documents: int
    embedding_model: str
    is_ready: bool


class KnowledgeBaseIndexResponse(BaseModel):
    """Result of a knowledge base indexing operation."""
    total_schemes: int
    indexed_schemes: int
    failed_schemes: List[Dict[str, str]] = []
    total_chunks: int
    semantic_chunks: int
    tfidf_chunks: int
    dataset_version: str
    message: str
