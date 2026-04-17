from __future__ import annotations

from typing import Iterable, Tuple
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity


def build_vector_space(texts: Iterable[str]) -> Tuple[TfidfVectorizer, object]:
    vectorizer = TfidfVectorizer(
        stop_words="english",
        ngram_range=(1, 2),
        min_df=1
    )
    matrix = vectorizer.fit_transform(list(texts))
    return vectorizer, matrix


def pairwise_similarity(matrix):
    return cosine_similarity(matrix)


def similarity_to_query(vectorizer: TfidfVectorizer, matrix, query_text: str):
    q = vectorizer.transform([query_text])
    scores = cosine_similarity(q, matrix).flatten()
    return scores